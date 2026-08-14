// CTOD Production Owner API v6
// Production deployment requires a verified Platform Owner and an AAL2 Supabase Auth session.
// Runtime source is deployed to Supabase Edge Functions. This repository checkpoint records the enforced security contract.
//
// SECURITY CONTRACT
// 1. verify_jwt=true at the Edge Function boundary.
// 2. Decode the presented access token and reject unless claims.aal === "aal2".
// 3. Resolve the authenticated user through Supabase Auth.
// 4. Require private.platform_operators.active=true and operator_role='platform_admin'.
// 5. Only then expose owner dashboard, template/customer provisioning, customer sandbox,
//    validation/promotion/rollback, and platform release-management actions.
// 6. All privileged database operator RPCs remain service-role-only.
//
// The complete deployed v6 implementation is maintained in the Supabase Edge Function
// `ctod-owner-api`; this file intentionally documents the production security boundary
// without embedding environment secrets.
