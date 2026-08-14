-- CTOD 001 review reconciliation
-- Preserves finalized/history records. Adds the previously agreed employee development prompts.
alter table public.career_decisions
  add column if not exists next_year_goal text,
  add column if not exists five_year_position text;

create or replace function public.save_review_career_prompts(p_review_id uuid,p_next_year_goal text,p_five_year_position text)
returns public.career_decisions
language plpgsql security definer set search_path='public','private','pg_catalog'
as $function$
declare v public.reviews; c public.career_decisions;
begin
 select * into v from public.reviews where id=p_review_id;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(v.company_id,v.location_id) then raise exception 'Access denied'; end if;
 if v.status='finalized' then raise exception 'Finalized review cannot be changed'; end if;
 insert into public.career_decisions(company_id,review_id,employee_id,next_year_goal,five_year_position)
 values(v.company_id,v.id,v.employee_id,nullif(trim(p_next_year_goal),''),nullif(trim(p_five_year_position),''))
 on conflict (review_id) do update set next_year_goal=excluded.next_year_goal,five_year_position=excluded.five_year_position
 returning * into c;
 return c;
end $function$;
revoke all on function public.save_review_career_prompts(uuid,text,text) from public;
grant execute on function public.save_review_career_prompts(uuid,text,text) to authenticated;

-- Production get_review_form was also advanced in this build to return scheduled_review_date,
-- next_year_goal and five_year_position. Keep that payload contract when editing get_review_form.