# CTOD Project Handoff

Version 1.3.2
Current build state: 2026-08-13

## Locked Product Architecture
CTOD is one multi-tenant commercial SaaS platform. Production is the eventual commercial system of record and permanent Platform Owner control plane. CTOD 002 Sandbox remains the product development/staging/security/acceptance environment. Customers receive isolated Company Masters/Tenants, not cloned CTOD applications.

## Completed Since v1.3.1
### Platform Release Control
Platform release validation, approval, staged targeting, activation and rollback infrastructure remains installed in CTOD 002. Owner API is now v5. Release `1.1.0` remains a candidate and must not be promoted to Production until all release gates are genuinely satisfied.

### SECURITY DEFINER Audit
The authenticated privileged RPC inventory was reviewed. Three functions that should never be directly callable by ordinary authenticated users had EXECUTE revoked from `authenticated`:
- `claim_initial_owner()`
- `recalculate_coaching_lifecycle(uuid)`
- `set_coaching_review_link_company()`

The remaining authenticated SECURITY DEFINER RPCs are intentional customer-facing operations with internal identity, tenant, company-role and/or location authorization. A registry now exists at `private.security_definer_rpc_reviews`. `operator_service_security_review_status()` compares live privileged RPCs against the reviewed registry. Current result: passed=true, unreviewed_count=0.

Supabase leaked-password protection remains disabled and is still a manual pre-production security item.

### Industry Template Engine
The generic industry-template materializer is implemented:
`private.provision_company_from_template(...)`

A published template version can now materialize a new Company Master with:
- company/tenant identity and template lineage
- initial published configuration version
- optional default location
- starter roles
- starter review questions

Template configuration is JSON-driven. Industry differences are therefore configuration, not application forks.

### Owner Template Administration
Owner-only services implemented:
- `operator_service_create_industry_template(...)`
- `operator_service_create_template_version(...)`

They create draft templates and versioned configurations, optionally publishing a template version for customer provisioning.

### Template-Selected Customer Provisioning
Owner-only `operator_service_provision_customer_v2(...)` is implemented. It provisions a customer from a selected published industry template/version, creates the customer account metadata, records platform core version, optionally creates the customer owner invite, records template lineage and operator audit history, and is idempotent through provisioning keys.

### Owner API
`ctod-owner-deploy` Edge Function is now v5. New actions include:
- security_review_status
- create_industry_template
- create_template_version
- provision_customer_v2
in addition to platform release and customer configuration controls.

### Owner Console Prototype
Standalone Owner Console v1.3.2 was generated for Sandbox testing. It adds:
- Industry Template Library
- Create Draft Template
- Publish Template Version with JSON configuration
- Create Customer from a published template
- existing customer portfolio/configuration deployment controls
- Platform Release controls

The Supabase Edge Function remains unsuitable as the UI host because Chrome renders its HTML source. The standalone HTML file is the temporary Sandbox test client. Permanent hosting, ideally `owner.ctod.app`, remains required before commercial launch.

## Source-Controlled Migrations Added
- `20260814001000_ctod_002_platform_release_tables.sql`
- `20260814001100_ctod_002_platform_release_services.sql`
- `20260814001200_ctod_002_platform_release_rollout.sql`
- `20260814001300_ctod_002_security_definer_review.sql`
- `20260814001400_ctod_002_template_materializer.sql`
- `20260814001500_ctod_002_template_admin_services.sql`
- `20260814001600_ctod_002_template_customer_provisioning.sql`

## Acceptance State
Commercial Tire exists as the large multi-location reference tenant. Sandbox safety controls prevented direct creation of fictional LANDSCAPE and RESTAURANT fixtures through raw SQL during this session. This is acceptable because the stronger acceptance path is now to create those templates and customers through the new authenticated Owner Console workflow itself.

## Next Engineering / Acceptance Block
1. Open Owner Console v1.3.2 in Sandbox.
2. Create and publish a `LANDSCAPE` template with one starter location, landscaping roles and landscaping-specific questions.
3. Provision a fictional one-location landscaping company from that template through Create Customer.
4. Create and publish a `RESTAURANT` template with restaurant roles/questions.
5. Provision a fictional restaurant group, then grow it to five locations using the normal location-management path.
6. Verify customer isolation, template lineage, roles/questions and Company Master counts.
7. Complete positive-path platform rollout testing against fictional tenants only.
8. Enable leaked-password protection in Supabase Sandbox manually and plan MFA for Production.
9. Establish normal web hosting for the Owner Console and connect the intended owner domain.
10. Only after all acceptance/security gates pass, prepare controlled promotion from 002 into CTOD Production.

## Start Here Next Session
Resume on `ctod-002`. Keep CTOD Production/001 protected. Begin with Owner Console v1.3.2 acceptance: build LANDSCAPE and RESTAURANT through the product UI, provision their fictional customer tenants, then verify isolation and template-specific materialization.
