# CTOD Production Deployment Standard

## Canonical architecture

CTOD uses one production delivery path only:

`GitHub main -> Vercel production -> app.ctodsystem.com`

Backend services remain separate:

- Supabase: database, authentication, authorization, RLS, backend functions
- Resend: transactional invitation/onboarding email
- GoDaddy: DNS registrar

Manual `vercel deploy` releases are not the production release process and must not be used as a fallback. Production changes originate in GitHub and are deployed from the connected `keagan173/CTOD` repository.

## Vercel project configuration

- Project: `ctod`
- Git repository: `keagan173/CTOD`
- Production branch: `main`
- Framework preset: Other
- Root directory: repository root
- Output directory: `public` (declared in `vercel.json`)
- Production hostname during transition: `ctod.vercel.app`
- Canonical hostname when DNS is connected: `app.ctodsystem.com`

## Release policy

1. All production source changes are committed to GitHub.
2. A push/merge to `main` triggers Vercel production deployment through Git integration.
3. The deployment must show GitHub commit metadata, not `vercel deploy`, as its source.
4. A release is not accepted until the live application is smoke-tested.
5. Rollback is performed by promoting/redeploying a known-good Git-backed deployment or reverting the Git commit, never by reconstructing source from a deployed artifact.
6. Production secrets remain in Supabase/Vercel/Resend configuration and are never stored in the repository.

## Foundation smoke test

Every foundation release must validate:

- Owner can sign in.
- Owner sees Reviews, Master, and Access Management.
- Manager does not see Owner-only tabs.
- Owner can create a Location 040 Manager invitation.
- Email arrives through Resend from `CTOD <invites@ctodsystem.com>`.
- Invitation opens on the CTOD application, not a raw Supabase endpoint.
- Recipient creates a password and receives the assigned Location 040 access.
- Manager can open review workflows and coaching moments.
- A finalized review updates Owner Master reporting.
- The two-page summary remains printable/saveable as PDF.

## Scalability rules

- Tenant/company, user role, and location authorization remain data-driven rather than hard-coded per user.
- Employees are deactivated rather than hard-deleted when historical review data exists.
- Backend authorization is enforced by Supabase RLS and functions; hiding UI controls is not treated as security.
- New features should be modularized instead of expanding a single deployment-only file indefinitely.
- Schema changes must be versioned and documented before multi-location rollout.
- GitHub remains the only source of application truth.

## Current milestone

Foundation milestone: establish a repeatable Git-backed Vercel production pipeline, confirm Access Management in production, then execute the true Location 040 invitation acceptance test before adding larger feature modules.
