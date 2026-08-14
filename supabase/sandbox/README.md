# CTOD Sandbox Database

These files are deliberately outside `supabase/migrations`. They must never be applied to production.

Run them only against the isolated CTOD Sandbox project, in numeric order:

1. `000_bootstrap.sql` once, replacing `__CTOD_SANDBOX_PROJECT_REF__` with the sandbox project ref.
2. `010_reset.sql` whenever fake operational data needs to be cleared.
3. `020_seed.sql` after reset to restore the three synthetic Location 040 employees.
4. `030_verify.sql` for a read-only proof of the resulting state.

The bootstrap refuses any database that already contains Auth users, profiles, or company memberships. Reset preserves sandbox login accounts, memberships, location access, and the one-time bootstrap audit marker, while deleting only fake employees, reviews, coaching, goals, invitations, imports, attachments, and other operational audit data.

Current isolated project ref: `zgwkjyezpgboysiklodj`.

The deployed one-time account bootstrap is permanently closed. Its checked-in source is retained under `functions/bootstrap-ctod-sandbox` as a 410 response so a future deployment cannot accidentally reopen account creation.
