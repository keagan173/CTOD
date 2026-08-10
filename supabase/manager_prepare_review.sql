create or replace function public.manager_prepare_review(p_employee_id uuid)
returns uuid
language plpgsql
security definer
set search_path to 'public','private','pg_catalog'
as $function$
declare
  v_emp public.employees;
  v_assignment public.employment_assignments;
  v_review public.reviews;
  v_template public.reviews;
begin
  select * into v_emp from public.employees where id=p_employee_id and employment_status='active';
  if not found then raise exception 'Active employee not found'; end if;
  select * into v_assignment from public.employment_assignments where employee_id=p_employee_id and effective_to is null order by effective_from desc limit 1;
  if v_assignment.id is null then raise exception 'Employee has no active assignment'; end if;
  if not private.can_access_location(v_emp.company_id,v_assignment.location_id) then raise exception 'Access denied'; end if;
  select * into v_review from public.reviews where employee_id=p_employee_id and status <> 'finalized' order by created_at desc limit 1;
  if v_review.id is not null then
    if v_review.location_id is distinct from v_assignment.location_id or v_review.role_id is distinct from v_assignment.role_id then
      update public.reviews set location_id=v_assignment.location_id,role_id=v_assignment.role_id,updated_at=now() where id=v_review.id returning * into v_review;
    end if;
    return v_review.id;
  end if;
  select * into v_template from public.reviews where company_id=v_emp.company_id and location_id=v_assignment.location_id order by created_at desc limit 1;
  if v_template.id is null then select * into v_template from public.reviews where company_id=v_emp.company_id order by created_at desc limit 1; end if;
  if v_template.id is null then raise exception 'No review template is available for this company'; end if;
  insert into public.reviews(company_id,employee_id,campaign_id,location_id,role_id,config_version_id,status,review_date,scheduled_review_date,next_review_date,source_client)
  values(v_emp.company_id,p_employee_id,v_template.campaign_id,v_assignment.location_id,v_assignment.role_id,v_template.config_version_id,'not_due',null,null,(current_date + interval '6 months')::date,'web')
  returning id into v_review.id;
  insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,after_json)
  values(v_emp.company_id,auth.uid(),'review.prepared','review',v_review.id,jsonb_build_object('employee_id',p_employee_id,'location_id',v_assignment.location_id,'role_id',v_assignment.role_id));
  return v_review.id;
end
$function$;
