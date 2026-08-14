# CTOD Current Project Handoff

Updated: 2026-08-11

## Current state

- Production source remained on GitHub `main`; the observed starting commit was `c320fbd`.
- Production Supabase was read-only during sandbox construction.
- Production ended with the same observed baseline: Auth 3, locations 55, employees 0, assignments 0, reviews 0, answers 0, coaching moments 0, goals 0, and audit events 13.
- Repository candidate version is 1.1.0 on `agent/ctod-sandbox`.
- The isolated Supabase project is `CTOD Sandbox` / `zgwkjyezpgboysiklodj`.
- The isolated Vercel project is `ctod-sandbox`.
- The sandbox has one owner login and three fake Location 040 employee records. Employees are records only and never log in.
- The reset/reseed transaction was proven with a disposable fourth employee; it preserved Auth, profile, membership, role, and bootstrap audit marker.
- Real sandbox Auth sign-in succeeded, `my_ctod_context` returned `owner` / `is_master: true`, and the manager roster RPC returned exactly three employees.
- Supabase advisors reported no errors and the same 29 inherited security warnings as production.

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

1. Review the `agent/ctod-sandbox` pull request/candidate without merging automatically.
2. Decide whether the `ctod-sandbox` project should remain Vercel-authenticated or be made accessible to a named tester.
3. If protected, grant that tester Vercel access; then use the separately delivered Sandbox Master credential.
4. Run one visual login/review pass on the deployed alias.
5. Merge only the application infrastructure after review. Never apply the baseline/reset/seed files to production.

## Release guardrails

- Production publishes only through GitHub `main` and the existing `ctod` Vercel project.
- A production build must resolve to Supabase ref `wezcuprboyvbmlnuqdoi`.
- A sandbox build must resolve to `zgwkjyezpgboysiklodj` and refuses the production ref.
- Server-side invitation/account functions deny sandbox email actions unless the exact allowlist is configured.
- The one-time bootstrap endpoint is permanently closed.
- Preserve legitimate employee/review history and finalized-review immutability.
- Employee records never become Auth users implicitly.
