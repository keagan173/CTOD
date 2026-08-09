# CTOD

Commercial Team Organization Development

## Purpose

CTOD is the company-wide organizational development system for manager reviews, coaching moments, employee development, promotion readiness, succession planning, location access, and owner-level reporting.

## Source of Truth

This repository is the permanent source of truth for the CTOD application.

- **GitHub**: application source, version history, rollback, engineering documentation
- **Vercel**: production web application hosting
- **Supabase**: PostgreSQL database, authentication, authorization, row-level access, and backend functions
- **Resend**: production transactional email delivery for CTOD invitations and account onboarding
- **GoDaddy**: DNS registrar for the CTOD production domain

## Production Domain

- Registered domain: **ctodsystem.com**
- Planned application URL: **app.ctodsystem.com**
- Planned invitation sender: **CTOD <invites@ctodsystem.com>**

The prior Vercel URL remains the temporary application endpoint until the production domain is connected.

## Required User Experience

### Owner / Master

The Owner account manages company-wide CTOD data and can:

- view the Master dashboard and reports
- invite managers, market leaders, area directors, executives, and viewers
- assign one or many locations to a user
- change access when leaders transfer or change roles
- preserve historical review and employee data when access changes
- view promotion readiness, coaching, goals, trends, and finalized review history

### Location Manager

A Location Manager is tied to one or more assigned locations and can:

- log in from a saved desktop/browser shortcut
- see only authorized location data
- complete and finalize employee reviews
- create and manage coaching moments
- print the professional two-page employee review summary
- add employees to the location roster
- edit employee/job information as permitted
- deactivate employees from the active roster while preserving historical records

## Invitation / Onboarding Flow

Production onboarding must work as follows:

1. Owner opens **Access Management** in CTOD.
2. Owner enters the recipient's work email.
3. Owner chooses the role and exact location(s).
4. Owner clicks **Send Invite**.
5. CTOD sends a branded invitation email through Resend.
6. Recipient clicks a link that opens **CTOD on the Vercel/custom domain**, never a raw Supabase page.
7. Recipient creates a password.
8. CTOD activates the assigned role/location access.
9. Recipient lands on the authorized CTOD dashboard.
10. Recipient can save/bookmark `app.ctodsystem.com` and use email + password for future logins.

Existing users must be reassigned without creating a second account. Access changes should update role/location permissions while retaining the same login and history.

## Review Requirements

- manager-facing review workflow
- save progress and resume later
- required-field validation that clearly identifies missing items
- coaching moments integrated into the review lifecycle
- two-cycle coaching resolution rule
- raise request workflow with reason, employee explanation, and timing
- professional two-page printable review summary for employee acknowledgment/signature and HR scanning
- signed summary does **not** need to be stored in the Owner Master
- finalized reviews automatically update Master reporting

## Current Rollout Status - 2026-08-08

Completed / established:

- permanent GitHub repository established
- Supabase production project active
- Vercel application running
- Vercel project connected to GitHub repository `keagan173/CTOD`
- production branch is `main`
- Owner account and Access Management implemented in source
- role/location assignment model implemented
- Location 040 pilot data present
- review finalization and two-page printing tested
- Master reporting connected to finalized review data
- `ctodsystem.com` purchased
- Resend account and API key created
- `ctodsystem.com` connected to Resend through GoDaddy Domain Connect
- Resend DNS verification completed
- custom SMTP saved in Supabase Authentication using Resend
- configured sender: `CTOD <invites@ctodsystem.com>`

Current deployment validation:

- a fresh commit was pushed after connecting Vercel Git integration to trigger a production deployment from `main`
- confirm the live CTOD deployment now includes the **Access Management** tab
- after Access Management appears, run the real Location 040 manager invitation test

Foundation acceptance test:

1. Owner signs into CTOD.
2. Access Management is visible only to Owner/Admin.
3. Owner sends invite to work email for Manager + Location 040.
4. Invitation arrives from CTOD through Resend.
5. Recipient clicks CTOD link and creates a password.
6. Recipient signs in and sees only Location 040 manager access.
7. Manager can complete reviews and coaching moments.
8. Finalized review updates Owner Master correctly.

Next build after foundation test:

- Location Employee Management
- add/deactivate employee workflow
- improved manager coaching workspace
- promotion-readiness gauges and red/green readiness screen
- succession/depth charts
- talent heatmaps
- multi-location Area Director dashboards
- trend and leadership pipeline reporting

## Engineering Rules

1. GitHub `main` is the production source of truth.
2. Vercel must deploy production from the connected GitHub `main` branch.
3. Do not rebuild the application from deployment fragments.
4. Supabase is backend-only. Users should not be sent to raw Supabase pages.
5. All user-visible onboarding, password setup, reviews, dashboards, and printing stay on CTOD/Vercel/custom-domain pages.
6. Never hard-delete historical employee/review data merely because a manager or employee leaves a location.
7. Location access belongs to roles/users, while employee history remains with the employee/location record.
8. Production secrets and API keys must never be committed to GitHub.

Baseline established: 2026-08-08.
