# Career Decision Persistence Hotfix — 2026-08-15

Root cause: `career_decisions` is uniquely keyed by `(review_id, employee_id)`, while several RPCs used `ON CONFLICT(review_id)`. PostgreSQL rejected those writes, leaving visible review selections unsaved.

Fixed RPCs:
- `save_review_employee_voice` (2-arg and 4-arg overloads)
- `save_review_career_prompts`
- `save_review_promotion_readiness`
- `save_review_specialist_growth`

All now upsert on `(review_id, employee_id)`.

Validation: simulated manager save for Noah Blythe LOC040 review `db5e2c8e-4316-47e5-9c3f-1b92e1fe9506` succeeded inside a rollback transaction after the migration. Review history was not recreated or reset.
