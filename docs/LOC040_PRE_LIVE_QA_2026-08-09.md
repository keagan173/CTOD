# CTOD LOC 040 Pre-Live QA

Date: 2026-08-09
Status: READY FOR MANUAL PILOT VALIDATION

## Production reset
All pilot/test employee transactional data was removed before the real LOC 040 rollout:
- employees: 0
- reviews: 0
- review answers: 0
- coaching moments: 0
- goals: 0
- career decisions: 0
- compensation decisions: 0

Configuration, locations, roles, access, branding, and system administration data were preserved.

## Review question library
- 80 active questions total.
- 10 organizational questions apply across roles.
- 14 configured Commercial Tire roles each have exactly 5 role-specific questions.
- A normal role review therefore presents 15 performance questions.

## Question-specific reason engine
Legacy broad review reasons were replaced with reasons explicitly bound to a single question ID.
- 80 active questions.
- 5 rating levels per question: Exceptional, Exceeds Expectations, Meets Expectations, Needs Improvement, Unsatisfactory.
- 3 selectable reasons per rating per question.
- 15 reasons per question.
- 1,200 active question-specific review reasons total.
- 0 question sets missing a rating level or expected reason count.
- 0 orphan question-specific reasons.

The review-form API returns only reasons for questions valid for the employee's role. The UI's existing category filter is now keyed to the unique question code so reasons cannot bleed between questions that happen to share a competency/category name.

## Data integrity hardened
- Six-digit employee number remains the permanent employee identity.
- Finalization requires a career direction.
- Advancement requires both Next Job Role and Ultimate Job Role before finalization.
- Finalized career role names are returned to Master and the two-page summary.
- Compensation captures employee request/reason/timing separately from manager timing/comment.
- Finalized review answers remain immutable in normal operation.
- Historical finalized reviews remain read-only and tied to employee identity.

## Static/database validation passed
- No residual employee/test transactional records.
- Every active role has the expected role-question set.
- Every active question has exactly 15 bound reasons across all 5 ratings.
- No orphan review reasons.
- Master career pipeline reads finalized career decisions.
- Two-page review summary receives finalized career role names through get_review_form.

## Manual acceptance test
The next test should be performed through the real LOC 040 manager UI with one employee using a real six-digit employee number. Validate in this order:
1. Add employee and verify immediate Master appearance.
2. Set review date and verify six-month next-review calculation.
3. Add recognition, development, and corrective coaching examples; verify include-in-review behavior.
4. Start review from Reviews/Review Schedule.
5. For multiple questions across organizational and role sections, change ratings and confirm the reason dropdown changes and remains question-specific.
6. Select Development Goal.
7. Select Career Direction, reason, Next Job Role, Ultimate Job Role, and manager Promotion Readiness.
8. Exercise compensation request and manager timing fields.
9. Save draft, leave review, reopen, and verify persistence.
10. Finalize review.
11. Verify Master talent pipeline/career fields update.
12. Verify finalized review appears in Employee Review History with date, score, role, and location.
13. Open finalized review and confirm read-only behavior.
14. Generate the two-page summary and verify score, career direction, next role, ultimate role, readiness, goals, coaching, and compensation data.
15. Verify the next review cycle exists/schedules correctly and coaching carry-forward behavior remains intact.

The LOC 040 rollout should not be expanded beyond the first real employee until this manual acceptance test passes end-to-end.