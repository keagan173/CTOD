# CTOD Project Handoff

Version 1.3.1
Current build state: 2026-08-13

## Governing Architecture
CTOD remains one commercial multi-tenant SaaS platform. CTOD Production is the commercial system of record and permanent Platform Owner control plane. CTOD 002 Sandbox is the development/staging/security/acceptance environment for the CTOD product itself. Customer sandboxes are tenant-scoped configuration drafts inside the commercial platform.

## Completed Since v1.3.0
Platform Release Management has moved from concept to implemented Sandbox infrastructure.

Implemented in CTOD 002:
- `private.platform_release_validations`
- `private.platform_release_targets`
- owner-only platform release read service
- platform release validation gate
- platform release approval gate
- staged rollout scheduling: pilot / selected / all
- per-customer rollout targets/status
- platform release activation service
- platform release rollback service
- operator audit events for release operations
- customer release history integration
- CTOD Owner deployment Edge Function v4 with platform-release actions
- Owner Console v1.3.1 prototype with Platform Releases panel

## Verified Gate Behavior
Release `1.1.0` remains a candidate. Automated tests and acceptance are recorded as passing, but security review is recorded as failing because current Supabase security advisor warnings remain unresolved. Attempting to approve `1.1.0` correctly raises: `Latest platform release validation must pass before approval`.

This is intentional. Do not make `1.1.0` available until the security review is genuinely clean.

## Source Control
Platform release schema/services are versioned on `ctod-002` in:
- `supabase/migrations/20260814001000_ctod_002_platform_release_tables.sql`
- `supabase/migrations/20260814001100_ctod_002_platform_release_services.sql`
- `supabase/migrations/20260814001200_ctod_002_platform_release_rollout.sql`

## Current Security Blockers Before Platform Release Approval
The Supabase security advisor still reports authenticated access to multiple older `SECURITY DEFINER` functions. These must be reviewed individually and either intentionally authorized with strong internal checks, changed to security invoker, moved/restricted, or have EXECUTE revoked as appropriate. Leaked-password protection is also still disabled.

## Owner Identity
The active CTOD 002 Platform Owner is now the real Sandbox account controlled by Keagan. The synthetic sandbox operator account is inactive and retained for test/history purposes only.

## Owner Console
The Supabase Edge Function URL renders HTML source in the user's browser and must not be treated as the final UI host. A standalone Owner Console file is being used temporarily for CTOD 002 testing. Permanent Owner Console hosting remains a required infrastructure item before commercial launch.

## Next Engineering Block
1. Audit every authenticated `SECURITY DEFINER` function and document intentional customer-facing RPCs.
2. Remove or harden unsafe grants until the platform release security gate can pass honestly.
3. Enable leaked-password protection and prepare MFA requirements for Production owner/admin identities.
4. Complete Platform Release positive-path acceptance testing using fictional tenants only.
5. Add Industry Template administration to Owner Console.
6. Add Create Customer / Provision Tenant workflow to Owner Console.
7. Acceptance-test three tenant shapes from the same codebase: large tire/automotive, one-location landscaping with growth, five-location restaurant group.
8. Only after all gates pass, plan controlled promotion from CTOD 002 into CTOD Production.

## Start Here Next Session
Resume on `ctod-002`. Keep CTOD 001/Production protected. Begin with the SECURITY DEFINER authorization audit. Do not override the failing security gate merely to advance release status.
