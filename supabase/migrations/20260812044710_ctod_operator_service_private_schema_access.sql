begin;

-- Sandbox migration history version: 20260812044710.

-- Operator RPCs are security invokers. The service role already has explicit
-- table privileges but also needs schema visibility to reach those tables.
grant usage on schema private to service_role;

commit;
