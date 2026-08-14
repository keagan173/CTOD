# CTOD Project Handoff v1.3.4

**Current build state: 2026-08-14**

## Locked architecture

CTOD is one commercial multi-tenant SaaS platform for many industries. CTOD Production is the commercial system of record and permanent Platform Owner control plane. CTOD Development/Sandbox 002 remains the product workshop/staging/security/acceptance environment. Each customer has isolated live configuration plus an isolated customer sandbox/draft. Industry templates provide versioned starter DNA. Platform releases and customer configuration releases remain separate pipelines.

## Production Owner control plane

- Owner URL: `https://owner.ctodsystem.com`
- DNS and SSL: valid
- Authentication: password + verified TOTP MFA
- Owner API: `ctod-owner-api` v9, `verify_jwt=true`, AAL2 required
- Private control-plane schema remains unexposed; service-only owner RPCs perform internal authorization
- Commercial Tire appears in Customer Portfolio
- Current Production portfolio: 1 customer, 1 active customer, 55 active locations

## Commercial Tire state

- Slug: `commercial-tire`
- Live configuration: `CTOD-CLOUD-1.0.0`
- Schema version: `1.5`
- No active customer sandbox draft at checkpoint
- Existing 55-location structure, roles, ratings and questions remain intact

## Industry templates

Published Production templates:

- `001` — Industry 001 Reference Template — v1.0.1
- `BLANK` — Blank Standard Master — v1.0.0
- `LANDSCAPE` — Landscaping — v1.0.0
- `RESTAURANT` — Restaurant — v1.0.0

Template changes must never silently overwrite an existing customer's live configuration.

## Platform releases

- CTOD 1.0.1: protected Production baseline
- CTOD 1.1.0: available; latest validation records automated tests, security review and acceptance tests as passed
- `operator_service_platform_releases` security boundary corrected so the service-only Owner path can read hidden release data without exposing private tables

## Customer access model

Platform Owner can manage customer access without becoming a customer-company member.

Supported customer roles:

- Executive: company-wide visibility; may manage that company's invitations/access
- Viewer: company-wide read-only visibility
- Area Leader: location scoped
- Market Leader: location scoped
- Manager: location scoped

Manager/Market/Area roles require one or more approved active locations. Platform Owner access invitation RPCs are service-role-only. Customer-side Owner/Admin/Executive users may manage invitations only for their own company. No customer receives CTOD code/platform editing rights.

## Invitation delivery

- `ctod-send-customer-invite` v2 requires JWT + AAL2 + Platform Owner authorization
- Existing recipient: secure magic-link flow
- New recipient: Supabase invitation flow
- Acceptance page: `/invite?token=...`
- Current customer-app host remains `ctod.vercel.app` until dedicated customer domain is connected
- Rollback-safe Production acceptance for create/list/revoke location-scoped Manager invitation passed
- Fake test invitation persisted: none
- Pending real invitations at checkpoint: 0

## Owner customer-management UI

The deployed customer-management screen now contains configuration safety, customer structure, customer sandbox/question management, validation/deployment, real validation history, real configuration release history, access and invitations, role/location scoping, create/send, resend and revoke invitation actions.

Vercel checks for Production and Sandbox passed on the owner-customer UI deployment.

## Key commits

- `55b24ad924ef2d1879cf3a1fc9b81b2f4c714062` — platform release RPC security boundary fix
- `814106150a81c2beae2b9fe727f1245f85dd3c3c` — hardened customer invitation sender v2
- `680f3f16f0e4154cc39491c4785356739465f640` — Platform Owner customer invitation services
- `52408ca3d96366e55ac9df43fa0fd23b4ac36068` — Owner API v9 customer access management
- `ea10e04167c1d008f7d7c3af48da76acd1d411b7` — customer Executive access administration
- `43a0e5d1e23d9216b4b052bea5337f8192e9cc25` — Owner customer validation/release history
- `685ba28053b3b0feaebf131a2b53afade27a0b60` — Owner customer-management UI access/history update

## Next build priorities

1. Visually verify repaired Platform Releases and Industry Template panels in Production Owner Console.
2. Visually verify Commercial Tire's new Access & Invitations plus validation/release-history sections.
3. Do not send a real invitation until a real intended recipient is selected.
4. Connect a dedicated customer application domain such as `app.ctodsystem.com`, then migrate customer login/invite links away from `ctod.vercel.app`.
5. Complete a reversible end-to-end commercial onboarding acceptance: Create Customer -> choose template -> provision Company Master -> invite Executive -> confirm tenant access -> customer sandbox -> validate -> promote/discard.
6. Add plan/billing/account-health/system-health surfaces to the Platform Owner Console.
7. Finalize the Platform Owner operating workflow for selling, provisioning, supporting and updating customers without cloning CTOD.

**This handoff supersedes CTOD Project Handoff v1.3.3.**
