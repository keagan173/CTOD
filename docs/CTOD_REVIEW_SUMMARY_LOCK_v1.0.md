# CTOD Review Summary Lock v1.0

Status: APPROVED / LOCKED
Date: 2026-08-15
Production checkpoint: fdfeb1c7ce9484b9f9c9643ff45b62a1d1f5e987

## Approved behavior

The finalized CTOD review summary design and content policy are approved and must be preserved unless the CTOD platform owner explicitly authorizes a redesign.

### Canonical report pipeline
Finalized review data -> canonical adaptive portrait report -> shared PDF/print artifact.

### Controls
- Download PDF
- Print Portrait Report
- Back to Review

PDF and Print remain separate actions and use the same canonical report pages.

### Summary content policy
- Key Strengths: show only Exceptional performance ratings.
- Development Areas: show only Needs Improvement and Unsatisfactory ratings.
- Exceeds Expectations and Meets Expectations remain preserved in review history, analytics, and source data but are omitted from the concise printed summary.
- Coaching: show total coaching count and count by coaching type/category; do not dump every coaching narrative into the summary.
- Goals, Career Direction, Employee Voice, Compensation, Acknowledgment, and signature lines remain part of the report.
- Full underlying review/coaching history remains preserved in CTOD.

### Presentation
- Report-specific CSS must remain isolated from customer workspace/dashboard classes.
- White readable content surfaces inside the approved CTOD report design.
- Adaptive Letter portrait pagination; reports may use as many pages as necessary.
- No clipped/overlapping text.
- Employee and Manager signature/date lines remain at the end.

### Architecture guardrails
- One canonical finalized-review report owner.
- No legacy combined Print / Save PDF control.
- No duplicate summary generators.
- No DOM MutationObserver/polling repair loops for report generation.
- Do not alter tenant isolation, history, Master Presentation Mode, Employee Voice, readiness, Depth Chart, or intelligence architecture as part of report work.

## Validation status
The platform owner visually approved the current report presentation and summary behavior. Physical printing was not available for final owner validation at the time of this lock. Therefore the report design/content is LOCKED; print-device validation remains a separate QA item and must not trigger a redesign of the approved report.
