# CTOD Project Handoff

Version 1.3.3
Current build state: 2026-08-13

## Locked Product Architecture

CTOD is one commercial multi-tenant SaaS platform for many industries. It is not a separate application or codebase per customer.

The permanent architecture is:

1. **CTOD Production**: commercial system of record, permanent Platform Owner control plane, customer tenants, platform releases, customer live configurations, customer configuration sandboxes, billing/plan metadata, health, audit and support controls.
2. **CTOD Development / Sandbox (002)**: permanent development, staging, security-testing and acceptance environment for the CTOD product itself. It is the workshop, not the commercial master.
3. **Customer Live**: each tenant's published configuration inside CTOD Production.
4. **Customer Sandbox / Draft**: each tenant's isolated configuration test lane.
5. **Industry Template Library**: CTOD-owned versioned starter configurations used to provision new customers.
6. **Platform Release Pipeline**: product/software/schema/application changes move from 002 through validation and approval into Production, then roll out to pilot, selected, or all customers.

CTOD 001 remains the protected current Production baseline/reference until the new multi-tenant platform proven in 002 passes release criteria.

## Confirmed Commercial Model

The product must match a standard multi-tenant SaaS operating model:

- **Main Dashboard** -> CTOD Platform Owner Console. Keagan can see customers, users/access, plan/billing metadata, versions, release state, backup/system health, support state and audit history.
- **Client Portal / Company Master** -> each customer sees only their tenant data, branding, authorized locations and tools.
- **Central Core** -> one CTOD codebase and shared product engine controls product logic and updates.
- **Tenant Isolation** -> company/tenant ownership and server-side database authorization prevent cross-customer access.
- **Shared Services** -> customers use the same CTOD cloud platform while remaining logically isolated.
- **Platform Staging** -> all CTOD-wide changes are built/tested in 002 before Production.
- **Customer Sandboxes** -> customer-specific configuration changes are staged and validated before promotion to that customer's live configuration.
- **Dedicated enterprise UAT** -> optional future enterprise-tier capability only when commercially justified; not the default architecture.

## Two Release Pipelines Must Remain Separate

### A. Platform Release

Use when CTOD itself changes.

Build in 002 -> automated tests -> security review -> acceptance tests -> approve release -> Production -> pilot customers -> selected customers -> all customers -> monitor / rollback.

Examples: new succession dashboard, reporting engine, permissions, review logic, new modules.

### B. Customer Configuration Release

Use when one customer's setup changes.

Customer Live -> Customer Sandbox/Draft -> configure -> validate exact configuration fingerprint -> promote -> Customer Live -> retain release history / rollback.

Examples: customer-specific questions, rating scales, roles, competencies, workflows, information collection or dashboard configuration.

A customer-specific change must never silently alter another tenant.

## Current 002 Build State

Implemented or substantially built in CTOD 002:

- multi-industry template infrastructure
- blank/master template provisioning
- company-to-template lineage
- customer provisioning ledger
- tenant-safe database patterns and Company Master model
- tiered customer access concepts and supporting structures
- customer-specific configuration drafts/sandboxes
- validation history and configuration fingerprints/checksums
- promote-to-live gate
- customer configuration release history
- discard-draft workflow
- customer configuration rollback engine
- Platform Owner identity separated from customer roles
- owner-only deployment API / Edge Function
- Owner Console prototype
- customer portfolio visibility
- Platform Release registry with candidate and available states
- customer core-version, target-version, previous-version and rollback tracking
- Platform Release validation records
- staged rollout targeting infrastructure
- release API actions for validate / approve / schedule / activate / rollback
- Owner Console prototype sections for Platform Releases
- generic Industry Template administration foundation
- template-version creation foundation
- template-driven customer provisioning foundation
- real CTOD Sandbox owner account attached to `keaganelsberry@gmail.com`

## Current Release State

- Production baseline `1.0.1`: available/current baseline.
- Sandbox platform candidate `1.1.0`: candidate.
- Automated and acceptance checks were recorded as passing for the current candidate, but the security review remains failing due to unresolved authenticated `SECURITY DEFINER` warnings. The release must remain blocked until that security work is completed.
- Leaked-password protection remains a pre-production security item.

Do not falsify or bypass release gates merely to complete an acceptance test.

## Owner Console Direction

The Owner Console built in 002 is a prototype of the future Production Owner Console. The final commercial Owner Console belongs in Production, planned at `owner.ctod.app` or the final approved owner domain.

The Owner Console must ultimately allow Keagan to perform routine commercial operations without engineering assistance:

- view all customers/tenants
- create a customer
- choose an industry template/version
- provision an isolated Company Master
- manage plan/trial/account state
- assign or invite a customer executive administrator
- inspect locations, roles, employees and configuration versions
- manage industry templates and versions
- create/open a customer sandbox
- stage customer-specific configuration changes
- validate/promote/discard/rollback customer configuration
- create/inspect Platform Releases
- see automated/security/acceptance release gates
- approve a platform release
- target pilot, selected, or all customers
- activate and roll back platform versions
- view system health, backups, release history and audit history

Customers never receive application/code editing rights.

## Next Session: Primary Objective

**Turn the architecture into an operable new-customer sales/provisioning workflow and complete the three-industry acceptance proof.**

Do not spend the next session re-deciding the platform architecture. It is locked unless a concrete engineering defect requires revision.

### Build Block 1: Finish Owner Console Commercial Workflow

Complete and verify the Owner Console workflow:

Owner -> Create Customer -> choose Industry Template -> choose template version -> enter company information -> provision isolated Company Master -> invite/assign customer executive -> validate initial configuration -> activate/go live.

The owner should not need SQL or engineering work to create an ordinary new customer.

### Build Block 2: Finish Industry Template Administration

Create and verify at least these reusable starter templates:

- General / Blank
- Tire / Automotive
- Landscaping
- Restaurant

Templates should define starter roles, questions/competencies, rating/configuration defaults and optional starter organizational structure without hard-coding the CTOD core to one industry.

Template versions are immutable starter DNA. Existing customer configuration must not be silently overwritten when a template is updated.

### Build Block 3: Three-Industry Acceptance Set

From the same CTOD codebase and database model, provision and test:

1. **Commercial Tire / Tire-Automotive**: large multi-location shape, company-wide and location-scoped access.
2. **Fictional Landscaping Company**: one location initially, with the ability to add future locations as the company grows.
3. **Fictional Restaurant Group**: five restaurant locations, location managers plus company-wide senior/executive visibility.

Acceptance requirement: ordinary differences in questions, roles, locations, competencies and data collection must be handled by tenant configuration/templates, not application forks.

### Build Block 4: Security Hardening Before Platform Approval

Audit each authenticated `SECURITY DEFINER` RPC and classify it as:

- intentionally customer-callable with explicit internal authorization
- converted to `SECURITY INVOKER`
- moved behind an owner/service-only boundary
- execution revoked from roles that do not require it

Run Supabase security advisors after fixes. Enable leaked-password protection and plan MFA for Production Platform Owner and customer executive administrators before commercial launch.

The `1.1.0` candidate must remain blocked until the security gate genuinely passes.

### Build Block 5: Production Readiness Plan

After the three-industry acceptance set and security gate pass:

- create a controlled Platform Release candidate
- verify rollback strategy
- define Production migration/deployment sequence
- establish proper hosting for the Owner Console and customer application
- connect the final owner domain (`owner.ctod.app` planned)
- migrate/establish the real Production Platform Owner identity with MFA
- pilot the release before broad rollout

Do not merge/deploy experimental 002 work directly into 001 Production without this release process.

## Commercial Sales Flow Target

The target sales operation is:

Lead closes -> Owner Console -> Create Customer -> choose template -> configure tenant -> invite customer executive -> validate -> go live -> manage changes through customer sandbox -> manage CTOD-wide updates through Platform Releases.

Selling customer #147 or #500 must not mean cloning CTOD or starting a new software project.

## Start Here Next Session

1. Resume on `ctod-002` only.
2. Verify the latest Owner Console/API/database state before writes.
3. Finish Owner Console Industry Template + Create Customer workflow end to end.
4. Create/publish Landscaping and Restaurant starter templates.
5. Provision fictional Landscaping and five-location Restaurant tenants from those templates.
6. Validate tenant isolation, access scopes and independent customer configuration behavior alongside Commercial Tire.
7. Then address the `SECURITY DEFINER` audit until Platform Release `1.1.0` can truthfully pass its security gate.
8. Keep CTOD 001 Production protected throughout.

This document supersedes Handoff v1.3.2 for the next working session.