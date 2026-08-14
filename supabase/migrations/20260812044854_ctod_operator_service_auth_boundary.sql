begin;

-- Sandbox migration history version: 20260812044854.

-- These two narrowly exposed, service-role-only routines must validate against
-- auth.users. Run them as their migration owner rather than granting the
-- service role broad SELECT access to the Auth schema.
alter function public.operator_service_provision_customer(
  uuid,text,text,text,text,text,text,integer,uuid
) security definer;

alter function public.operator_service_upsert_operator(
  uuid,uuid,text,text,boolean,uuid
) security definer;

commit;
