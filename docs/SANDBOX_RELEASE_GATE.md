# CTOD Sandbox Release Gate

Updated: 2026-08-14

## Purpose

The customer sandbox is not a decorative duplicate. It is the mandatory proving ground for customer-facing software changes before Production.

CTOD has two different sandbox concepts:

1. **Customer Configuration Sandbox** — versioned tenant configuration changes such as roles, questions, locations and customer-specific settings. These are validated and promoted through the existing configuration engine.
2. **Application Sandbox** — the Vercel `ctod-sandbox` deployment used to test customer-facing application code before the Production `ctod` deployment.

Both are required. Configuration validation does not prove browser code is safe, and a browser preview does not replace tenant configuration/version controls.

## Locked release path

`GitHub ctod-sandbox branch -> Vercel ctod-sandbox -> customer-workspace acceptance -> promote exact tested commit to main -> Vercel Production ctod -> post-release health check`

Do not intentionally develop new customer-facing UI directly on `main` once the Vercel projects are branch-separated.

## Required sandbox acceptance for customer UI

Before promotion to Production, verify at minimum:

- sign in / session restore
- Reviews roster loads
- open a review
- Career Direction renders exactly once
- Advancement exposes required readiness
- Employee Voice controls load
- Compensation and comments load
- Reviews/Coaching/Employees/People/Review Schedule/Master/Depth Chart tabs switch without browser stalls
- Master company map loads
- People Pulse loads
- talent filters load
- Depth Chart loads
- browser remains responsive through repeated navigation
- no new fatal/error telemetry generated during acceptance

## Runtime support

Authenticated customer workspaces report bounded runtime signals through `report_client_runtime_event` into `client_runtime_events`.

The CTOD Platform Owner can view these without customer impersonation at `/owner-support` after Owner authentication + MFA. Signals include JavaScript errors, unhandled promise rejections, detected long main-thread stalls, release version, page path and company scope.

No employee review contents are included in runtime telemetry.

## Git branches

- `main` = Production release branch
- `ctod-sandbox` = customer application acceptance branch

The `ctod-sandbox` branch was established from the current safe Production checkpoint on 2026-08-14.

## Vercel configuration requirement

The Vercel projects must be separated so `ctod-sandbox` follows the Git `ctod-sandbox` branch while Production `ctod` follows `main`. Until this Vercel Git-branch setting is confirmed, a green `ctod-sandbox` deployment alone must not be interpreted as proof that Production has been protected by a promotion gate.

## Emergency hotfix exception

A Production outage may require an emergency direct hotfix. In that case:

1. minimize the patch to the failing behavior;
2. restore Production first;
3. immediately sync the same safe commit to `ctod-sandbox`;
4. perform acceptance checks;
5. document the incident and root cause;
6. continue normal development from the sandbox branch.

The 2026-08-14 LOC040 browser lockup is the reference incident that established this rule.
