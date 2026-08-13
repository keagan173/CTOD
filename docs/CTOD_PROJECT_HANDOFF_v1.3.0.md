# CTOD Project Handoff

Version 1.3.0
Current build state: 2026-08-13

## Locked Direction

CTOD is being built as a commercial multi-tenant SaaS product for multiple industries.

The architecture is now explicitly separated into:
1. CTOD Production: the commercial platform and permanent Platform Owner control plane.
2. CTOD Development / Sandbox (002): permanent development, staging, testing and acceptance environment for CTOD itself.
3. Customer Live: each tenant's published production configuration inside CTOD Production.
4. Customer Sandbox/Draft: each tenant's isolated configuration-testing lane.
5. Industry Template Library: CTOD-owned versioned starter configurations used to provision new customers.
6. Platform Releases: changes to CTOD itself, promoted from 002 into Production only after validation.

Do not treat 001 and 002 as separate customer products.

## Environment Status

### CTOD 001

Protected current production baseline/reference. Keep stable while the next-generation multi-tenant architecture is proven in 002. No experimental owner-control work should be pushed directly into 001.

### CTOD 002 Sandbox

Active development environment for the future commercial CTOD platform.

Implemented/proven in 002 includes:
- industry template infrastructure
- blank/master template provisioning
- company/template lineage
- provisioning ledger
- tenant-safe database patterns
- Company Master/customer provisioning
- tiered customer access concepts and supporting data structures
- customer-specific configuration drafts/sandboxes
- validation history and configuration fingerprints/checksums
- promote-to-live gate
- customer configuration release history
- discard-draft path
- rollback engine and rollback candidates
- owner-only deployment Edge Function
- Owner Console prototype and customer portfolio/deployment workflow

The Owner Console built in 002 is a prototype of the future Production Owner Console. 002 itself is not the final commercial owner master.

## Production Target

The finished commercial platform should expose a permanent Platform Owner experience in Production, planned as `owner.ctod.app`, with a customer application route such as `app.ctod.app` or the final approved production domain.

The CTOD Platform Owner should be able to:
- see every customer/tenant
- see industry, plan, locations, employees, roles, status and platform/config versions
- provision and suspend/reactivate customers
- manage industry templates
- open any customer's Company Master for support/authorized platform operations
- open a customer-specific sandbox
- stage configuration changes
- validate customer changes
- promote only that customer's configuration
- roll back customer configuration
- manage platform releases
- roll platform changes to selected or all customers
- manage customer executive/access invitations
- monitor release history, audit history, backups and system health

Customers must never receive application/code editing rights.

## Two Release Pipelines

### Platform release pipeline

Build feature in 002 -> automated/manual tests -> security test -> acceptance test -> approve -> deploy to CTOD Production -> staged or broad customer rollout.

Use this for changes to the CTOD product itself.

### Customer configuration pipeline

Customer Live -> Customer Sandbox/Draft -> make configuration changes -> validate exact fingerprint -> promote -> Customer Live -> retain history/rollback.

Use this for customer-specific questions, rating scales, dashboards, competencies, roles, workflows and information collection.

A Commercial Tire-specific change must not alter a landscaping or restaurant tenant unless explicitly included in a platform release.

## Multi-Industry Product Rule

Do not hard-code the core product around Commercial Tire or the tire industry.

Core product entities remain industry-neutral: company, organizational unit/location, role, employee, review program, question, response, competency, goal, development action, succession/talent record, access grant and release/configuration.

Industry-specific behavior is expressed through templates and tenant configuration.

## New-Customer Sales/Provisioning Flow

CTOD Owner -> Create Customer -> choose Industry Template -> create Company Master/Tenant -> configure locations/roles/questions -> invite customer executive/admin -> validate -> go live.

Selling CTOD must not require cloning the application.

## Owner Identity

For long-term operation, the permanent Production Platform Owner account must use a real recoverable owner identity controlled by Keagan and should use MFA before commercial launch. Synthetic `@ctod.test` accounts remain test personas only.

A real owner account may also be used in 002 for realistic testing, but 002 ownership does not make 002 the commercial master.

## Immediate Engineering Priorities

1. Keep 001 protected.
2. Continue platform work in 002 only.
3. Finish and verify Production/Sandbox separation in code and documentation.
4. Harden Owner Console authentication and hosting.
5. Finish platform-owner identity transfer/testing in 002 using a safe supported path.
6. Complete security audit of authenticated SECURITY DEFINER functions and intentional customer-facing RPC permissions.
7. Enable leaked-password protection and plan MFA for Production owner/admin accounts.
8. Build explicit Platform Release model in addition to the existing customer configuration release model.
9. Build industry-template administration in Owner Console.
10. Build customer provisioning UI so a new customer can be created without engineering work.
11. Acceptance-test with at least three fictional tenant shapes: large multi-location tire/automotive, single-location landscaping with growth, and five-location restaurant group.
12. Only after acceptance criteria pass, plan controlled promotion of the multi-tenant platform architecture into CTOD Production.

## Start Here Next Session

Resume in `ctod-002`.

Do not confuse CTOD 002 Sandbox with the commercial Platform Owner master. Treat 002 as the workshop/staging environment and Production as the eventual operating system for the CTOD software business.

First engineering block: formalize Platform Release entities/workflow and finish the Production Owner Console deployment path while preserving the customer-specific Sandbox -> Validate -> Promote -> Rollback engine already built.

Governing architecture document: `docs/CTOD_PLATFORM_ARCHITECTURE_v1.0.0.md`.
