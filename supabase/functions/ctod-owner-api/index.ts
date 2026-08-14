// CTOD Production Owner API v7
// Production deployment requires a verified Platform Owner and an AAL2 Supabase Auth session.
//
// v7 fixes Base64URL claim decoding by restoring JWT payload padding before atob().
// This resolves valid AAL2 sessions being rejected with HTTP 400 after successful MFA.
//
// SECURITY CONTRACT
// 1. verify_jwt=true at the Edge Function boundary.
// 2. Decode the presented access token as padded Base64URL and reject unless claims.aal === "aal2".
// 3. Resolve the authenticated user through Supabase Auth.
// 4. Require private.platform_operators.active=true and operator_role='platform_admin'.
// 5. Only then expose owner dashboard, template/customer provisioning, customer sandbox,
//    validation/promotion/rollback, and platform release-management actions.
// 6. All privileged database operator RPCs remain service-role-only.
//
// Runtime implementation is deployed as Supabase Edge Function `ctod-owner-api` v7.
