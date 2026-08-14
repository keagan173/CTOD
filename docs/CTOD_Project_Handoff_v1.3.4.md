# CTOD Project Handoff v1.3.4

**Final 2026-08-14 commercial-platform checkpoint**

## Locked architecture

CTOD is one commercial multi-tenant SaaS platform for many industries and customers. Production is the permanent Platform Owner control plane plus isolated customer Company Masters. CTOD Development/Sandbox 002 remains the product workshop/staging/security/acceptance environment. Customer configuration releases and CTOD Platform Releases are separate pipelines. Industry templates are versioned starter DNA and never silently overwrite existing customer live configuration.

## Production Owner control plane

- Owner URL: `https://owner.ctodsystem.com`
- DNS/SSL: valid
- Authentication: password + verified TOTP MFA/AAL2
- Owner API: `ctod-owner-api` v11, `verify_jwt=true`
- Private control-plane schema remains unexposed; service-only RPCs enforce Platform Owner authorization
- Commercial Tire remains intact in Production with 55 active locations
- Owner customer-management UI supports invitations/access, locations/roles, customer sandbox, validation, promotion, discard, rollback and release history

## Customer access model

Platform Owner is separate from customer-company membership. Customer first-contact semantics are now **Executive**, not customer `owner`.

- Executive: company-wide visibility and customer access administration
- Viewer: company-wide read-only
- Area Leader: approved-location scope
- Market Leader: approved-location scope
- Manager: approved-location scope

Customers never receive CTOD application/code editing rights.

## Published Production starter templates

- `001` — Industry 001 Reference Template v1.0.1
- `BLANK` — Blank Standard Master v1.0.0
- `LANDSCAPE` — Landscaping v1.0.0
- `RESTAURANT` — Restaurant v1.0.0

## Multi-industry provisioning acceptance

Rollback-safe Production tests passed and left no fictional tenants behind.

### Landscaping proof

- provisioned from LANDSCAPE v1.0.0
- 1 starter location
- 3 starter roles
- 3 landscaping-specific review questions
- first customer administrator = Executive

### Restaurant proof

- provisioned from RESTAURANT v1.0.0
- 1 starter restaurant
- 4 starter roles
- 4 restaurant-specific review questions
- first customer administrator = Executive
- added R02/R03/R04/R05
- verified 5 active restaurants
- organization mode automatically switched to `multi_site`

This proves ordinary industry/customer differences can remain template/configuration driven in the same CTOD codebase and database model.

## Organization growth behavior

Company organization mode is automatic:

- 1 active location -> `single_site`
- more than 1 active location -> `multi_site`

This supports a one-location landscaping customer growing into multiple branches and a restaurant customer growing from one restaurant to a multi-unit group without changing applications.

## Customer account lifecycle

Production now supports `trial`, `active`, `suspended`, and `closed` customer account states.

Central tenant authorization was hardened so:

- trial/active -> customer access allowed
- suspended/closed -> customer access denied
- Platform Owner service access remains available for support/reactivation

Rollback-safe suspension acceptance passed: the test tenant's customer-access helper returned false immediately after suspension.

## New-customer commercial workflow

Backend capability now supports:

Lead closes -> Owner Console -> Create Customer -> choose published Industry Template/version -> company information -> optional Executive email -> provision isolated Company Master -> Executive invitation -> configure locations/roles/questions -> validate -> activate/manage customer.

New-customer provisioning creates Executive access, not a second platform owner.

## Owner API v11

Owner API v11 is live in Production and synchronized to GitHub. It includes the prior Platform Owner controls plus current customer account state returned on customer-management status and Platform Owner account-state update support.

## Frontend queued in GitHub

New Owner Console/customer-management UI commits include:

- guided Create Customer onboarding presentation
- template preview before provisioning
- Executive terminology
- automatic Executive invitation delivery after provisioning
- direct Manage Customer next step
- customer Account & Subscription panel
- plan/trial/support-note controls
- account status controls with confirmation for suspend/close

### Vercel blocker at checkpoint

Vercel Hobby build-rate limiting rejected the newest frontend automatic deployments. This is an external deployment throttle, not a CTOD code/build defect. The currently deployed Owner Console remains online. The queued frontend commits are safely on GitHub `main` and should be deployed/verified after the rate window clears.

## Source-control/database synchronization

Production migrations created during the final session were synchronized into GitHub, including:

- new customer first contact = Executive
- Platform Owner location management
- automatic company site-mode management
- customer account lifecycle enforcement

Owner API v11 runtime was also synchronized to `supabase/functions/ctod-owner-api/index.ts`.

## Exact next-session priorities

1. Verify GitHub `main`, Production Owner API v11 and current Production customer state before writes.
2. Check whether Vercel's build-rate limit has cleared.
3. Deploy/verify the queued Owner Console onboarding and Account & Subscription UI.
4. Build the guided **Industry Builder** so Platform Owner can create industry starter roles, starter location and starter review questions without JSON or SQL.
5. Keep industry/customer differences data-driven; do not fork CTOD.
6. Connect a dedicated customer application domain such as `app.ctodsystem.com` and move customer login/invite links away from the temporary Vercel customer URL.
7. Continue commercial readiness: plan/billing surfaces, system health/backups/audit visibility, reversible real onboarding acceptance and the Platform Owner operating playbook.

## Restart command

`Resume CTOD build from Handoff v1.3.4 commercial-platform checkpoint. Verify GitHub main, Production Owner API v11, and whether the Vercel build-rate limit has cleared. Deploy and validate the queued Owner Console onboarding/account UI, then continue with the guided Industry Builder. Do not redesign the locked multi-tenant architecture.`

**This handoff supersedes all earlier v1.3.4 interim notes for restart purposes.**
