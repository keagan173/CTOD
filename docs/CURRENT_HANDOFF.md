# CTOD Current Project Handoff

Updated: 2026-08-14
Handoff: v1.3.5 Owner Platform + Industry Builder checkpoint

## Locked product architecture

CTOD remains one commercial multi-tenant SaaS platform for many industries and customers. Do not redesign it into separate applications or codebases per customer.

- Production contains the CTOD Platform Owner control plane plus isolated customer Company Masters.
- `owner.ctodsystem.com` is the Production Platform Owner entry point.
- Platform Owner authentication is password + TOTP MFA/AAL2.
- Customer-specific changes use Customer Sandbox -> Validate -> Promote -> Live, with release history and rollback.
- CTOD-wide software changes remain a separate Platform Release pipeline.
- Industry templates are immutable/versioned starter DNA and never silently overwrite an existing customer's live configuration.
- Platform Owner remains separate from customer-company membership and customer access roles.

## System-of-record and permanent-history invariant

The CTOD Platform Owner layer is the authoritative platform-level system of record and historical intelligence layer for the product. Customer workspaces are permission-scoped operational views into the same underlying tenant data, not separate disposable copies.

Locked behavior:

- When an authorized customer manager adds an employee, assigns a role/location, completes a review, creates coaching, changes an employee, transfers an employee, or performs another supported tenant action, the resulting record must be stored in the same Production tenant history that the Owner Platform reports from.
- The Platform Owner should not re-enter customer operational data manually just to keep the Owner Platform current.
- Platform changes and customer configuration changes must append new versions/history rather than erase prior state.
- Historical employees, assignments, reviews, coaching, configuration versions, access events, release history, audit events, and prior outcomes must remain queryable after later 001/customer updates.
- Existing customer live data must not be destroyed when CTOD 001 or another template/configuration is upgraded.
- The governing product rule is: **CTOD never replaces the past; it adds the next version on top of the past.**
- Tenant isolation remains mandatory: CTOD Platform Owner may govern/report across the platform, while customer users only see records allowed by their company/location role scope.

## Production state

- Commercial Tire remains intact as the real Production customer/reference tenant with 55 active locations.
- Published Production starter templates remain exactly: `001`, `BLANK`, `LANDSCAPE`, and `RESTAURANT`.
- Production Owner API is `ctod-owner-api` v12, ACTIVE, with `verify_jwt=true` and AAL2 Platform Owner authorization.
- Platform Owner customer invitation/access management remains live.
- Supported customer access model includes Executive, Viewer, Area Leader, Market Leader and Manager with location scoping where required.
- Customer configuration sandbox/validation/promotion/discard/rollback services remain active.
- Customer account lifecycle supports trial, active, suspended and closed states.
- Central customer authorization helpers enforce lifecycle: trial/active allow tenant access; suspended/closed deny tenant access while Platform Owner management remains available.
- Company organization mode automatically tracks active location count: one active location = single_site; more than one = multi_site.

## Location 040 pilot readiness

Commercial Tire Location `040` / Meridian is active and is the controlled real-world 001 pilot location.

Verified Production behavior:

- Manager invitations can be scoped specifically to Location 040.
- Accepted Location 040 manager accounts receive active `manager` location access only for the authorized location.
- Managers, not Platform Owner, are responsible for adding their own employees during normal pilot onboarding.
- `manager_add_employee` validates that the signed-in manager can access the selected location before writing.
- The manager can only select a role belonging to the same company and active role library.
- New employees are written to the Commercial Tire company record and receive an active employment assignment to Location 040 and the selected role.
- Employee creation also creates the employee's initial review record when no open review exists, using the Location 040 review campaign and current published customer configuration.
- Employee creation writes an audit event with actor, employee, location and role information.
- `manager_workspace_employees()` only returns active employees whose current assignment is in a location the signed-in user is authorized to access.
- Production currently has 14 active Commercial Tire roles, 4 Location 040 review campaigns and 1 published Commercial Tire configuration, so the add-employee/review bootstrap prerequisites exist.

Pilot sequence is therefore:

Platform Owner sends Manager invite scoped to 040 -> manager accepts/signs in -> manager adds Location 040 employees and correct roles -> CTOD creates/links initial review records -> manager begins real reviews -> Owner Platform history/reporting reads the resulting Production records automatically.

## 001 Owner Platform visual identity

The established 001 visual system is the locked CTOD Platform Owner identity.

- official primary mark: Infinity CTOD logo (`ctod-logo-1-primary.svg`)
- primary colors: black/dark graphite + CTOD gold
- primary tagline: **BUILDING PEOPLE. DRIVING PERFORMANCE.**
- supporting people/performance marks may be used across Owner Platform sections
- blue remains a restrained functional/data accent, not the dominant identity
- customer/company branding remains configuration-driven and separate from CTOD platform branding

Reusable assets:

- `public/branding/ctod-owner-platform-theme.css`
- `public/branding/ctod-owner-platform-branding.js`

The Owner Console and Guided Industry Builder directly load this brand layer. Persistent Owner Platform navigation connects Owner Console, Industry Builder and Owner Customer Management.

## Vercel deployment state

The previous Hobby build-rate throttle has cleared. Production and Sandbox deployments have been succeeding for the current Owner Platform work.

## Guided Industry Builder

The Platform Owner can create and version industry starter DNA without writing JSON or SQL.

### New industry workflow

Owner Console -> Industry Builder -> New Industry -> enter identity -> starter location -> starter roles -> starter review questions -> review -> publish/draft.

A new industry and its first template version are created through one atomic database RPC. If version creation fails, the industry shell is rolled back instead of leaving a partial draft.

### Existing industry workflow

Industry Builder -> Load Existing -> load latest starter DNA -> edit starter location/roles/questions -> choose next version -> create new immutable template version -> optionally publish.

Existing published template versions are preserved. Existing customer live configurations are not silently changed.

## Owner Console

The Owner Console retains password + TOTP MFA/AAL2 sign-in, Production KPIs, Customer Portfolio, guided Create Customer workflow, industry-template preview, optional first Executive invitation, direct customer setup, Platform Release visibility and Guided Industry Builder routing.

## Customer management

The customer-management screen continues to provide customer Account & Subscription state, plan/trial/support notes, suspend/close confirmation, Customer Sandbox creation, location and role management, sandbox review-question management, validation, promotion/discard, rollback, release history and access invitations with role/location scoping.

## Database/source synchronization

Production migration synchronized to GitHub:

- `20260814200641_atomic_industry_builder_bundle.sql`

Owner API v12 source is synchronized at:

- `supabase/functions/ctod-owner-api/index.ts`

The new atomic Industry Builder RPC is executable only by `service_role`; it did not add a new Supabase advisor warning. Pre-existing legacy SECURITY DEFINER warnings remain scheduled for a deliberate security-hardening pass rather than ad hoc changes during pilot rollout.

## Published Production starter templates

- `001` - Industry 001 Reference Template v1.0.1
- `BLANK` - Blank Standard Master v1.0.0
- `LANDSCAPE` - Landscaping v1.0.0
- `RESTAURANT` - Restaurant v1.0.0

## Immediate next build block

1. Finish visual/UI verification of direct 001 branding/navigation on `owner-customer.html` while preserving every customer-management control.
2. Run the first controlled real Location 040 pilot: Manager invite -> manager employee entry -> initial reviews -> review/coaching/history validation.
3. Verify the Owner Platform automatically reflects Location 040 employee/review/audit history without manual re-entry.
4. Complete reversible commercial onboarding acceptance for additional tenants as needed without leaving fictional persistent data.
5. Connect a dedicated customer application domain such as `app.ctodsystem.com` and migrate customer login/invitation links off the temporary Vercel customer URL.
6. Continue commercial readiness: plan/billing surfaces, system health, backups/audit visibility and Platform Owner operating playbook.
7. Perform a deliberate security-hardening pass over legacy authenticated SECURITY DEFINER RPCs using current app behavior/acceptance tests so access is not broken accidentally.

## Guardrails

- Start future sessions from GitHub `main` and this handoff.
- Verify live Production state before writes.
- Never create fictional persistent customer data for testing; use rollback-safe acceptance tests.
- Do not alter Commercial Tire live configuration merely to test a feature.
- Customers never receive CTOD application/code editing rights.
- Platform Owner remains separate from customer-company memberships.
- Preserve tenant isolation and service-only/private control-plane boundaries.
- Do not bypass MFA, validation, release or rollback gates.
- Preserve the established 001 CTOD logo/black/gold identity across Platform Owner screens.
- Ordinary industry/customer differences remain data/configuration driven. Do not fork CTOD.
- Preserve all historical records across future 001/customer upgrades; never implement destructive overwrite as an update mechanism.

## Exact restart phrase

`Resume CTOD build from Handoff v1.3.5 Owner Platform + Industry Builder checkpoint. Preserve the locked system-of-record rule that CTOD never replaces the past; it adds the next version on top of the past. Continue the controlled Commercial Tire Location 040 pilot, verifying manager-added employees/reviews flow automatically into Owner Platform history without destructive overwrite. Do not redesign the locked multi-tenant architecture.`
