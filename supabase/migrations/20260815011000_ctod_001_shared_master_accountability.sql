create or replace function public.company_location_accountability_map()
returns table(location_id uuid, location_code text, location_name text, market_name text, area_name text, health text, health_reason text)
language sql stable security definer set search_path='public','private','pg_catalog'
as $function$
with me as (
 select cm.company_id from public.company_memberships cm where cm.user_id=auth.uid() and cm.active=true limit 1
), locs as (
 select l.id,l.location_code,l.name,l.market_name,l.area_name from public.locations l join me on me.company_id=l.company_id where l.status='active'
), review_stats as (
 select r.location_id,
        count(*) filter(where r.status<>'finalized' and r.scheduled_review_date is not null and r.scheduled_review_date < current_date)::int overdue,
        count(*) filter(where r.scheduled_review_date is not null)::int scheduled
 from public.reviews r join me on me.company_id=r.company_id group by r.location_id
)
select l.id,l.location_code,l.name,l.market_name,l.area_name,
 case when coalesce(rs.scheduled,0)=0 then 'yellow'
      when (coalesce(rs.overdue,0)::numeric/greatest(rs.scheduled,1)) > .20 then 'red'
      when coalesce(rs.overdue,0)>0 then 'yellow'
      else 'green' end,
 case when coalesce(rs.scheduled,0)=0 then 'No CTOD review schedule data yet'
      when (coalesce(rs.overdue,0)::numeric/greatest(rs.scheduled,1)) > .20 then 'More than 20% of scheduled reviews are overdue'
      when coalesce(rs.overdue,0)>0 then 'Some scheduled reviews are overdue'
      else 'Scheduled reviews are current' end
from locs l left join review_stats rs on rs.location_id=l.id
order by l.location_code;
$function$;
revoke all on function public.company_location_accountability_map() from public;
grant execute on function public.company_location_accountability_map() to authenticated;

create or replace function public.talent_search_scope()
returns table(employee_id uuid,employee_name text,location_code text,role_title text,career_direction text,next_role text,promotion_readiness text,specialist_growth_path text,finalized_at timestamptz)
language sql stable security definer set search_path='public','private','pg_catalog'
as $function$
with ranked as (
 select r.employee_id,r.location_id,r.role_id,r.finalized_at,cd.career_direction,cd.desired_role_id,cd.promotion_readiness,cd.specialist_growth_path,
        row_number() over(partition by r.employee_id order by r.finalized_at desc nulls last,r.updated_at desc) rn
 from public.reviews r join public.career_decisions cd on cd.review_id=r.id
 where r.status='finalized' and private.can_access_location(r.company_id,r.location_id)
)
select e.id,e.first_name||' '||e.last_name,l.location_code,ro.title,ranked.career_direction,nr.title,ranked.promotion_readiness,ranked.specialist_growth_path,ranked.finalized_at
from ranked join public.employees e on e.id=ranked.employee_id join public.locations l on l.id=ranked.location_id join public.roles ro on ro.id=ranked.role_id left join public.roles nr on nr.id=ranked.desired_role_id
where ranked.rn=1;
$function$;
revoke all on function public.talent_search_scope() from public;
grant execute on function public.talent_search_scope() to authenticated;