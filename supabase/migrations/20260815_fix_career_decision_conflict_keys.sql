-- Align career_decisions upserts with the actual unique key (review_id, employee_id).
-- Fixes Save Draft / Finalize failures for next-year goal, readiness, Employee Voice,
-- relocation, and specialist growth.

create or replace function public.save_review_employee_voice(p_review_id uuid, p_safety_priority_response text, p_career_feeling_response text)
returns public.career_decisions
language plpgsql security definer
set search_path to 'public','private','pg_catalog'
as $function$
declare v public.reviews; c public.career_decisions;
begin
 select * into v from public.reviews where id=p_review_id;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(v.company_id,v.location_id) then raise exception 'Access denied'; end if;
 if v.status='finalized' then raise exception 'Finalized review cannot be changed'; end if;
 if p_safety_priority_response not in ('Yes','No') then raise exception 'Safety response must be Yes or No'; end if;
 if p_career_feeling_response not in ('Yes','No') then raise exception 'Career response must be Yes or No'; end if;
 insert into public.career_decisions(company_id,review_id,employee_id,safety_priority_response,career_feeling_response)
 values(v.company_id,v.id,v.employee_id,p_safety_priority_response,p_career_feeling_response)
 on conflict(review_id,employee_id) do update set safety_priority_response=excluded.safety_priority_response,career_feeling_response=excluded.career_feeling_response
 returning * into c;
 return c;
end $function$;

create or replace function public.save_review_employee_voice(p_review_id uuid, p_safety_priority_response text, p_career_feeling_response text, p_work_preference_response text, p_relocation_openness_response text)
returns public.career_decisions
language plpgsql security definer
set search_path to 'public','private','pg_catalog'
as $function$
declare v public.reviews; c public.career_decisions;
begin
 select * into v from public.reviews where id=p_review_id;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(v.company_id,v.location_id) then raise exception 'Access denied'; end if;
 if v.status='finalized' then raise exception 'Finalized review cannot be changed'; end if;
 if p_safety_priority_response not in ('Yes','No') then raise exception 'Safety response must be Yes or No'; end if;
 if p_career_feeling_response not in ('Yes','No') then raise exception 'Career response must be Yes or No'; end if;
 if p_work_preference_response not in ('More money / more hours','More flexibility / flexible hours') then raise exception 'Invalid work preference response'; end if;
 if p_relocation_openness_response not in ('Yes','No','Maybe, depending on the opportunity') then raise exception 'Invalid relocation response'; end if;
 insert into public.career_decisions(company_id,review_id,employee_id,safety_priority_response,career_feeling_response,work_preference_response,relocation_openness_response)
 values(v.company_id,v.id,v.employee_id,p_safety_priority_response,p_career_feeling_response,p_work_preference_response,p_relocation_openness_response)
 on conflict(review_id,employee_id) do update set safety_priority_response=excluded.safety_priority_response,career_feeling_response=excluded.career_feeling_response,work_preference_response=excluded.work_preference_response,relocation_openness_response=excluded.relocation_openness_response
 returning * into c;
 return c;
end $function$;

create or replace function public.save_review_career_prompts(p_review_id uuid, p_next_year_goal text, p_five_year_position text)
returns public.career_decisions
language plpgsql security definer
set search_path to 'public','private','pg_catalog'
as $function$
declare v public.reviews; c public.career_decisions;
begin
 select * into v from public.reviews where id=p_review_id;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(v.company_id,v.location_id) then raise exception 'Access denied'; end if;
 if v.status='finalized' then raise exception 'Finalized review cannot be changed'; end if;
 insert into public.career_decisions(company_id,review_id,employee_id,next_year_goal,five_year_position)
 values(v.company_id,v.id,v.employee_id,nullif(trim(p_next_year_goal),''),nullif(trim(p_five_year_position),''))
 on conflict(review_id,employee_id) do update set next_year_goal=excluded.next_year_goal,five_year_position=excluded.five_year_position
 returning * into c;
 return c;
end $function$;

create or replace function public.save_review_promotion_readiness(p_review_id uuid, p_promotion_readiness text)
returns public.career_decisions
language plpgsql security definer
set search_path to 'public','private','pg_catalog'
as $function$
declare v public.reviews; c public.career_decisions;
begin
 select * into v from public.reviews where id=p_review_id;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(v.company_id,v.location_id) then raise exception 'Access denied'; end if;
 if v.status='finalized' then raise exception 'Finalized review cannot be changed'; end if;
 if p_promotion_readiness not in ('Ready Now','30-90 Days','Within 1 Year','Not Yet Ready') then raise exception 'Invalid promotion readiness'; end if;
 insert into public.career_decisions(company_id,review_id,employee_id,promotion_readiness)
 values(v.company_id,v.id,v.employee_id,p_promotion_readiness)
 on conflict(review_id,employee_id) do update set promotion_readiness=excluded.promotion_readiness
 returning * into c;
 return c;
end $function$;

create or replace function public.save_review_specialist_growth(p_review_id uuid, p_specialist_growth_path text)
returns public.career_decisions
language plpgsql security definer
set search_path to 'public','private','pg_catalog'
as $function$
declare v public.reviews; c public.career_decisions;
begin
 select * into v from public.reviews where id=p_review_id;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(v.company_id,v.location_id) then raise exception 'Access denied'; end if;
 if v.status='finalized' then raise exception 'Finalized review cannot be changed'; end if;
 if p_specialist_growth_path not in ('Training / certifications','Mentorship / training others','More responsibility in current specialty','Management responsibility','Higher-level specialist / broader organizational scope','Advanced technical mastery','Cross-functional specialist experience') then raise exception 'Invalid specialist growth path'; end if;
 insert into public.career_decisions(company_id,review_id,employee_id,specialist_growth_path)
 values(v.company_id,v.id,v.employee_id,p_specialist_growth_path)
 on conflict(review_id,employee_id) do update set specialist_growth_path=excluded.specialist_growth_path
 returning * into c;
 return c;
end $function$;
