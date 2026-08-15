create or replace function public.review_finalization_checklist(p_review_id uuid)
returns table(code text,label text,complete boolean)
language plpgsql
stable security definer
set search_path to 'public','private','pg_catalog'
as $function$
declare
 v public.reviews;
 c public.career_decisions;
 comp public.compensation_decisions;
 q_missing integer:=0;
 coach_missing integer:=0;
begin
 select * into v from public.reviews where id=p_review_id;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(v.company_id,v.location_id) then raise exception 'Access denied'; end if;
 select * into c from public.career_decisions where review_id=p_review_id limit 1;
 select * into comp from public.compensation_decisions where review_id=p_review_id limit 1;
 select count(*) into q_missing from public.get_review_validation_issues(p_review_id);
 select count(*) into coach_missing from public.get_review_coaching_validation_issues(p_review_id);
 return query values
 ('performance','Required performance answers confirmed',q_missing=0),
 ('coaching','Active coaching dispositions complete',coach_missing=0),
 ('career_direction','Career direction selected',c.career_direction is not null),
 ('career_reason','Why this career path? answered',nullif(trim(coalesce(c.career_direction_reason,'')),'') is not null),
 ('next_year_goal','Next-year goal selected',nullif(trim(coalesce(c.next_year_goal,'')),'') is not null),
 ('voice_safety','Employee Voice · safety priority answered',nullif(trim(coalesce(c.safety_priority_response,'')),'') is not null),
 ('voice_career','Employee Voice · career answered',nullif(trim(coalesce(c.career_feeling_response,'')),'') is not null),
 ('voice_work','Employee Voice · money/hours vs flexibility answered',nullif(trim(coalesce(c.work_preference_response,'')),'') is not null),
 ('voice_relocation','Employee Voice · relocation answered',nullif(trim(coalesce(c.relocation_openness_response,'')),'') is not null),
 ('advancement_roles','Advancement · next and long-term roles selected',coalesce(c.career_direction,'')<>'ADVANCEMENT' or (c.desired_role_id is not null and c.final_desired_role_id is not null)),
 ('advancement_readiness','Advancement · manager readiness selected',coalesce(c.career_direction,'')<>'ADVANCEMENT' or nullif(trim(coalesce(c.promotion_readiness,'')),'') is not null),
 ('specialist_path','Specialist · growth path selected',coalesce(c.career_direction,'')<>'SPECIALIST' or nullif(trim(coalesce(c.specialist_growth_path,'')),'') is not null),
 ('compensation','Raise discussion complete when requested',coalesce(comp.raise_requested,false)=false or (nullif(trim(coalesce(comp.raise_reason_code,'')),'') is not null and nullif(trim(coalesce(comp.requested_timing,'')),'') is not null and nullif(trim(coalesce(comp.manager_timing,'')),'') is not null));
end $function$;