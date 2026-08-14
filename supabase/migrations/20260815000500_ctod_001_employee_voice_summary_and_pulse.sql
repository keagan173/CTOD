-- 001 employee voice: review retrieval, two-page summary payload, and scope-aware dashboard pulse.
create or replace function public.get_review_employee_voice(p_review_id uuid)
returns jsonb language plpgsql stable set search_path='public','private','pg_catalog' as $function$
declare r public.reviews; cd public.career_decisions;
begin
 select * into r from public.reviews where id=p_review_id;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(r.company_id,r.location_id) then raise exception 'Access denied'; end if;
 select * into cd from public.career_decisions where review_id=r.id;
 return jsonb_build_object('safety_priority_response',cd.safety_priority_response,'career_feeling_response',cd.career_feeling_response,'work_preference_response',cd.work_preference_response,'relocation_openness_response',cd.relocation_openness_response,'next_year_goal',cd.next_year_goal,'five_year_position',cd.five_year_position);
end $function$;
grant execute on function public.get_review_employee_voice(uuid) to authenticated;

-- Production review_print_summary is extended by this release to include employee_voice and career prompt fields.
-- Production employee_voice_pulse() returns scope-filtered overall, by_role, and by_location aggregates using private.can_access_location().