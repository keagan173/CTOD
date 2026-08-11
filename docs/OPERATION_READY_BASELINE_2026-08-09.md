# CTOD Operation-Ready Baseline — 2026-08-09

Historical baseline. Superseded by the [validated production QA release dated 2026-08-11](PRODUCTION_QA_RELEASE_2026-08-11.md).

This document records the production baseline immediately before the first real Location 040 employee rollout.

## Production state

- Test employee/review data was cleared from the CTOD production dataset to prepare for real employee onboarding.
- Employee identity remains based on the permanent six-digit employee number.
- Finalized reviews remain immutable/read-only and are available through Employee Review History with the dated two-page summary.
- Career direction, next role, ultimate role, and promotion readiness are persisted with the finalized review and feed Master talent analytics.
- Compensation captures employee raise request, employee reason/timing, manager timing, and manager comment as structured data.
- Coaching remains timestamped and tied to the employee record, including the two-cycle carry-forward resolution rule.

## Review reason architecture

All active CTOD review questions now have question-specific reason choices across all five rating bands:

1. Exceptional
2. Exceeds Expectations
3. Meets Expectations
4. Needs Improvement
5. Unsatisfactory

Reasons are generated and stored against the question's specific role/category context rather than using one generic reason pool. `external_code` values preserve the relationship between the question code, rating band, and reason index for auditability and future editing.

Examples:

- `OS-02:EXCEPTIONAL:1`
- `AM-02:NEEDS_IMPROVEMENT:2`
- `ORG-002:MEETS:3`

The application filters reasons by rating and question category/role so the manager sees reasons tailored to the question being scored.

## Current review model

Every role uses the same core review structure:

- Organizational competencies
- Role-specific performance questions
- Development goal
- Employee career direction
- Career direction reason
- Next job role
- Ultimate / long-term job role
- Manager promotion readiness
- Compensation discussion
- Coaching items included in review
- Finalization validation
- Read-only finalized review history
- Two-page printable review summary

## Finalization safeguards

CTOD finalization must block when required review answers are incomplete or unconfirmed, active coaching items are unresolved, required career information is missing, or a raise request is structurally incomplete.

For advancement selections, the next job role and ultimate job role must be persisted before finalization. Finalized career data must be returned by `get_review_form` so the Master pipeline and two-page review summary consume the exact same source record.

## Manual rollout acceptance test

The first real Location 040 employee should be used as the final human acceptance test. Confirm this exact path:

1. Add employee with real six-digit employee number.
2. Confirm employee appears immediately in Master and Location 040.
3. Set review date and verify next review defaults six months later.
4. Start review from Reviews or Review Schedule.
5. Complete every rating and confirm the reason dropdown is tailored to that question/rating.
6. Add a coaching moment and verify timestamp/history behavior.
7. Choose development goal.
8. Choose career direction, next role, ultimate role, and manager promotion readiness.
9. Complete compensation discussion.
10. Save draft and reopen to confirm all selections persist.
11. Finalize review.
12. Confirm Master talent pipeline updates.
13. Confirm employee profile shows dated finalized review and score.
14. Open finalized review in read-only mode.
15. Generate the two-page summary and verify score, career direction, next role, ultimate role, readiness, goals, coaching, and compensation data.
16. Confirm no finalized data can be edited.

## Release rule

No additional test employees should remain in production after acceptance testing. Real employees should be loaded using their true six-digit employee numbers only.
