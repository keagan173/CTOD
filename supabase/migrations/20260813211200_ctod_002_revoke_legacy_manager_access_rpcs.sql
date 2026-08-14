-- CTOD 002 security hardening.
-- These legacy SECURITY DEFINER RPCs are not referenced by the current ctod-002 application
-- and are not called by other database functions. Remove direct signed-in execution while
-- retaining service-role access for controlled backend compatibility.

revoke execute on function public.accept_manager_invitation() from authenticated;
revoke execute on function public.admin_grant_location_access_by_email(uuid,text,public.membership_role) from authenticated;
revoke execute on function public.invite_location_manager(uuid,text) from authenticated;
revoke execute on function public.replace_location_manager(uuid,uuid) from authenticated;

grant execute on function public.accept_manager_invitation() to service_role;
grant execute on function public.admin_grant_location_access_by_email(uuid,text,public.membership_role) to service_role;
grant execute on function public.invite_location_manager(uuid,text) to service_role;
grant execute on function public.replace_location_manager(uuid,uuid) to service_role;
