# CTOD Production QA Release — 2026-08-11

Status: PASSED — controlled Location 040 QA lifecycle

## Release identity

| Item | Value |
| --- | --- |
| Production application commit | `4ab3f459f1f54b99c025d7d9f8e55b54d9ed7f45` |
| Production endpoint | https://ctod.vercel.app/ |
| QA manager scope | QA LOC40 |
| QA employee | `QA TEST · 990040` |
| Lifecycle tested | Two consecutive finalized review cycles |
| Repository version after documentation update | 1.0.1 |

## Acceptance results

| Acceptance condition | Result |
| --- | --- |
| Reviews roster loads under the signed-in manager's authorized location | Passed |
| Existing prepared/in-progress review opens without a duplicate | Passed |
| Fifteen role and organizational questions accept tailored reasons and confirmations | Passed in both cycles |
| Draft answers, career fields, goals, coaching dispositions, and compensation persist | Passed |
| Cycle one resolved coaching remains active | Passed — 1 of 2 |
| Cycle two consecutive resolution closes coaching | Passed — 2 of 2 |
| Finalization creates the next review exactly once | Passed |
| Finalized score and rating feed Employee 360 and Master | Passed — 3.00 / 60% / Meets Expectations |
| Promotion readiness feeds succession intelligence | Passed — Ready in 1 Year |
| Date-only values remain on the intended calendar day | Passed — 2/10/2026 |
| Carried development goal displays once | Passed — one active goal |
| Review History and Talent Trajectory survive navigation rerenders | Passed — one panel each |
| Active coaching after cycle two | Passed — zero |
| Future reviews after cycle two | Passed — one |

## Reporting and print evidence

The deployed finalized-review builders include:

- performance ratings, reasons, and manager notes
- career direction, next role, long-term role, and promotion readiness
- deduplicated development goals
- coaching included in the review
- structured compensation discussion
- manager summary and employee comments
- employee and manager acknowledgment/signature areas

The archive summary action created its temporary two-page print frame. The cloud browser's native print handling removed that frame before a visual capture could be retained. The deployed builder, authenticated review data, page structure, and required sections were verified. A physical Print / Save PDF spot check remains part of the first-real-employee rollout.

## Database release and security

The release applied and then committed these production migrations:

1. `supabase/migrations/20260810224051_finalized_review_intelligence.sql`
2. `supabase/migrations/20260810233320_restore_promotion_readiness_security_invoker.sql`

The first migration:

- calculates finalized score and rating from locked answer/rating relationships
- persists overall score, percent, rating label, and promotion readiness
- updates the active succession record from the latest finalized review
- reuses an existing active development goal when the same goal carries forward
- returns the finalized data contract required by Employee 360, Master, archive, and summaries

The corrective migration restores `security_invoker = true` on the promotion-readiness view. Post-migration security checks passed, and finalized answer rows were not rewritten.

## Locked decisions

1. Finalized answer rows remain immutable. Reporting intelligence is calculated from their locked relationships, never by rewriting historical answers.
2. Corrective coaching closes only after two consecutive reviews select Resolved this cycle.
3. Review creation and reopening are idempotent. A retry resumes the same review ID.
4. Date-only database values are rendered as calendar dates, not UTC timestamps.
5. CTOD modules use the application's already-authenticated Supabase client after workspace/session restoration.
6. Carried development goals are reused and deduplicated in reporting instead of creating repeated active goals.
7. Finalized reporting must include performance, career, goals, coaching, compensation, manager summary, and employee comments.
8. Database-contract releases run migration/backfill first, security verification second, and dependent frontend deployment third.
9. GitHub `main` and committed Supabase migrations must match the live production state.
10. Cleanup of test data must target the exact fake identity and must never broaden into deletion of legitimate employee history.

## Retained QA data

No records were deleted during this release. Production intentionally retains the isolated fake QA evidence:

- one fake employee: `QA TEST · 990040`
- two finalized reviews
- one future review
- two closed QA coaching rows
- zero active coaching items
- one active development goal

## Cloud-readiness checkpoint

The validated behavior is portable without redesign:

- business rules live in versioned database functions and data contracts
- authorization is enforced through roles, location access, and RLS
- employee history is keyed to permanent identity rather than a worksheet or browser session
- review lifecycle operations are idempotent and transaction-backed
- reporting consumes persisted canonical records
- the frontend renders and orchestrates the same contracts a future application client can use

This release passes the CTOD architecture test: the logic is already operating as a cloud application rather than depending on workbook-only behavior.

## Controlled next step

1. Decide whether the fake QA evidence should be retained temporarily or removed.
2. If removal is approved, target only `QA TEST · 990040` and its fake dependent records, then verify configuration and legitimate history remain intact.
3. Confirm the resulting clean baseline.
4. Onboard the first real Location 040 employee using the permanent six-digit employee number.
5. Complete one controlled review and physically verify Print / Save PDF before loading the remainder of the location roster.

## Rollback reference

The accepted application release is `4ab3f45`. Rollback must use Git/Vercel deployment history or a normal revert. Do not reconstruct source from deployed browser files.
