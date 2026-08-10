-- Deployment security hardening for legacy views and RPC grants.
-- Authenticated callers still use the same application flows; anonymous callers
-- no longer receive database-owner view behavior or callable management RPCs.

alter view public.v_master_kpis set (security_invoker = true);
alter view public.v_master_review_history set (security_invoker = true);
alter view public.v_promotion_pipeline set (security_invoker = true);

revoke all on public.v_master_kpis from public, anon, authenticated;
revoke all on public.v_master_review_history from public, anon, authenticated;
revoke all on public.v_promotion_pipeline from public, anon, authenticated;

grant select on public.v_master_kpis to authenticated;
grant select on public.v_master_review_history to authenticated;
grant select on public.v_promotion_pipeline to authenticated;

revoke execute on function public.accept_access_invite(uuid) from public, anon;
revoke execute on function public.admin_set_location_active(uuid,boolean) from public, anon;
revoke execute on function public.admin_set_question_active(uuid,boolean) from public, anon;
revoke execute on function public.admin_set_role_active(uuid,boolean) from public, anon;
revoke execute on function public.admin_upsert_location(uuid,text,text,text,text,text,text,text,text) from public, anon;
revoke execute on function public.admin_upsert_question(uuid,uuid,text,text,text,integer) from public, anon;
revoke execute on function public.admin_upsert_role(uuid,text) from public, anon;
revoke execute on function public.list_access_invites() from public, anon;
revoke execute on function public.manager_add_employee(text,text,text,uuid,uuid,date) from public, anon;
revoke execute on function public.manager_deactivate_employee(uuid) from public, anon;
revoke execute on function public.manager_edit_employee(uuid,text,text,date,uuid,uuid) from public, anon;
revoke execute on function public.manager_prepare_review(uuid) from public, anon;
revoke execute on function public.manager_set_review_schedule(uuid,date,date) from public, anon;
revoke execute on function public.manager_workspace_employees() from public, anon;
revoke execute on function public.revoke_access_invite(uuid) from public, anon;
revoke execute on function public.save_review_career_path(uuid,text,text,uuid,uuid) from public, anon;
revoke execute on function public.save_review_career_roles(uuid,uuid,uuid) from public, anon;
revoke execute on function public.set_coaching_review_link_company() from public, anon;

grant execute on function public.accept_access_invite(uuid) to authenticated;
grant execute on function public.admin_set_location_active(uuid,boolean) to authenticated;
grant execute on function public.admin_set_question_active(uuid,boolean) to authenticated;
grant execute on function public.admin_set_role_active(uuid,boolean) to authenticated;
grant execute on function public.admin_upsert_location(uuid,text,text,text,text,text,text,text,text) to authenticated;
grant execute on function public.admin_upsert_question(uuid,uuid,text,text,text,integer) to authenticated;
grant execute on function public.admin_upsert_role(uuid,text) to authenticated;
grant execute on function public.list_access_invites() to authenticated;
grant execute on function public.manager_add_employee(text,text,text,uuid,uuid,date) to authenticated;
grant execute on function public.manager_deactivate_employee(uuid) to authenticated;
grant execute on function public.manager_edit_employee(uuid,text,text,date,uuid,uuid) to authenticated;
grant execute on function public.manager_prepare_review(uuid) to authenticated;
grant execute on function public.manager_set_review_schedule(uuid,date,date) to authenticated;
grant execute on function public.manager_workspace_employees() to authenticated;
grant execute on function public.revoke_access_invite(uuid) to authenticated;
grant execute on function public.save_review_career_path(uuid,text,text,uuid,uuid) to authenticated;
grant execute on function public.save_review_career_roles(uuid,uuid,uuid) to authenticated;
grant execute on function public.set_coaching_review_link_company() to authenticated;
