# Changelog

This changelog records accepted CTOD production and repository releases. GitHub `main` remains the application source of truth, and versioned Supabase migrations remain the database source of truth.

## 1.1.0 — 2026-08-11 (sandbox candidate)

### Added

- A fully separate Supabase database/Auth project for CTOD Sandbox (`zgwkjyezpgboysiklodj`).
- Reproducible schema and safe configuration baselines for new environments, deliberately outside production migrations.
- Guarded sandbox bootstrap, reset, seed, and verification SQL.
- One Sandbox Master Auth account and three deterministic fake Location 040 employees.
- Central environment-aware browser configuration with one Supabase client, separate session storage, feature flags, and an unmistakable fake-data banner.
- A separate `ctod-sandbox` Vercel project with preview and production-target sandbox artifacts.
- CI checks for source syntax, JSON, environment neutrality, production build identity, sandbox isolation, and refusal of a production-backed sandbox build.
- A server-side, one-time sandbox user bootstrap script that refuses production and existing Auth/membership state.
- Sandbox architecture, recreation, reset, verification, and zero-production-impact documentation.

### Hardened

- Sandbox build and runtime project-ref guards reject the production Supabase project.
- Browser builds accept publishable keys only.
- Invitation sending and acceptance both enforce the sandbox email allowlist and fail closed when server configuration is missing.
- Supabase client imports are pinned to version 2.112.2.
- The one-time administrative Edge Function was replaced with a permanent HTTP 410 implementation after the account was created.

### Verified

- Real password Auth returned HTTP 200 for the Sandbox Master account.
- User context returned `owner` and `is_master: true`; the workspace roster returned exactly three fake employees.
- A disposable fourth employee was removed by reset, while Auth/profile/membership/bootstrap state survived and the three-person seed was restored.
- Supabase security advisors reported no errors and the same inherited warning profile as production.
- Production observed counts were unchanged during sandbox work.

### Deployment note

- The connected Vercel team protects the sandbox aliases with Vercel Authentication. Protection was retained; an unauthenticated deployed-UI pass and public fallback upload are intentionally not claimed.

## 1.0.1 — 2026-08-11

### Added

- Session-safe Reviews roster loading through CTOD's authenticated Supabase client.
- Direct reopening of the exact prepared/in-progress review, including an idempotent reload fallback.
- Versioned finalized-review intelligence migration and a corrective migration preserving `security_invoker` on the promotion-readiness view.
- Shared date-only display handling.
- Compensation, manager summary, and employee comments in finalized review reporting.

### Fixed

- Blank Reviews employee dropdowns caused by stale roster data and session-restoration timing.
- Start/Open Review reloading the page without opening the review workspace.
- Compensation Discussion being hidden with obsolete compensation fields.
- Duplicate coaching saves caused by repeat clicks.
- Blank finalized score, rating, readiness, and succession reporting.
- One-day-early date rendering in Pacific time.
- Duplicate carried goals and Talent Trajectory panels.
- Review History disappearing after workspace rerenders.
- Finalized summaries omitting compensation and commentary.

### Verified

- Two consecutive review cycles for `QA TEST · 990040`.
- Fifteen fresh confirmed answers per cycle.
- Cycle-one coaching resolution remains active at 1 of 2.
- Cycle-two consecutive resolution closes coaching at 2 of 2.
- Exactly one future review is created.
- Finalized result is 3.00 / 60% / Meets Expectations.
- Promotion readiness is Ready in 1 Year.
- Employee 360 shows one Review History panel, one Talent Trajectory panel, one active goal, and the correct date.
- Finalized-answer immutability and RLS-safe reporting remain enforced.

### Retained QA state

- The fake QA employee remains in production.
- Two finalized reviews and one future review remain as acceptance evidence.
- Active coaching count is zero.
- No production record was deleted by this release.

## 1.0.0 — 2026-08-09

- Established the operation-ready GitHub/Vercel/Supabase baseline.
- Implemented the permanent employee identity, review, coaching, career, compensation, history, summary, Master, and talent-intelligence foundations.
- Bound three tailored reasons to every active question and rating band.
