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
- search employees by name or six-digit employee number
- open every finalized review in read-only mode
- generate the dated two-page summary for any finalized review

### Location Manager

A Location Manager is tied to one or more assigned locations and can:

- log in from a saved desktop/browser shortcut
- see only authorized location data
- complete and finalize employee reviews
- create and manage coaching moments
- print the professional two-page employee review summary
- add employees to the location roster using the permanent six-digit employee number
- edit employee/job information as permitted
- deactivate employees from the active roster while preserving historical records
- search an employee and open all prior finalized reviews in read-only mode

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
- question-specific reasons across all five rating bands
- development goal dropdown
- standard career direction for every job role
- next job role and ultimate / long-term job role
- manager promotion-readiness selection after employee career choices
- structured compensation discussion with employee reason/timing and manager timing/comment
- professional two-page printable review summary for employee acknowledgment/signature and HR scanning
- finalized reviews are immutable/read-only
- finalized reviews automatically update Master reporting and talent pipeline
- finalized review history follows the employee's six-digit identity across location transfers

## Current Rollout Status - 2026-08-11

Completed / established:

- permanent GitHub repository established
- Supabase production project active
- Vercel application running and connected to GitHub `main`
- Owner account and Access Management implemented
- role/location assignment model implemented
- Manager Coaching, Employees, Review Schedule, Reviews, and Master workspaces implemented
- six-digit employee number established as permanent employee identity
- employee transfer/history model preserves prior reviews and coaching
- review finalization and two-page printing implemented
- finalized review archive and read-only historical viewer implemented
- Master reporting connected to finalized review data
- company talent pipeline, promotion readiness, map, succession intelligence, and leadership summary implemented
- Presentation Mode implemented for executive demonstrations
- career-direction workflow standardized across every job role
- compensation workflow standardized and structured
- question-specific review reasons built across all active questions and all five rating bands
- authenticated Reviews roster loading and direct review reopening verified in production
- two consecutive review cycles completed for the isolated Location 040 QA employee
- coaching carry-forward verified at 1 of 2 after cycle one and closed at 2 of 2 after cycle two
- finalized review intelligence verified at 3.00 / 60% / Meets Expectations
- promotion readiness verified as Ready in 1 Year
- date-only rendering, goal deduplication, Review History, and Talent Trajectory reporting repaired
- compensation, manager summary, and employee comments restored to finalized review reporting
- one future review is created after finalization without duplicating the active review
- isolated fake QA evidence retained pending deliberate cleanup approval
- `ctodsystem.com` purchased and Resend configured for CTOD invitations

### Validated production release

The current production acceptance record, locked decisions, data state, and handoff are documented in:

- [Production QA release — 2026-08-11](docs/PRODUCTION_QA_RELEASE_2026-08-11.md)
- [Current project handoff](docs/CURRENT_HANDOFF.md)
- [Changelog](CHANGELOG.md)

The validated application release is GitHub commit `4ab3f45`. The isolated QA lifecycle currently contains two finalized reviews, one future review, zero active coaching items, and one active goal for `QA TEST · 990040`.

The next controlled step is to decide whether to retain or remove that exact fake QA evidence, confirm the resulting baseline, and then onboard the first real Location 040 employee. Cleanup must be narrowly targeted; legitimate employee history is never bulk-deleted.

## Engineering Rules

1. GitHub `main` is the production source of truth.
2. Vercel must deploy production from the connected GitHub `main` branch.
3. Do not rebuild the application from deployment fragments.
4. Supabase is backend-only. Users should not be sent to raw Supabase pages.
5. All user-visible onboarding, password setup, reviews, dashboards, and printing stay on CTOD/Vercel/custom-domain pages.
6. Never hard-delete legitimate historical employee/review data merely because a manager or employee leaves a location.
7. Test data may be cleared before a production rollout, but real employee history must remain permanent.
8. Location access belongs to roles/users, while employee history remains attached to the permanent six-digit employee identity.
9. Finalized reviews are read-only records.
10. Production secrets and API keys must never be committed to GitHub.

Baseline updated: 2026-08-11.
