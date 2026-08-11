# Changelog

This changelog records accepted CTOD production and repository releases. GitHub `main` remains the application source of truth, and versioned Supabase migrations remain the database source of truth.

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
