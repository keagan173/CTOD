# CTOD 002 Schema Scope Inventory

Date: 2026-08-11
Environment inspected: CTOD Sandbox Supabase
Purpose: first engineering gate for reusable multi-company CTOD tenancy

## Finding

The current canonical schema is already substantially company-scoped. Core operational tables carry `company_id`, and reviews already pin `config_version_id`. CTOD 002 therefore does not need a destructive tenancy rewrite. The safer path is to complete and formalize the existing company boundary, then introduce industry-template inheritance above it.

## Scope Classification

### Platform-global

Platform behavior, authentication infrastructure, audit standards, shared application code, and future template catalog metadata belong at platform scope.

Supabase `auth.*` remains platform authentication infrastructure and is not customer-owned configuration.

Candidate platform-global metadata to add in 002:

- industry_templates
- industry_template_versions
- platform_feature_definitions
- provisioning_runs

### Company-tenant

The following current tables are already explicitly company-scoped or operationally company-owned:

- companies
- company_memberships
- locations
- employees
- employment_assignments
- roles
- configuration_versions
- configuration_options
- question_definitions
- reason_definitions
- rating_scale_items
- raise_reason_definitions
- goal_templates
- review_campaigns
- reviews
- review_answers
- review_summaries
- coaching_moments
- coaching_review_links
- goals
- succession_records
- career_decisions
- compensation_decisions
- attachments
- import_batches
- access_invites
- access_invite_locations
- manager_invitations
- user_location_access
- audit_events

Most critical operational records already include `company_id`, including employees, assignments, locations, roles, questions, reasons, reviews, answers, coaching, goals, and succession.

### Industry-template

Industry templates do not yet exist as first-class relational entities. The current `companies.industry_code` text field indicates the intended concept but does not provide a versioned template relationship.

002 should add template entities rather than place industry-owned rows directly into operational company tables.

Initial template-owned configuration should support:

- terminology defaults
- default role definitions
- default question definitions
- default reason libraries
- default rating scale
- default coaching categories
- default review cadence
- succession-critical role definitions
- optional scoring / weighting rules

A company should receive a copied/version-pinned configuration release from a template. Later edits to a published industry template must not mutate historical company reviews.

### Historical / immutable

These records require special historical protection:

- finalized reviews
- finalized review answers
- review summaries / finalized reporting contracts
- career decisions captured for a review
- compensation decisions captured for a review
- review/coaching disposition links
- assignment history with closed effective periods
- audit events

Historical records must preserve the configuration IDs used at the time of the transaction.

## Existing Architecture We Must Preserve

### Company boundary already present

Key current tables contain `company_id NOT NULL`:

- employees
- employment_assignments
- locations
- roles
- configuration_versions
- configuration_options
- question_definitions
- reason_definitions
- review_campaigns
- reviews
- review_answers
- coaching_moments
- goals
- succession_records

This is the correct base for CTOD 002.

### Configuration version pinning already present

`reviews.config_version_id` is required.

`question_definitions.config_version_id`, `reason_definitions.config_version_id`, and `configuration_options.config_version_id` are also required.

This supports historical integrity and should be extended, not replaced.

### Company identity already carries industry intent

`companies.industry_code` already exists.

002 should migrate this from an unvalidated text concept into a proper template/version relationship while preserving backward compatibility during the transition.

## First 002 Database Design

The first 002 migration should be additive and sandbox-only during development.

Recommended new entities:

1. `industry_templates`
   - permanent template identity
   - stable industry/template code
   - display name
   - status
   - default terminology / metadata

2. `industry_template_versions`
   - immutable/publishable version identity
   - template id
   - version label
   - lifecycle status: draft / published / retired
   - compatibility metadata
   - checksum

3. template configuration tables or a normalized template configuration contract for:
   - roles
   - questions
   - reasons
   - rating scale
   - coaching categories
   - cadence
   - succession rules

4. company template linkage
   - `companies.industry_template_id`
   - `companies.source_template_version_id`
   - preserve `industry_code` during migration for compatibility

5. provisioning run ledger
   - idempotency key
   - company id
   - source template version
   - status
   - started/completed timestamps
   - error/result metadata

## Blank Standard Master

Create a CTOD-owned published template representing Blank Standard Master.

It should contain platform-safe defaults only and no customer operational records.

A company provisioned from Blank Standard Master starts with zero:

- employees
- locations
- company-specific roles
- company-specific review questions
- coaching/history records

while still having a valid configuration version and access to every CTOD Core module.

## Migration Safety Rule

Do not retrofit template ownership directly onto finalized historical records.

Instead:

- retain their current company/configuration references
- add template lineage to future company configuration releases
- use additive nullable compatibility columns first where needed
- backfill only deterministic configuration lineage
- never rewrite finalized answers to satisfy a new template model

## Next Engineering Action

Build the first additive sandbox migration for:

- `industry_templates`
- `industry_template_versions`
- company template lineage
- provisioning-run idempotency ledger

Then validate RLS and confirm that the existing 1.0.1 review lifecycle still runs unchanged for the reference company.
