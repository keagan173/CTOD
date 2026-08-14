-- Complete the 001 employee voice block before compensation.
alter table public.career_decisions
 add column if not exists work_preference_response text,
 add column if not exists relocation_openness_response text;

create or replace function public.save_review_employee_voice(p_review_id uuid,p_safety_priority_response text,p_career_feeling_response text,p_work_preference_response text,p_relocation_openness_response text)
returns public.career_decisions
language plpgsql security definer set search_path='public','private','pg_catalog'
as $function$
declare v public.reviews; c public.career_decisions;
begin
 select * into v from public.reviews where id=p_review_id;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(v.company_id,v.location_id) then raise exception 'Access denied'; end if;
 if v.status='finalized' then raise exception 'Finalized review cannot be changed'; end if;
 if p_safety_priority_response not in ('Yes','No') then raise exception 'Safety response must be Yes or No'; end if;
 if p_career_feeling_response not in ('Yes','No') then raise exception 'Career response must be Yes or No'; end if;
 if p_work_preference_response not in ('More money / more hours','More flexibility / flexible hours','A balance of both') then raise exception 'Invalid work preference response'; end if;
 if p_relocation_openness_response not in ('Yes','No','Maybe, depending on the opportunity') then raise exception 'Invalid relocation response'; end if;
 insert into public.career_decisions(company_id,review_id,employee_id,safety_priority_response,career_feeling_response,work_preference_response,relocation_openness_response)
 values(v.company_id,v.id,v.employee_id,p_safety_priority_response,p_career_feeling_response,p_work_preference_response,p_relocation_openness_response)
 on conflict(review_id) do update set safety_priority_response=excluded.safety_priority_response,career_feeling_response=excluded.career_feeling_response,work_preference_response=excluded.work_preference_response,relocation_openness_response=excluded.relocation_openness_response
 returning * into c;
 return c;
end $function$;
revoke all on function public.save_review_employee_voice(uuid,text,text,text,text) from public;
grant execute on function public.save_review_employee_voice(uuid,text,text,text,text) to authenticated;