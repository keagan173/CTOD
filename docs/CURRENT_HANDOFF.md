# CTOD Current Project Handoff

Updated: 2026-08-12

## Current state

- Production source remained on GitHub `main`; the observed starting commit was `c320fbd`.
- Production Supabase was read-only during sandbox construction.
- Production ended with the same observed baseline: Auth 3, locations 55, employees 0, assignments 0, reviews 0, answers 0, coaching moments 0, goals 0, and audit events 13.
- Repository candidate version is 1.1.0 on `agent/ctod-operator-control-plane`.
- The isolated Supabase project is `CTOD Sandbox` / `zgwkjyezpgboysiklodj`.
- The isolated Vercel project is `ctod-sandbox`.
- The sandbox has one Commercial Tire owner login, one independent platform-operator login, three fake Location 040 employee records, and one customer-neutral operator acceptance tenant. Employees are records only and never log in.
- The platform operator has zero company memberships. The Sandbox Master remains a customer owner and is not a platform operator.
- The Operator Control Plane provides customer provisioning, lifecycle, aggregate diagnostics, operations metadata, release assignment, access-account support, and operator-account administration.
- Customer suspension/restore passed with one exact owner membership held and restored; customer configuration access was empty while suspended and returned after reactivation.
- Operator diagnostics exposed aggregate counts and the owner account email/role only; no employee identity or review-content fields were returned.
- The reset/reseed transaction was proven with a disposable fourth employee; it preserved Auth, profile, membership, role, and bootstrap audit marker.
- Real sandbox Auth sign-in succeeded, `my_ctod_context` returned `owner` / `is_master: true`, and the manager roster RPC returned exactly three employees.
- Supabase advisors reported no control-plane security finding. The 29 inherited security warnings remain; all new control-plane foreign-key index findings were resolved.

## Hosting gate

The stable sandbox alias is `https://ctod-sandbox-keaganelsberry-4694s-projects.vercel.app`. The Vercel team enforces Vercel Authentication on it. This protection was not disabled. The connected management surface could create the project/deployments but could not change protection or mint a share URL.

An official claimable/public fallback was considered but not used because it would upload the bundle outside the connected Vercel account. Therefore an unauthenticated deployed-UI pass is not claimed. Functional Auth/RPC, build, syntax, reset, seed, and isolation checks passed.

## Source-of-truth references

- [Sandbox architecture and reset runbook](SANDBOX_ARCHITECTURE.md)
- [Production QA release record](PRODUCTION_QA_RELEASE_2026-08-11.md)
- [Operation-ready baseline](OPERATION_READY_BASELINE_2026-08-09.md)
- [Repository changelog](../CHANGELOG.md)
- [Deployment standard](../DEPLOYMENT.md)

## Exact next action

1. Review the `agent/ctod-operator-control-plane` draft pull request without merging automatically.
2. Verify the protected sandbox deployment with the separately delivered Sandbox Operator credential.
3. Exercise customer search, diagnostics, and the retained `CTOD Operator Acceptance Co` lifecycle from the deployed console.
4. Decide whether the protected sandbox should be shared with additional named testers.
5. Plan production migration/operator bootstrap as a separate release; do not apply sandbox acceptance identities or data to production.

## Release guardrails

- Production publishes only through GitHub `main` and the existing `ctod` Vercel project.
- A production build must resolve to Supabase ref `wezcuprboyvbmlnuqdoi`.
- A sandbox build must resolve to `zgwkjyezpgboysiklodj` and refuses the production ref.
- Server-side invitation/account functions deny sandbox email actions unless the exact allowlist is configured.
- The one-time bootstrap endpoint is permanently closed.
- Preserve legitimate employee/review history and finalized-review immutability.
- Employee records never become Auth users implicitly.
