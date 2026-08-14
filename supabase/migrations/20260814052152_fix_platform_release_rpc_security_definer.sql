-- CTOD Production Owner Console
-- Allow the service-role-only platform release RPC to read the hidden control-plane schema
-- while preserving the existing internal platform_admin authorization check.

alter function public.operator_service_platform_releases(uuid) security definer;
