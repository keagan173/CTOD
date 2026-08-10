-- Persist finalized-review intelligence, reuse carried development goals, and
-- keep reporting views aligned with the canonical review record.

create unique index if not exists uq_succession_records_active_employee
on public.succession_records(company_id, employee_id)
where active = true;

create or replace function private.refresh_finalized_review_intelligence(p_review_id uuid)
returns public.reviews
language plpgsql
set search_path to 'public', 'pg_catalog'
as $function$
declare
  v_review public.reviews;
  v_weighted_score numeric;
  v_simple_score numeric;
  v_score numeric;
  v_label text;
  v_readiness text;
  v_target_role uuid;
  v_has_active_goal boolean;
begin
  select * into v_review
  from public.reviews
  where id = p_review_id
  for update;

  if not found then
    raise exception 'Review not found';
  end if;

  -- Finalized answer rows are immutable. Calculate intelligence from the
  -- locked rating relationship below instead of rewriting answer snapshots.

  select
    sum(
      scale.score_value
      * coalesce(nullif(question.question_weight, 0), 1)
      * coalesce(nullif(question.section_weight, 0), 1)
    ) / nullif(sum(
      coalesce(nullif(question.question_weight, 0), 1)
      * coalesce(nullif(question.section_weight, 0), 1)
    ), 0),
    avg(scale.score_value)
  into v_weighted_score, v_simple_score
  from public.review_answers answer
  join public.rating_scale_items scale on scale.id = answer.rating_id
  join public.question_definitions question on question.id = answer.question_id
  where answer.review_id = p_review_id;

  v_score := coalesce(v_weighted_score, v_simple_score);

  select decision.promotion_readiness, decision.desired_role_id
  into v_readiness, v_target_role
  from public.career_decisions decision
  where decision.review_id = p_review_id;

  if v_score is not null then
    select scale.label
    into v_label
    from public.rating_scale_items scale
    where scale.config_version_id = v_review.config_version_id
    order by abs(scale.score_value - v_score), scale.score_value desc
    limit 1;
  end if;

  update public.reviews
  set overall_score = coalesce(round(v_score, 2), overall_score),
      overall_percent = coalesce(round((v_score / 5.0) * 100.0, 2), overall_percent),
      overall_rating_label = coalesce(v_label, overall_rating_label),
      promotion_readiness = coalesce(v_readiness, promotion_readiness),
      updated_at = now()
  where id = p_review_id
  returning * into v_review;

  if v_readiness is not null
     and not exists(
       select 1
       from public.reviews newer
       where newer.employee_id = v_review.employee_id
         and newer.status = 'finalized'
         and newer.id <> v_review.id
         and coalesce(newer.finalized_at, newer.created_at)
             > coalesce(v_review.finalized_at, v_review.created_at)
     ) then
    select exists(
      select 1
      from public.goals goal
      where goal.employee_id = v_review.employee_id
        and goal.status in ('not_started', 'in_progress')
    ) into v_has_active_goal;

    insert into public.succession_records(
      company_id,
      employee_id,
      current_role_id,
      target_role_id,
      readiness,
      active,
      active_development_goal,
      last_updated_at,
      source_version
    )
    values(
      v_review.company_id,
      v_review.employee_id,
      v_review.role_id,
      v_target_role,
      v_readiness,
      true,
      v_has_active_goal,
      now(),
      'CTOD-REVIEW-INTELLIGENCE-1.0'
    )
    on conflict(company_id, employee_id) where active = true
    do update set
      current_role_id = excluded.current_role_id,
      target_role_id = excluded.target_role_id,
      readiness = excluded.readiness,
      active_development_goal = excluded.active_development_goal,
      last_updated_at = excluded.last_updated_at,
      source_version = excluded.source_version;
  end if;

  return v_review;
end
$function$;

revoke all on function private.refresh_finalized_review_intelligence(uuid)
from public, anon, authenticated;
grant execute on function private.refresh_finalized_review_intelligence(uuid)
to service_role;

create or replace function public.save_review_development(
  p_review_id uuid,
  p_manager_summary text,
  p_employee_comments text,
  p_goal_text text,
  p_goal_target_date date,
  p_promotion_interest boolean,
  p_desired_role_id uuid,
  p_promotion_readiness text,
  p_raise_requested boolean,
  p_raise_basis text
)
returns jsonb
language plpgsql
set search_path to 'public'
as $function$
declare
  r public.reviews;
  g_id uuid;
begin
  select * into r
  from public.reviews
  where id = p_review_id
  for update;

  if not found then
    raise exception 'Review not found';
  end if;

  if not private.can_access_location(r.company_id, r.location_id) then
    raise exception 'Access denied';
  end if;

  if r.status = 'finalized' then
    raise exception 'Finalized review is immutable';
  end if;

  insert into public.review_summaries(
    company_id,
    review_id,
    template_version,
    manager_summary,
    employee_comments
  )
  values(
    r.company_id,
    r.id,
    'CTOD-2PAGE-1.2',
    nullif(trim(p_manager_summary), ''),
    nullif(trim(p_employee_comments), '')
  )
  on conflict(review_id) do update
  set manager_summary = excluded.manager_summary,
      employee_comments = excluded.employee_comments,
      generated_at = now(),
      template_version = excluded.template_version;

  if nullif(trim(p_goal_text), '') is not null then
    select id into g_id
    from public.goals
    where origin_review_id = r.id
    order by created_at
    limit 1
    for update;

    if g_id is null then
      select id into g_id
      from public.goals
      where company_id = r.company_id
        and employee_id = r.employee_id
        and status in ('not_started', 'in_progress')
        and lower(trim(goal_text)) = lower(trim(p_goal_text))
      order by updated_at desc, created_at desc
      limit 1
      for update;
    end if;

    if g_id is null then
      insert into public.goals(
        company_id,
        employee_id,
        origin_review_id,
        goal_text,
        goal_type,
        status,
        target_date
      )
      values(
        r.company_id,
        r.employee_id,
        r.id,
        trim(p_goal_text),
        'development',
        'in_progress',
        p_goal_target_date
      )
      returning id into g_id;
    else
      update public.goals
      set goal_text = trim(p_goal_text),
          target_date = p_goal_target_date,
          status = 'in_progress',
          updated_at = now()
      where id = g_id;
    end if;
  end if;

  insert into public.career_decisions(
    company_id,
    review_id,
    employee_id,
    promotion_interest,
    desired_role_id,
    promotion_readiness
  )
  values(
    r.company_id,
    r.id,
    r.employee_id,
    coalesce(p_promotion_interest, false),
    p_desired_role_id,
    nullif(trim(p_promotion_readiness), '')
  )
  on conflict(review_id, employee_id) do update
  set promotion_interest = excluded.promotion_interest,
      desired_role_id = coalesce(excluded.desired_role_id, public.career_decisions.desired_role_id),
      promotion_readiness = excluded.promotion_readiness;

  insert into public.compensation_decisions(
    company_id,
    review_id,
    employee_id,
    raise_requested,
    raise_basis,
    decision_status
  )
  values(
    r.company_id,
    r.id,
    r.employee_id,
    coalesce(p_raise_requested, false),
    nullif(trim(p_raise_basis), ''),
    case when p_raise_requested then 'planned' else 'not_requested' end
  )
  on conflict(review_id, employee_id) do update
  set raise_requested = excluded.raise_requested,
      raise_basis = coalesce(excluded.raise_basis, public.compensation_decisions.raise_basis),
      decision_status = excluded.decision_status;

  return jsonb_build_object('ok', true, 'goal_id', g_id);
end
$function$;

revoke execute on function public.save_review_development(
  uuid, text, text, text, date, boolean, uuid, text, boolean, text
) from public, anon;
grant execute on function public.save_review_development(
  uuid, text, text, text, date, boolean, uuid, text, boolean, text
) to authenticated, service_role;

create or replace function public.finalize_review(p_review_id uuid)
returns public.reviews
language plpgsql
security definer
set search_path to 'public', 'pg_catalog'
as $function$
declare
  v_review public.reviews;
  v_missing integer;
  v_raise_missing integer;
  v_coaching_missing integer;
  v_direction text;
  v_next uuid;
  v_final uuid;
  v_next_date date;
  v_next_campaign uuid;
  v_next_config uuid;
  v_cycle text;
  v_due date;
begin
  select * into v_review
  from public.reviews
  where id = p_review_id
  for update;

  if not found then
    raise exception 'Review not found';
  end if;

  if auth.uid() is null
     or not private.can_access_location(v_review.company_id, v_review.location_id) then
    raise exception 'Access denied';
  end if;

  if v_review.status = 'finalized' then
    return private.refresh_finalized_review_intelligence(p_review_id);
  end if;

  if v_review.status not in ('in_progress', 'blocked', 'ready_to_finalize', 'reopened') then
    raise exception 'Review cannot be finalized from status %', v_review.status;
  end if;

  select count(*) into v_missing
  from public.get_review_validation_issues(p_review_id);

  if v_missing > 0 then
    update public.reviews set status = 'blocked' where id = p_review_id;
    raise exception 'Review has % incomplete or unconfirmed required answers', v_missing;
  end if;

  select count(*) into v_coaching_missing
  from public.get_review_coaching_validation_issues(p_review_id);

  if v_coaching_missing > 0 then
    update public.reviews set status = 'blocked' where id = p_review_id;
    raise exception 'Review has % active coaching moments that must be addressed', v_coaching_missing;
  end if;

  select career_direction, desired_role_id, final_desired_role_id
  into v_direction, v_next, v_final
  from public.career_decisions
  where review_id = p_review_id;

  if v_direction is null then
    raise exception 'Employee career direction must be selected before finalizing';
  end if;

  if v_direction = 'ADVANCEMENT' and (v_next is null or v_final is null) then
    raise exception 'Next job role and ultimate job role are required for advancement before finalizing';
  end if;

  select count(*) into v_raise_missing
  from public.compensation_decisions d
  where d.review_id = p_review_id
    and d.raise_requested = true
    and (
      nullif(trim(d.raise_reason_code), '') is null
      or nullif(trim(d.requested_timing), '') is null
      or nullif(trim(d.manager_timing), '') is null
    );

  if v_raise_missing > 0 then
    update public.reviews set status = 'blocked' where id = p_review_id;
    raise exception 'Raise request is incomplete';
  end if;

  update public.reviews
  set status = 'finalized',
      finalized_at = now(),
      review_date = coalesce(review_date, current_date),
      updated_at = now()
  where id = p_review_id
  returning * into v_review;

  v_review := private.refresh_finalized_review_intelligence(v_review.id);

  insert into public.review_summaries(company_id, review_id, template_version)
  values(v_review.company_id, v_review.id, 'CTOD-2PAGE-1.2')
  on conflict(review_id) do update
  set generated_at = now(),
      template_version = excluded.template_version;

  insert into public.audit_events(
    company_id,
    actor_user_id,
    event_type,
    entity_type,
    entity_id,
    after_json
  )
  values(
    v_review.company_id,
    auth.uid(),
    'review.finalized',
    'review',
    v_review.id,
    to_jsonb(v_review)
  );

  perform public.recalculate_coaching_lifecycle(l.coaching_id)
  from public.coaching_review_links l
  where l.review_id = p_review_id;

  if not exists(
    select 1
    from public.reviews x
    where x.employee_id = v_review.employee_id
      and x.status <> 'finalized'
  ) then
    v_next_date := coalesce(
      v_review.next_review_date,
      (v_review.review_date + interval '6 months')::date
    );
    v_cycle := extract(year from v_next_date)::int::text
      || case when extract(month from v_next_date)::int <= 6 then '-H1' else '-H2' end;
    v_due := case
      when extract(month from v_next_date)::int <= 6
        then make_date(extract(year from v_next_date)::int, 6, 30)
      else make_date(extract(year from v_next_date)::int, 12, 31)
    end;

    insert into public.review_campaigns(company_id, location_id, cycle_code, due_date, status)
    values(v_review.company_id, v_review.location_id, v_cycle, v_due, 'upcoming')
    on conflict(company_id, cycle_code, location_id) do update
    set due_date = excluded.due_date
    returning id into v_next_campaign;

    select id into v_next_config
    from public.configuration_versions
    where company_id = v_review.company_id
      and status::text = 'published'
    order by published_at desc nulls last, created_at desc
    limit 1;

    v_next_config := coalesce(v_next_config, v_review.config_version_id);

    insert into public.reviews(
      company_id,
      employee_id,
      campaign_id,
      location_id,
      role_id,
      config_version_id,
      status,
      review_date,
      scheduled_review_date,
      next_review_date,
      source_client
    )
    values(
      v_review.company_id,
      v_review.employee_id,
      v_next_campaign,
      v_review.location_id,
      v_review.role_id,
      v_next_config,
      'not_due',
      null,
      v_next_date,
      (v_next_date + interval '6 months')::date,
      'web'
    );

    insert into public.audit_events(
      company_id,
      actor_user_id,
      event_type,
      entity_type,
      entity_id,
      after_json
    )
    select
      v_review.company_id,
      auth.uid(),
      'review.next_cycle_created',
      'review',
      x.id,
      jsonb_build_object(
        'prior_review_id', v_review.id,
        'scheduled_review_date', v_next_date,
        'next_review_date', (v_next_date + interval '6 months')::date
      )
    from public.reviews x
    where x.employee_id = v_review.employee_id
      and x.campaign_id = v_next_campaign;
  end if;

  return v_review;
end
$function$;

revoke execute on function public.finalize_review(uuid) from public, anon;
grant execute on function public.finalize_review(uuid) to authenticated, service_role;

create or replace view public.v_promotion_readiness
with (security_invoker = true) as
select
  e.company_id,
  e.id as employee_id,
  e.employee_code,
  e.first_name || ' ' || e.last_name as employee_name,
  a.location_id,
  l.location_code,
  l.name as location_name,
  a.role_id,
  r.title as current_job_title,
  sr.target_role_id,
  tr.title as target_role,
  sr.readiness,
  case
    when sr.readiness = 'Ready Now' then 'green'
    when sr.readiness = 'Ready in 1 Year' then 'green'
    when sr.readiness = 'Ready in 2-3 Years' then 'yellow'
    else 'red'
  end as readiness_light,
  case
    when sr.readiness = 'Ready Now' then 100
    when sr.readiness = 'Ready in 1 Year' then 75
    when sr.readiness = 'Ready in 2-3 Years' then 50
    else 20
  end as readiness_score,
  sr.mobility,
  sr.manager_recommendation,
  sr.performance_trend,
  sr.last_updated_at,
  (
    select count(distinct (lower(trim(g.goal_text)), g.target_date))
    from public.goals g
    where g.employee_id = e.id
      and g.status in ('not_started', 'in_progress')
  ) as active_goals,
  (
    select count(*)
    from public.coaching_moments c
    where c.employee_id = e.id
      and c.active_carry_forward
  ) as active_coaching,
  (
    select max(rv.finalized_at)
    from public.reviews rv
    where rv.employee_id = e.id
      and rv.status = 'finalized'
  ) as last_review_date
from public.employees e
join public.employment_assignments a
  on a.employee_id = e.id
 and a.effective_to is null
join public.locations l on l.id = a.location_id
join public.roles r on r.id = a.role_id
left join public.succession_records sr
  on sr.employee_id = e.id
 and sr.active = true
left join public.roles tr on tr.id = sr.target_role_id
where e.employment_status = 'active';

do $backfill$
declare
  finalized record;
begin
  for finalized in
    select id
    from public.reviews
    where status = 'finalized'
    order by coalesce(finalized_at, created_at), created_at
  loop
    perform private.refresh_finalized_review_intelligence(finalized.id);
  end loop;
end
$backfill$;
