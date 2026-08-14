-- CTOD review scheduling correction
-- Manager-entered scheduled_review_date is authoritative for the active employee review.
-- Following review defaults to +6 months. Campaign dates remain fallback only.

create or replace function public.manager_set_review_schedule(p_review_id uuid, p_scheduled_date date, p_next_review_date date default null::date)
returns public.reviews
language plpgsql
security definer
set search_path to 'public','private','pg_catalog'
as $function$
declare
  v public.reviews;
  v_next date;
  v_status public.review_status;
begin
  if p_scheduled_date is null then raise exception 'Scheduled review date is required'; end if;
  select * into v from public.reviews where id=p_review_id for update;
  if not found then raise exception 'Review not found'; end if;
  if not private.can_access_location(v.company_id,v.location_id) then raise exception 'Access denied'; end if;
  if v.status='finalized' then raise exception 'Finalized review schedule cannot be changed'; end if;

  v_next:=coalesce(p_next_review_date,(p_scheduled_date + interval '6 months')::date);
  v_status:=case
    when v.status in ('not_due','queued') then
      case when p_scheduled_date <= current_date then 'queued'::public.review_status else 'not_due'::public.review_status end
    else v.status
  end;

  update public.reviews
     set scheduled_review_date=p_scheduled_date,
         next_review_date=v_next,
         status=v_status,
         updated_at=now()
   where id=p_review_id
   returning * into v;

  insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,after_json)
  values(v.company_id,auth.uid(),'review.schedule_updated','review',v.id,
    jsonb_build_object('scheduled_review_date',v.scheduled_review_date,'next_review_date',v.next_review_date,'status',v.status));
  return v;
end
$function$;

create or replace function public.refresh_review_queue(p_company_id uuid)
returns integer
language plpgsql
set search_path to 'public'
as $function$
declare n integer;
begin
  update public.reviews r
     set status='queued',updated_at=now()
    from public.review_campaigns c
   where r.campaign_id=c.id
     and r.company_id=p_company_id
     and r.status='not_due'
     and current_date >= coalesce(r.scheduled_review_date,c.reminder_start_date,c.due_date);
  get diagnostics n = row_count;
  return n;
end;
$function$;

create or replace view public.v_review_queue as
select rv.company_id,
       rv.id as review_id,
       rv.employee_id,
       e.employee_code,
       e.first_name || ' ' || e.last_name as employee_name,
       rv.location_id,
       l.location_code,
       rv.role_id,
       ro.title as role_title,
       rv.campaign_id,
       c.cycle_code,
       coalesce(rv.scheduled_review_date,c.due_date) as due_date,
       case when rv.scheduled_review_date is not null then rv.scheduled_review_date else c.reminder_start_date end as reminder_start_date,
       rv.status,
       rv.started_at,
       rv.finalized_at,
       rv.next_review_date
from public.reviews rv
join public.employees e on e.id=rv.employee_id
join public.locations l on l.id=rv.location_id
join public.roles ro on ro.id=rv.role_id
join public.review_campaigns c on c.id=rv.campaign_id
where rv.status <> 'finalized'::public.review_status;

create or replace view public.v_review_work_queue as
select rv.company_id,
       rv.id as review_id,
       rv.employee_id,
       e.employee_code,
       e.first_name || ' ' || e.last_name as employee_name,
       rv.location_id,
       l.location_code,
       l.name as location_name,
       rv.role_id,
       ro.title as role_title,
       rv.status,
       rv.review_date,
       rv.next_review_date,
       rv.overall_rating_label,
       rv.overall_score,
       rv.overall_percent,
       rv.finalized_at,
       c.cycle_code,
       coalesce(rv.scheduled_review_date,c.due_date) as due_date
from public.reviews rv
join public.employees e on e.id=rv.employee_id
join public.locations l on l.id=rv.location_id
join public.roles ro on ro.id=rv.role_id
join public.review_campaigns c on c.id=rv.campaign_id
where private.can_access_location(rv.company_id,rv.location_id);
