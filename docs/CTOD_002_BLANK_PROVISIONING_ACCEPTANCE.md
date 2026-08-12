# CTOD 002 Blank Provisioning Acceptance

Date: 2026-08-11
Environment: CTOD Sandbox only
Git branch: `ctod-002`
Production impact: none

## Objective

Prove that CTOD can initialize a second customer from a customer-neutral Blank Standard Master without copying the application, seeding customer operational data, or modifying the validated CTOD 001 production baseline.

## Implemented Foundation

The sandbox now includes:

- `industry_templates`
- `industry_template_versions`
- company-to-template references on `companies`
- `company_template_lineage`
- `v_company_template_context` with `security_invoker = true`
- `company_provisioning_runs`
- service-role-only `private.provision_blank_company(...)`

Published templates established:

- `BLANK` — Blank Standard Master
- `001` — Industry 001 Reference Template

The existing Industry 001 company is linked to the 1.0.1 reference template without rewriting operational history.

## Security Rules

- New public tables have RLS enabled.
- Anonymous access is revoked.
- Published template catalog rows are readable by authenticated users.
- Company template lineage is readable only through existing company membership scope.
- Provisioning ledger is not exposed to authenticated customer users.
- Blank-company provisioning is service-role only and is not executable by `anon` or `authenticated`.
- The company/template view uses security-invoker behavior so underlying RLS remains authoritative.

## Blank Customer Acceptance Test

Sandbox acceptance company:

`CTOD 002 Blank Acceptance Co`

Slug:

`ctod-002-blank-acceptance`

Provisioning key:

`ctod-002-blank-acceptance-v1`

The provisioning request was executed twice with the same key. Both calls returned the same company ID:

`ccb0b2d2-5647-49dc-84ae-54a0fcaf85de`

This verifies the current provisioning path is idempotent for retries.

## Resulting Blank State

| Object | Rows |
| --- | ---: |
| Employees | 0 |
| Locations | 0 |
| Roles | 0 |
| Questions | 0 |
| Reviews | 0 |
| Coaching | 0 |
| Goals | 0 |
| Configuration versions | 1 |
| Template lineage rows | 1 |
| Provisioning ledger rows | 1 |

The test therefore proves that a new CTOD customer can exist as a valid tenant with platform configuration identity but no inherited customer operational data.

## Production Isolation Verification

The production Supabase project was checked after the sandbox migrations.

`public.industry_templates` does not exist in production.

`public.company_template_lineage` does not exist in production.

This confirms the CTOD 002 schema work has not been applied to CTOD 001 production.

## Security Advisor Result

Supabase security advisors were run after the DDL changes. No warning referenced the new template, lineage, provisioning, or company-template view objects. Existing warnings concern pre-existing `SECURITY DEFINER` RPC functions and leaked-password protection; those are separate hardening items and were not changed as part of this acceptance gate.

## Acceptance Decision

**PASSED — Blank Standard Master provisioning foundation.**

CTOD 002 can now create an empty second customer in the sandbox from a reusable platform template, retain template lineage, and safely retry provisioning without creating duplicate tenants.

## Next Engineering Gate

Build customer-admin configuration on top of this tenant:

1. organization hierarchy
2. locations
3. job roles
4. review questions
5. reason libraries
6. coaching categories
7. review cadence
8. succession-critical roles
9. terminology and branding

The next acceptance test must configure the blank customer without source-code changes and verify that Industry 001 data remains invisible to the second tenant under authenticated RLS.
