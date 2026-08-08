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
- Owner account and Access Management implemented
- role/location assignment model implemented
- Location 040 pilot data present
- review finalization and two-page printing tested
- Master reporting connected to finalized review data
- `ctodsystem.com` purchased
- Resend account and API key created
- `ctodsystem.com` connected to Resend through GoDaddy Domain Connect
- GoDaddy DNS records confirmed present for Resend sending:
  - MX `send` -> Amazon SES feedback endpoint, priority 10
  - TXT `resend._domainkey` -> DKIM public key
  - TXT `send` -> SPF configuration
  - supporting `_spfm.send` TXT record created by Domain Connect

In progress:

- wait for DNS propagation / Resend domain verification to change from Not Started to Pending/Verified
- connect Resend SMTP to Supabase Authentication
- configure sender as `CTOD <invites@ctodsystem.com>`
- connect `app.ctodsystem.com` to Vercel
- complete true first-time Location 040 manager invitation test
- validate: invite email -> create password -> manager login -> complete review -> finalized review updates Master

### Next Session Resume Point

1. Open Resend -> Domains -> `ctodsystem.com`.
2. Refresh and confirm domain status is **Pending** or **Verified**.
3. Do not edit the GoDaddy DNS records unless Resend shows a specific validation failure. The required records are already present.
4. Once verified, open Supabase -> Authentication -> Emails -> SMTP Settings.
5. Enable custom SMTP and configure:
   - Sender email: `invites@ctodsystem.com`
   - Sender name: `CTOD`
   - Host: `smtp.resend.com`
   - Port: `465`
   - Username: `resend`
   - Password: private Resend API key (never commit to GitHub)
6. Save/test SMTP.
7. Then wire/confirm `app.ctodsystem.com` on Vercel and run the real Location 040 invitation test.

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
2. Do not rebuild the application from deployment fragments.
3. Supabase is backend-only. Users should not be sent to raw Supabase pages.
4. All user-visible onboarding, password setup, reviews, dashboards, and printing stay on CTOD/Vercel/custom-domain pages.
5. Never hard-delete historical employee/review data merely because a manager or employee leaves a location.
6. Location access belongs to roles/users, while employee history remains with the employee/location record.
7. Production secrets and API keys must never be committed to GitHub.

Baseline established: 2026-08-08.
