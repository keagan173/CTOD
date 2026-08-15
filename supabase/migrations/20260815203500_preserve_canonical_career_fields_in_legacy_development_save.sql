-- System-wide protection: legacy review save must never erase canonical career intelligence.
create or replace function public.save_review_development(p_review_id uuid, p_manager_summary text, p_employee_comments text, p_goal_text text, p_goal_target_date date, p_promotion_interest boolean, p_desired_role_id uuid, p_promotion_readiness text, p_raise_requested boolean, p_raise_basis text)
returns jsonb
language plpgsql
set search_path to 'public'
as $function$
declare r public.reviews; g_id uuid;
begin
  select * into r from public.reviews where id=p_review_id for update;
  if not found then raise exception 'Review not found'; end if;
  if not private.can_access_location(r.company_id,r.location_id) then raise exception 'Access denied'; end if;
  if r.status='finalized' then raise exception 'Finalized review is immutable'; end if;
  insert into public.review_summaries(company_id,review_id,template_version,manager_summary,employee_comments) values(r.company_id,r.id,'CTOD-2PAGE-1.2',nullif(trim(p_manager_summary),''),nullif(trim(p_employee_comments),'')) on conflict(review_id) do update set manager_summary=excluded.manager_summary,employee_comments=excluded.employee_comments,generated_at=now(),template_version=excluded.template_version;
  if nullif(trim(p_goal_text),'') is not null then
    select id into g_id from public.goals where origin_review_id=r.id order by created_at limit 1 for update;
    if g_id is null then select id into g_id from public.goals where company_id=r.company_id and employee_id=r.employee_id and status in ('not_started','in_progress') and lower(trim(goal_text))=lower(trim(p_goal_text)) order by updated_at desc,created_at desc limit 1 for update; end if;
    if g_id is null then insert into public.goals(company_id,employee_id,origin_review_id,goal_text,goal_type,status,target_date) values(r.company_id,r.employee_id,r.id,trim(p_goal_text),'development','in_progress',p_goal_target_date) returning id into g_id; else update public.goals set goal_text=trim(p_goal_text),target_date=p_goal_target_date,status='in_progress',updated_at=now() where id=g_id; end if;
  end if;
  insert into public.career_decisions(company_id,review_id,employee_id,promotion_interest,desired_role_id,promotion_readiness) values(r.company_id,r.id,r.employee_id,coalesce(p_promotion_interest,false),p_desired_role_id,nullif(trim(p_promotion_readiness),'')) on conflict(review_id,employee_id) do update set promotion_interest=case when p_promotion_interest is true then true else public.career_decisions.promotion_interest end,desired_role_id=coalesce(excluded.desired_role_id,public.career_decisions.desired_role_id),promotion_readiness=coalesce(excluded.promotion_readiness,public.career_decisions.promotion_readiness);
  insert into public.compensation_decisions(company_id,review_id,employee_id,raise_requested,raise_basis,decision_status) values(r.company_id,r.id,r.employee_id,coalesce(p_raise_requested,false),nullif(trim(p_raise_basis),''),case when p_raise_requested then 'planned' else 'not_requested' end) on conflict(review_id,employee_id) do update set raise_requested=excluded.raise_requested,raise_basis=coalesce(excluded.raise_basis,public.compensation_decisions.raise_basis),decision_status=excluded.decision_status;
  return jsonb_build_object('ok',true,'goal_id',g_id);
end
$function$;