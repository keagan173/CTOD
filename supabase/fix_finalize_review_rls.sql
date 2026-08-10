-- Finalization creates the employee's next review campaign and review.
-- Keep the existing location-access boundary while allowing that privileged,
-- transactional scheduling work to complete behind RLS.
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
    return v_review;
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

  insert into public.review_summaries(company_id, review_id, template_version)
  values(v_review.company_id, v_review.id, 'CTOD-2PAGE-1.1')
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
