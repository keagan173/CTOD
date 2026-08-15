# CTOD Review Finalization System Contract 1.0

Status: LOCKED
Applies to: Commercial Tire 001 and all future tenants using the standard CTOD review engine.

## Required UI / persistence parity
Every field required by `finalize_review` must be visibly rendered in the review UI, saved before validation, and reload from the database with the same value.

Required canonical fields:
- Career direction
- Why this path
- Next position desired when Advancement
- Long-term position desired when Advancement
- Manager readiness when Advancement
- Specialist growth path when Specialist
- Next-year goal
- Employee Voice: safety priority
- Employee Voice: career feeling
- Employee Voice: money/hours vs flexibility
- Relocation openness
- Compensation reason when raise requested
- Employee requested timing when raise requested
- Manager timing when raise requested
- Required performance answers / confirmations
- Required coaching dispositions

## Canonical ownership
- One Career Direction / Employee Voice renderer only.
- One Compensation renderer only.
- No legacy Development & Career renderer may reintroduce Manager Summary, Employee Comments, duplicate Career Direction, duplicate Employee Voice, duplicate relocation, or hidden required fields.

## Database invariants
- `career_decisions` uniqueness is `(review_id, employee_id)`.
- Career/Voice save functions must update-or-insert using `(review_id, employee_id)`, never `review_id` alone.
- Save Draft and Finalize persist canonical visible fields before final validation.
- Finalization remains blocked if any required data is actually missing from the database.

## Compensation invariant
If `raise_requested = true`, the UI must show and persist:
- raise reason code
- requested timing
- manager timing
Manager Timing must install every time a review is opened, including when `#reviewDetail` is reused and only its contents change.

## Regression acceptance
Before any Sandbox -> main promotion affecting the review engine:
1. Open a queued review and start it.
2. Save and reload all canonical Career/Voice fields.
3. Select Advancement and verify readiness survives reload.
4. Request a raise and verify Manager Timing appears and survives reload.
5. Verify exactly one Career Direction section, one Employee Voice section, and one relocation question.
6. Run finalization validation and confirm the only blockers reported correspond to truly missing visible fields.
7. Finalize a test review and verify history, two-page summary, next review cycle, People Pulse, Master intelligence and Depth Chart update.

## System audit checkpoint 2026-08-15
- All affected Career/Voice RPC conflict keys corrected to `(review_id, employee_id)`.
- Database audit found zero remaining functions using the broken `ON CONFLICT(review_id)` pattern for `career_decisions`.
- Database audit found zero finalized reviews missing required Career/Voice intelligence.
- Database audit found zero finalized raise requests missing required compensation fields.

This contract is part of the locked CTOD release gate and must not be weakened by tenant-specific UI work.
