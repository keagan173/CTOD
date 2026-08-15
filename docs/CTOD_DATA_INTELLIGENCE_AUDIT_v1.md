# CTOD Data Intelligence Audit v1

## Purpose
Every meaningful field CTOD collects must have an intentional display, filter, aggregation, ranking, or historical use. Data may not be collected and then disappear into storage.

## Locked visibility model
- Company location accountability map: visible to every active customer user across the entire company, regardless of employee-data access scope.
- Employee-level names, review content, coaching, goals, compensation, Employee Voice, career/readiness, and depth detail: restricted to the viewer's authorized location scope.
- Aggregate intelligence always honors the same employee-data scope as the underlying records.

## Intelligence domains

### 1. Review execution and performance
Source: `reviews`, `review_answers`, `question_definitions`, `rating_scale_items`, `reason_definitions`.
Collected: review status/dates, overall score/percent/rating, safety cap, raise recommendation, role-specific and organization-wide question ratings, primary/additional reasons, manager notes, carry-forward confirmations.
Required intelligence: completion/overdue, average score by role/location/question, highest/lowest scoring roles, rating distribution, repeated development reasons, safety-cap incidence, question-level trends, role comparison, location comparison, time trend.
Filters: one or multiple job roles, location/market/area where authorized, review cycle/date range, question, section, rating, reason, finalized/open.

### 2. Employee Voice
Source: `career_decisions` Employee Voice fields.
Collected: safety priority, feels they have a career, money/hours vs flexibility, relocation openness.
Required intelligence: overall gauges, one-or-multiple-role comparison, role rankings for each signal, location comparison, response counts, strongest/weakest roles, time trend.
Filters: one or multiple roles, authorized location scope, date/review cycle.

### 3. Career and succession
Source: `career_decisions`, `roles`, finalized reviews.
Collected: career direction, path reason, desired next role, long-term role, promotion readiness, next-year goal, specialist growth path, promotion/more-responsibility/schedule/transfer/relocation interests and mobility scope.
Required intelligence: Ready Now bench, 30-90 day bench, one-year bench, role gaps, desired-role demand, specialist pipeline, career-direction distribution, mobility/relocation pool, succession depth.
Filters: current role, one/multiple roles, career direction, next role, readiness, specialist path, location scope.

### 4. Coaching
Source: `coaching_moments`.
Collected: type, category, reason, notes, expected outcome, include-in-review flag, record status, resolution streak, carry-forward status, review cycle/source version.
Required intelligence: recognition/development/corrective mix, category frequency, repeated corrective themes, unresolved carry-forward count, two-cycle resolution progress, coaching frequency by role/location, coaching-to-review outcome correlation.
Filters: one/multiple roles, type, category, active/resolved, date range, location scope.

### 5. Goals and development
Source: `goals`.
Collected: goal text/template/type, status, target date, completion, raise-linked, promotion-linked, carry-forward/source.
Required intelligence: active/completed/overdue, goal type frequency, promotion-linked development, raise-linked commitments, completion rate by role/location, recurring development needs.
Filters: one/multiple roles, status, type, linkage, date range, location scope.

### 6. Compensation discussion
Source: `compensation_decisions`.
Collected: raise requested, basis/reason, employee note, requested timing/date, manager timing/comment, decision status, planned effective date, amount type/value, linked goal.
Required intelligence: request rate by role/location, top raise reasons, timing alignment/gaps, decision distribution, goal-linked raise frequency. Monetary values remain access-scoped and must never appear in company-wide public accountability views.
Filters: one/multiple roles, raise requested, reason, decision, timing, location scope.

### 7. Review summary and acknowledgements
Source: `review_summaries`, `review_print_summary`, `get_review_form`.
Collected: employee comments, manager summary, generated template/version/document, employee/manager acknowledgements/signature dates, signed copy attachment.
Required use: permanent two-page review history, searchable historical record where appropriate, completion/acknowledgement audit. Free-text comments are not used in broad company rankings without an explicit future text-analysis policy.

## Master workspace contract
Master is the primary intelligence surface and must contain:
1. Full company map visible to all users.
2. Access-scoped People Pulse.
3. Multi-role Intelligence Explorer.
4. Career/readiness search.
5. Depth/succession intelligence.
6. Review/coaching/goal/compensation aggregate analytics.
7. Drilldown only when the viewer has employee-level authorization.

## Non-negotiable analytics rules
- Every percentage displays its response/sample count.
- Multi-role selections aggregate numerator/denominator, never average percentages.
- Role rankings show sample size to avoid misleading tiny-sample comparisons.
- Historical data is never deleted when a UI field is retired.
- New collected fields must be added to this audit and assigned a display/filter/history purpose before release.
