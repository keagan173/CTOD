-- CREATE OR REPLACE VIEW resets explicitly configured view options when they
-- are omitted. Keep promotion readiness governed by the invoking user's RLS.

alter view public.v_promotion_readiness
set (security_invoker = true);
