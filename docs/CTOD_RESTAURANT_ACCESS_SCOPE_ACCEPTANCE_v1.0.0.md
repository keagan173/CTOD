# CTOD Restaurant Access Scope Acceptance v1.0.0

Date: 2026-08-13
Environment: CTOD 002 Sandbox only
Production impact: none

## Objective
Prove that location-scoped and company-wide authorization are enforced by the database for the five-location Restaurant Acceptance Group.

## Test tenant
- Company: Restaurant Acceptance Group
- Industry template: RESTAURANT v1.0.0
- Active locations: R01, R02, R03, R04, R05

## Test identities
- Executive: sandbox-executive@ctod.test
- Manager: sandbox-manager@ctod.test

## Access assignment
- Executive membership: company-wide executive for Restaurant Acceptance Group.
- Manager membership: manager for Restaurant Acceptance Group with one active user_location_access grant to R01 only.

## Database authorization proof
The authorization function under test is `private.can_access_location(company_id, location_id)` using the signed-in user's `auth.uid()` identity.

### Executive result
- R01: allowed
- R02: allowed
- R03: allowed
- R04: allowed
- R05: allowed

Result: PASS. Executive access spans the full company.

### Manager result
- R01: allowed
- R02: denied
- R03: denied
- R04: denied
- R05: denied

Result: PASS. Location manager is constrained to the specifically authorized restaurant.

## RLS table-read proof
The same identities were then tested while executing as the Postgres `authenticated` role against `public.locations`, proving the row-level security policy itself filters records correctly.

### Manager RLS result
Visible rows: R01 only.

### Executive RLS result
Visible rows: R01, R02, R03, R04, R05.

Result: PASS. The restriction is enforced by database RLS and cannot be bypassed by merely changing the front-end UI.

## Acceptance conclusion
CTOD supports the required access model for a five-location restaurant group using one multi-tenant core:
- senior/executive leadership can see the Company Master across locations;
- a location manager can be limited to a single authorized location;
- authorization is enforced at both the authorization helper and RLS table-read layers, not merely hidden in the UI.

This acceptance test used Sandbox test identities and fictional tenant data only. CTOD 001 Production was not modified.
