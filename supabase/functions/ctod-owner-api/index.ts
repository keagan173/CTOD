// CTOD Production Owner API v8
// Production deployment requires a verified Platform Owner and an AAL2 Supabase Auth session.
//
// v8 removes the failed PostgREST lookup of private.platform_operators. The private schema
// intentionally remains unexposed. Owner authorization is now proven by calling the
// service-role-only operator_service_dashboard RPC, which performs the platform_admin check
// internally in PostgreSQL. The successful dashboard result is reused for the home action.
//
// SECURITY CONTRACT
// 1. verify_jwt=true at the Edge Function boundary.
// 2. Decode the presented access token as padded Base64URL and require claims.aal === "aal2".
// 3. Resolve the authenticated user through Supabase Auth.
// 4. Call operator_service_dashboard with that authenticated user ID as the authorization gate.
//    The RPC checks private.platform_operators internally; private tables are never exposed via REST.
// 5. Only after that gate succeeds expose owner dashboard, provisioning, customer sandbox,
//    validation/promotion/rollback, template administration and platform release actions.
// 6. All privileged operator RPCs remain service-role-only.
//
// Runtime implementation is deployed as Supabase Edge Function `ctod-owner-api` v8.
