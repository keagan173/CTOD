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

The Owner Console and Guided Industry Builder now directly load this brand layer. Persistent Owner Platform navigation connects Owner Console and Industry Builder. Legacy Owner Customer Management receives the same black/gold theme and fallback primary mark; direct script wiring can be completed during its next focused UI refactor.

## Vercel deployment state

The previous Hobby build-rate throttle has cleared.

- branded Owner Console deployment: Production success
- branded Owner Console deployment: Sandbox success
- the queued onboarding/account UI is no longer blocked by the former rate limit
- Vercel routes now support both `/industry-builder` and `/owner-industry-builder`

## Guided Industry Builder

The Platform Owner can now create and version industry starter DNA without writing JSON or SQL.

### New industry workflow

Owner Console -> Industry Builder -> New Industry -> enter identity -> starter location -> starter roles -> starter review questions -> review -> publish/draft.

A new industry and its first template version are created through one atomic database RPC. If version creation fails, the industry shell is rolled back instead of leaving a partial draft.

### Existing industry workflow

Industry Builder -> Load Existing -> load latest starter DNA -> edit starter location/roles/questions -> choose next version -> create new immutable template version -> optionally publish.

Existing published template versions are preserved. Existing customer live configurations are not silently changed.

### Production acceptance

Rollback-safe tests passed:

- forced failure during the second half of new-industry creation left zero orphan template records
- successful template + published version creation was verified inside a forced rollback transaction
- rollback left zero acceptance-test templates behind
- Production template catalog remains only `001`, `BLANK`, `LANDSCAPE`, and `RESTAURANT`

## Owner Console

The Owner Console retains:

- password + TOTP MFA/AAL2 sign-in
- Production KPIs
- Customer Portfolio
- guided Create Customer workflow
- published industry template preview before provisioning
- optional first Executive invitation and delivery
- direct customer setup next step
- Platform Release visibility

Raw template JSON editing was removed from the main Owner Console. Industry creation/versioning now routes through the Guided Industry Builder.

## Customer management

The customer-management screen continues to provide:

- customer Account & Subscription state
- plan/trial/support notes
- suspend/close confirmation
- Customer Sandbox creation
- location and role management
- sandbox review-question management
- validation
- promotion/discard
- rollback
- release history
- access invitations with role/location scoping

## Database/source synchronization

Production migration added and synchronized to GitHub:

- `20260814200641_atomic_industry_builder_bundle.sql`

Owner API v12 source is synchronized at:

- `supabase/functions/ctod-owner-api/index.ts`

The new atomic Industry Builder RPC is executable only by `service_role`; it did not add a new Supabase advisor warning.

The Production security advisor still reports pre-existing legacy SECURITY DEFINER warnings and the existing RLS/no-policy informational notice. These should be handled as a dedicated security-hardening block rather than casually changing established manager/customer RPC behavior during unrelated UI work.

## Published Production starter templates

- `001` - Industry 001 Reference Template v1.0.1
- `BLANK` - Blank Standard Master v1.0.0
- `LANDSCAPE` - Landscaping v1.0.0
- `RESTAURANT` - Restaurant v1.0.0

## Immediate next build block

1. Complete direct 001 branding/navigation wiring on `owner-customer.html` while preserving every existing customer-management control.
2. Run an authenticated AAL2 browser/UI acceptance of Owner Console -> Industry Builder -> load existing template/new version flow when an interactive browser session is available.
3. Complete a reversible end-to-end commercial onboarding acceptance: Create Customer -> select industry template -> provision Company Master -> Executive access -> Customer Sandbox -> validate -> promote/discard, leaving no fictional persistent tenant.
4. Connect a dedicated customer application domain such as `app.ctodsystem.com` and migrate customer login/invitation links off the temporary Vercel customer URL.
5. Continue commercial readiness: plan/billing surfaces, system health, backups/audit visibility and Platform Owner operating playbook.
6. Perform a deliberate security-hardening pass over legacy authenticated SECURITY DEFINER RPCs using current app behavior/acceptance tests so access is not broken accidentally.

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

## Exact restart phrase

`Resume CTOD build from Handoff v1.3.5 Owner Platform + Industry Builder checkpoint. Verify GitHub main, Production Owner API v12, Commercial Tire 55-location Production state, and Vercel deployment status. Continue by directly wiring the locked 001 brand/navigation system into Owner Customer Management without changing its controls, then run reversible commercial onboarding acceptance and continue commercial readiness. Do not redesign the locked multi-tenant architecture.`
