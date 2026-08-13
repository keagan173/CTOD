# CTOD Technical Specifications Addendum

Version 1.3.0
Date: 2026-08-13
Applies to: CTOD commercial cloud platform architecture

## Environment Separation

CTOD must maintain distinct platform environments:
- Production: commercial system of record and permanent Platform Owner control plane.
- Development/Sandbox (002): platform development, staging, security testing, acceptance and release preparation.

Customer configuration sandboxes are logical tenant-scoped drafts inside the platform and are not substitutes for the platform-wide 002 environment.

## Multi-Tenant Isolation

All customer-owned records must be scoped by company/tenant identity and protected so that users cannot read or mutate another tenant's records.

Tenant isolation must be enforced server-side through database authorization/RLS and privileged service functions. UI filtering alone is never authoritative.

## Configuration vs Code

Industry/customer variation must be stored as versioned configuration wherever possible. Examples include locations, roles, competencies, review questions, answer types, rating scales, reasons, goals, schedules, career paths, workflow requirements and dashboard options.

Forking the application for individual customers is prohibited by default.

## Template Lineage

Each provisioned company must retain lineage to its starting industry template and template version. Template updates must not silently overwrite customer-owned configuration.

## Customer Configuration Lifecycle

Required states/behaviors:
- published/live configuration
- draft/customer sandbox configuration
- exact configuration fingerprint/checksum
- validation result/history
- promote gate requiring passing validation for the current fingerprint
- release history
- discard draft
- rollback to eligible prior published configuration

Promotion must affect only the targeted company.

## Platform Release Lifecycle

CTOD must add a separate platform-release lifecycle for software/schema/application changes:
- development in 002
- automated/manual tests
- security review
- acceptance review
- approved release artifact/version
- deployment to Production
- staged rollout targeting selected tenants or all tenants
- release audit/history
- rollback/repair strategy

Customer configuration releases and platform releases must never be conflated.

## Owner Control Plane

Production Platform Owner capabilities must include:
- customer portfolio
- tenant provisioning
- customer status/plan/support metadata
- industry templates
- tenant configuration sandbox management
- validation/promote/discard/rollback
- platform release management
- access/invitation controls
- audit/release history
- backup/system-health visibility

The Platform Owner role is CTOD-internal and must not be granted through customer-role administration.

## Customer Access Model

Customer roles are tenant-scoped. At minimum the platform must support:
- location/middle management: authorized locations only
- senior/master-viewer leadership: authorized company-wide visibility
- customer executive administrator: authorized company-wide visibility plus invite/access management

Customer roles may configure or operate only within granted product functions. They may not edit application code, platform infrastructure or other tenants.

## Owner Authentication

Commercial Production Platform Owner identities must be real, recoverable identities controlled by CTOD ownership. Production owner/admin accounts require strong authentication and should require MFA before commercial launch.

Synthetic `@ctod.test` identities are test-only.

## Commercial Provisioning Contract

New-customer provisioning must be executable from the Owner Control Plane without engineering changes:
1. Create tenant/company.
2. Select industry template/version.
3. Create initial Company Master.
4. Add/import locations, roles and employees as needed.
5. Configure tenant-specific content.
6. Invite authorized customer executive/admin.
7. Validate configuration.
8. Activate/go live.

## Acceptance Requirement

Before promoting the multi-tenant architecture from 002 to Production, validate at least these tenant shapes from the same platform codebase and data model:
- large multi-location tire/automotive organization
- one-location landscaping company designed to add locations over time
- five-location restaurant group

No tenant may require a separate application fork to satisfy ordinary configuration differences.
