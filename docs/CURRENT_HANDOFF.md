# CTOD Current Project Handoff

Updated: 2026-08-14
Handoff: v1.3.4 commercial-platform checkpoint

## Locked product architecture

CTOD is one commercial multi-tenant SaaS platform for many industries and customers. Do not redesign it into separate applications or codebases per customer.

- Production contains the CTOD Platform Owner control plane plus isolated customer Company Masters.
- `owner.ctodsystem.com` is the Production Platform Owner entry point.
- Platform Owner authentication is password + TOTP MFA/AAL2.
- Customer-specific changes use Customer Sandbox -> Validate -> Promote -> Live, with release history and rollback.
- CTOD-wide software changes remain a separate Platform Release pipeline.
- Industry templates are versioned starter DNA and must never silently overwrite an existing customer's live configuration.

## Production state at checkpoint

- Commercial Tire remains intact as the real Production customer/reference tenant with 55 active locations.
- Production Owner Console login, custom domain, SSL, MFA, customer portfolio and customer-management routing are working.
- Owner API is live at v11.
- Platform Owner customer invitation/access management is live.
- Customer Executive can manage access for that customer's organization but cannot edit CTOD code/platform internals.
- Supported access model includes Executive, Viewer, Area Leader, Market Leader and Manager with location scoping where required.
- Customer configuration sandbox/validation/promotion/discard/rollback services remain active.
- Customer account lifecycle now supports trial, active, suspended and closed states.
- Central customer authorization helpers enforce lifecycle: trial/active allow tenant access; suspended/closed deny tenant access while Platform Owner management remains available.
- Company organization mode automatically tracks active location count: one active location = single_site; more than one = multi_site.

## 001 visual identity is now the Owner Platform standard

Before continuing functional build work in the next session, finish applying the established 001 branding system to the Platform Owner experience.

Source-of-truth branding remains `BRANDING_GUIDE.md` and `public/branding/`.

Locked visual direction:

- official primary mark: Infinity CTOD logo (`ctod-logo-1-primary.svg`)
- primary identity colors: black / dark graphite + CTOD gold
- primary tagline: **BUILDING PEOPLE. DRIVING PERFORMANCE.**
- supporting marks may be used for people/talent, location, and performance sections
- blue may remain as a restrained functional/data accent, not the dominant Owner Platform identity
- customer/company branding must remain configuration-driven and separate from CTOD platform branding

New reusable Owner Platform branding assets are committed:

- `public/branding/ctod-owner-platform-theme.css`
- `public/branding/ctod-owner-platform-branding.js`

Next session must wire this reusable brand layer into `owner.html`, `owner-customer.html`, and future Owner Platform screens before continuing the Industry Builder. Do not invent a new Owner Console theme.

## Multi-industry provisioning acceptance

Rollback-safe Production acceptance tests passed without leaving fictional tenants behind.

### Landscaping

Provisioned from published `LANDSCAPE` v1.0.0 template and verified:

- 1 starter location
- 3 starter roles
- 3 landscaping-specific review questions
- first customer administrator role = Executive

### Restaurant

Provisioned from published `RESTAURANT` v1.0.0 template and verified:

- 1 starter restaurant
- 4 starter roles
- 4 restaurant-specific review questions
- first customer administrator role = Executive
- added R02, R03, R04 and R05
- 5 active restaurant locations
- organization mode automatically became multi_site

All fictional acceptance data was rolled back.

## New-customer commercial workflow

Backend capability now supports:

Lead closes -> Platform Owner -> Create Customer -> choose published Industry Template/version -> enter company information -> optionally identify customer Executive -> provision isolated Company Master -> create Executive invitation -> configure locations/roles/questions -> validate -> activate/manage customer.

New customer first-contact semantics were corrected from misleading customer `owner` terminology to `executive`. The CTOD Platform Owner remains the only platform owner.

## Owner Console work committed but awaiting Vercel deployment

The newest frontend commits add/improve:

- Create Customer onboarding wizard
- industry template preview before provisioning
- Executive terminology
- automatic Executive invitation delivery after provisioning
- direct Manage Customer next step
- customer account status/plan/trial/support-note controls
- explicit suspend/close confirmation
- account lifecycle display on customer-management screen

These frontend changes are in GitHub `main`, but Vercel Hobby build-rate limiting rejected the latest automatic deployments. This is an external deployment throttle, not a CTOD code failure. The currently deployed Owner Console remains online. Recheck/redeploy after the Vercel rate window clears.

## Published Production starter templates

- `001` - Industry 001 Reference Template v1.0.1
- `BLANK` - Blank Standard Master v1.0.0
- `LANDSCAPE` - Landscaping v1.0.0
- `RESTAURANT` - Restaurant v1.0.0

## Immediate next build block

1. Verify Vercel rate limit has cleared.
2. Wire the reusable 001 black/gold/logo brand layer into Owner Console and Owner Customer Management.
3. Deploy and visually verify the branded Owner Platform plus queued onboarding/account UI.
4. Visually verify Create Customer template preview/onboarding workflow.
5. Visually verify customer Account & Subscription controls.
6. Build the guided Industry Builder so Platform Owner can create/edit starter roles, starter location and starter review questions without JSON or SQL.
7. Keep ordinary customer differences data/configuration driven. Do not fork CTOD per industry/customer.
8. Connect a dedicated customer application domain such as `app.ctodsystem.com` and move invitation/customer-login links off the temporary Vercel customer URL.
9. Continue commercial readiness: account/billing surfaces, system health, backups/audit visibility, final reversible onboarding acceptance, and Platform Owner operating workflow.

## Source-control checkpoint

Recent commercial-platform work includes Owner API v11, new-customer Executive semantics, automatic site-mode management, Platform Owner location management, customer lifecycle enforcement, onboarding UI, account-control UI, and reusable 001 Owner Platform branding assets. Production migrations and Edge Function runtime were synchronized back into GitHub during the 2026-08-14 build session.

## Guardrails

- Start the next session from GitHub `main` and this handoff.
- Verify live Production state before writes.
- Never create fictional persistent customer data for testing; use rollback-safe acceptance tests.
- Do not alter Commercial Tire live configuration merely to test a feature.
- Customers never receive CTOD application/code editing rights.
- Platform Owner remains separate from customer-company memberships.
- Preserve tenant isolation and service-only/private control-plane boundaries.
- Do not bypass MFA, validation, release or rollback gates.
- Preserve the established 001 CTOD logo/black/gold identity across Platform Owner screens.

## Exact restart phrase

`Resume CTOD build from Handoff v1.3.4 commercial-platform checkpoint. Verify GitHub main, Production Owner API v11, and whether the Vercel build-rate limit has cleared. First finish wiring the established 001 CTOD logos and black/gold brand system into the Owner Platform and deploy/validate the queued Owner Console UI. Then continue with the guided Industry Builder. Do not redesign the locked multi-tenant architecture.`
