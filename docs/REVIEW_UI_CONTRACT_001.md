# Commercial Tire 001 Review UI Contract

Locked acceptance rules for the active review form:

1. Exactly one Employee Career Direction section may render per review.
2. Exactly one Employee Voice section may render per review.
3. Employee Voice contains Safety Priority, Career Feeling, and Money/Hours vs Flexibility.
4. Exactly one Relocation for Opportunity question may render, inside Compensation Discussion.
5. Relocation remains persisted as Employee Voice / workforce mobility analytics.
6. Manager Summary and Employee Comments are not rendered in the active review form.
7. Legacy Development Goal, legacy Promotion Readiness, legacy Career Direction, and legacy Employee Voice renderers must not appear.
8. Canonical career section contains Career Direction, Why This Path, Next Position, Long-Term Position, Manager Readiness, Specialist Growth Path when applicable, and Next-Year Goal.
9. Existing review history and in-progress answers must never be deleted by UI reconciliation.
10. Sandbox validation and visual QA precede promotion to main/Production.
