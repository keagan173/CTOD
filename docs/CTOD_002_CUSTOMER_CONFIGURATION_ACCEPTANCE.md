# CTOD 002 Customer Configuration Engine Acceptance

Date: 2026-08-11
Branch: `ctod-002`
Environment: CTOD Sandbox only
Production impact: none

## Built

- Customer-owned company settings with review cadence and configurable terminology/settings payloads.
- Normalized organization hierarchy units for region, area, market, division, department, and group structures.
- Optional hierarchy linkage on locations.
- Owner/admin company-profile update policy.
- Owner/admin RLS boundaries for company settings and organization hierarchy.
- Configuration draft creation using `SECURITY INVOKER`.
- Published-to-draft cloning for configuration options, ratings, goal templates, questions, and question reasons.
- Configuration publishing that retires the previous published configuration without deleting historical records.
- RLS-safe `v_company_configuration_context` view.
- Owner/admin Configuration workspace in the browser for company profile, hierarchy, locations, roles, review questions, and reasons.
- Blank Standard Master five-point CTOD core rating scale.

## Acceptance Results

### Tenant isolation
An authenticated owner of Industry 001 attempted to insert an organization unit into the blank acceptance company without membership. PostgreSQL rejected the write with RLS error `42501`.

Result: PASS.

### Admin write model
A transactional sandbox test temporarily granted owner membership to the blank acceptance company, then successfully:

1. created a protected configuration draft
2. updated the company profile
3. created an organization unit
4. created a job role

The transaction was rolled back after verification.

Result: PASS.

### Draft / publish lifecycle
A second transactional test created a configuration draft, created an `Operations Lead` role, added a leadership review question and a rating-specific reason, then published the draft.

Verified published draft contents:

- 5 platform rating items
- 1 review question
- 1 review reason
- status = `published`

The transaction was rolled back after verification, leaving the blank acceptance tenant clean.

Result: PASS.

### Blank tenant cleanliness after testing
`CTOD 002 Blank Acceptance Co` remains customer-neutral:

- organization units: 0
- locations: 0
- roles: 0
- questions: 0
- reasons: 0
- draft configurations: 0
- CTOD platform rating items: 5

Result: PASS.

### Production isolation
Production was queried after the sandbox migrations. The following 002 objects do not exist in production:

- `industry_templates`
- `company_settings`
- `organization_units`
- `admin_begin_configuration_draft(uuid,text)`

Result: PASS.

## Security Advisor

The new configuration-engine tables have RLS policies and the new public configuration functions are `SECURITY INVOKER`.

The sandbox security advisor continues to report warnings on older pre-002 `SECURITY DEFINER` RPCs and leaked-password protection. Those warnings were not introduced by this configuration-engine release and remain a separate hardening workstream.

`company_provisioning_runs` intentionally has RLS enabled with no customer policy because access is service-role-only.

## Deployment Gate

Do not deploy `ctod-002` against the production database.

The 002 UI inherits production database endpoints from `main`. A separate `agent/ctod-sandbox` branch already contains runtime environment isolation (`ctod-config.js`, environment build files, sandbox guards, and sandbox-specific database routing). Before browser acceptance of 002, reconcile that environment-isolation work into the 002 branch so the 002 preview can only connect to CTOD Sandbox.

## Next Engineering Gate

Reconcile the sandbox runtime-isolation layer into `ctod-002`, deploy a sandbox-only preview, and perform browser acceptance of the Configuration workspace using a sandbox owner account and a blank tenant. After that, configure a fictional non-tire business end-to-end and prove employee/review lifecycle operation under the new tenant.