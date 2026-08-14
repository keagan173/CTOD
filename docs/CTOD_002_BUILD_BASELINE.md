# CTOD 002 Build Baseline

Started: 2026-08-11
Branch: `ctod-002`
Source baseline: `c320fbd1eb081534bc90372401503a27dac83d2b` (repository version 1.0.1)

## Isolation Rule

CTOD 002 is a development branch created from the validated CTOD 001 production baseline. Work in this branch must not alter GitHub `main`, the production Vercel deployment, or the production Supabase database unless a later release is explicitly approved and promoted.

`main` remains the locked CTOD 001 / production source of truth while 002 is under development.

## Product Goal

Turn the validated CTOD reference implementation into a reusable, sellable platform that can be initialized for another company or industry without redesigning the CTOD core.

The platform must remain useful to organizations that need a structured, accountable way to manage, develop, evaluate, promote, transfer, and retain employees while giving senior leaders reliable talent intelligence and giving managers practical development tools.

## Non-Negotiable Architecture

CTOD Core is shared and must not be copied per customer or industry.

Customer-specific behavior belongs in configuration and data:

- companies
- industries / templates
- locations and organization hierarchy
- employees and assignments
- job roles
- review questions
- reason libraries
- coaching categories
- succession-critical roles
- review cadence
- scoring / weighting configuration
- terminology
- branding
- access rules

Every configurable item used historically must be versioned or deactivated rather than destructively rewritten.

## Blank CTOD Standard

A new customer must eventually be creatable from a Blank Standard Master with:

- zero customer employees
- zero customer locations
- zero customer-specific roles
- zero customer-specific review questions
- zero customer coaching/history data

while immediately retaining the CTOD platform modules:

- Employees / People
- Employee 360
- Reviews
- Review Schedule
- Coaching
- Goals and development
- Locations administration
- Job Roles administration
- Review Question administration
- Succession / Depth
- Master dashboards
- Access Management
- Talent intelligence

## CTOD 002 Build Sequence

### Phase 1 — Tenant and Configuration Foundation

1. Introduce explicit industry-template and company tenancy concepts.
2. Define a Blank Standard Master template.
3. Preserve Industry 001 data as the reference implementation without hard-coding Commercial Tire into CTOD Core.
4. Establish configuration ownership and versioning rules.
5. Define RLS boundaries so a company can never read or modify another company's records.

### Phase 2 — Administrative Configuration

Build admin-managed configuration for:

- company profile and branding
- organization hierarchy
- locations
- job roles
- review questions
- reason libraries
- coaching categories
- review cadence
- succession-critical roles
- terminology

All additions, removals, and changes must be data-driven and usable without source-code edits.

### Phase 3 — Blank Customer Provisioning

Create a repeatable workflow that can initialize a new customer from Blank Standard Master, then allow an administrator to build the organization through configuration.

Provisioning must be idempotent and must never duplicate seeded platform configuration when retried.

### Phase 4 — Commercialization / Operator Controls

Create the controls required to sell and operate CTOD as a product:

- customer lifecycle state
- environment / tenant identification
- platform-admin visibility
- customer-admin permissions
- safe customer suspension / reactivation
- audit trail
- release compatibility
- backup / export expectations
- support diagnostics

### Phase 5 — Acceptance

A new empty test company must be provisioned without modifying Industry 001. The test company must then be able to add its own hierarchy, locations, roles, questions, employees, reviews, coaching, and succession configuration while remaining fully isolated from Industry 001.

## Release Guardrails

- Do not deploy 002 changes to production from this branch.
- Do not apply 002 database migrations to production during development.
- Do not delete or rewrite validated CTOD 001 history.
- Do not fork the application by industry.
- Do not hard-code customer names, locations, roles, questions, or hierarchy into platform logic.
- Database-contract changes must be versioned migrations.
- Finalized reviews remain immutable.
- Permanent employee history remains attached to permanent employee identity.
- Existing two-cycle coaching resolution behavior remains unchanged unless an explicit product requirement changes it.

## First Engineering Gate

Before any 002 tenant migration is written, inventory the current production schema and classify every table/view/function into one of four scopes:

1. Platform-global
2. Industry-template
3. Company-tenant
4. Historical / immutable

The first migration must be designed from that inventory so tenancy is added without breaking the validated 1.0.1 review lifecycle.

## Definition of 002 Success

CTOD 002 succeeds when a second company can be created from a clean standard configuration, operated independently through the same CTOD application, and upgraded through the same CTOD Core without copying the repository or redesigning the system.
