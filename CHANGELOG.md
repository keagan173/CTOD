# Changelog

This changelog records accepted CTOD production and repository releases. GitHub `main` remains the application source of truth, and versioned Supabase migrations remain the database source of truth.

## 1.3.6 checkpoint — 2026-08-14

### Added

- Required career-readiness model for Advancement: Ready Now, 30-90 Days, Within 1 Year, Not Yet Ready.
- Specialist/technical growth-track selections for non-management career paths.
- Employee Voice questions for safety priority, career confidence, work preference, and relocation openness.
- Next-year development-goal dropdown and removal of the active five-year-position question while preserving historical fields.
- Manager password-recovery UI.
- Nine additional Commercial Tire 001 roles: Market Manager Levels 1-3, AP Specialist, IT Administrator, Administrative Assistant, Director of Sales, Regional Sales Manager, Human Resources.
- Five role-specific review questions per newly added role plus standard rating/reason structures.
- Shared Master direction with company-wide location accountability context and access-scoped employee intelligence.
- Modern People Pulse gauges/charts with job-role analysis.
- Searchable career intelligence direction for Career Direction, Next Position, Readiness, and Job Role.
- Depth Chart direction replacing generic Succession labeling.

### Changed

- Employee review scheduling now follows the manager-entered review date and calculates the next cycle six months later.
- Development Goal / Raise Conditions moved into the compensation discussion flow.
- Manager Summary and Employee Comments moved to the end of the review.
- Career Direction panel styling aligned with the dark CTOD customer workspace.
- Work-preference response is now a hard choice between money/hours and flexibility; `A balance of both` was removed.
- Customer brand bar safe-area expanded to prevent the primary CTOD/CTC mark from clipping.
- People Pulse white metric cards replaced with dark visual gauges and charts.

### Fixed

- Duplicate Career Direction panels caused by repeated MutationObserver installation.
- Duplicate Location Command Centers.
- Advancement readiness control disappearing from the review.
- Blank native dropdown rendering in the career module.
- Employee-specific review dates being ignored by the queue in favor of the generic campaign due date.

### Architecture / guardrails

- CTOD remains one multi-tenant SaaS codebase with data/config-driven customer variation.
- Customer workspaces remain operational views over the same Production tenant history used for Owner/leadership intelligence.
- Company-wide location accountability may be visible across a customer organization, but unauthorized employee names/reviews/detail remain protected by access scope.
- Historical records remain append-only/version-preserving across upgrades.

### Deployment

- Vercel upgraded to Pro.
- Production and Sandbox deployments were green at code checkpoint `884729777f9d69cec8d6698ff1728e5d1df822a5`.
- Handoff advanced to `v1.3.6 Commercial Tire 001 Talent Intelligence checkpoint`.

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
