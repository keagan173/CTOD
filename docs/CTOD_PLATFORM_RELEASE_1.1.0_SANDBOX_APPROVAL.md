# CTOD Platform Release 1.1.0 - Sandbox Approval

Date: 2026-08-13
Environment: CTOD 002 Sandbox only
Production impact: none

## Release gates
CTOD 1.1.0 passed the Sandbox release validation after:
- multi-industry acceptance for Commercial Tire, Landscaping and Restaurant tenant shapes;
- customer configuration validation for fictional Landscaping and Restaurant tenants;
- tenant-integrity checks with zero cross-company question/rating/template-lineage mismatches;
- Restaurant executive vs location-manager authorization acceptance;
- direct RLS proof showing the manager receives only R01 while the executive receives R01-R05;
- authenticated SECURITY DEFINER inventory review with zero unreviewed privileged RPCs in the CTOD review registry;
- legacy privileged RPC exposure cleanup;
- Supabase leaked-password protection enabled after project upgrade to Pro;
- successful disposable Platform Release schedule/activate/rollback acceptance.

## Supabase advisor interpretation
The leaked-password warning cleared after enabling the feature. Remaining SECURITY DEFINER warnings correspond to reviewed, intentional signed-in business RPCs that enforce caller authorization inside the function. These warnings remain visible because the Supabase linter flags signed-in SECURITY DEFINER exposure categorically.

## Release state
1.1.0 was revalidated with automated tests = PASS, security review = PASS, acceptance = PASS.
It was then approved as `available` in CTOD 002.

## Controlled pilot
1.1.0 was scheduled and activated for the two fictional acceptance tenants only:
- GreenScape Acceptance Co
- Restaurant Acceptance Group

Both moved from core version 1.0.1 to 1.1.0 and retain 1.0.1 as the rollback version.
Commercial Tire remained on 1.0.1 and was not included in the pilot.

## Production rule
This approval is a Sandbox release-management milestone. It does not authorize deployment to CTOD 001 Production. Production promotion requires a separate production-readiness checkpoint, hosting/domain plan, production owner identity/MFA, migration review, backup/rollback plan and explicit controlled promotion decision.
