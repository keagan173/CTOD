# CTOD Platform Rollout Acceptance v1.0.0

Date: 2026-08-13
Environment: CTOD 002 Sandbox only
Production impact: none

## Objective
Prove the Platform Release control path can safely perform a staged rollout and rollback against fictional tenants without touching CTOD 001 Production.

## Release used
- Version: `0.0.0-rollout-acceptance`
- Purpose: disposable Sandbox-only rollout mechanics acceptance
- Final status: retired
- This release is not CTOD 1.1.0 and is never eligible for Production deployment.

## Pilot tenants
- GreenScape Acceptance Co (`LANDSCAPE`)
- Restaurant Acceptance Group (`RESTAURANT`)

## Acceptance sequence
1. Validated the disposable release for Sandbox rollout mechanics only.
2. Approved the disposable release inside CTOD 002.
3. Scheduled the two fictional customers as a `pilot` rollout.
4. Activated the release for both customers.
5. Verified both customer account records moved from core version `1.0.1` to `0.0.0-rollout-acceptance` and retained `previous_core_version = 1.0.1` with rollback available.
6. Executed rollback for both customers.
7. Verified both returned to core version `1.0.1` and recorded `rollback_completed`.
8. Retired the disposable release immediately after acceptance.

## Defect discovered and fixed
The release validation service attempted to move a successful release into status `validated`, but the `private.platform_releases` check constraint allowed only `candidate`, `available`, and `retired`.

A CTOD 002 migration corrected the constraint to allow the intended `validated` lifecycle state.

Migration:
`supabase/migrations/20260813215000_ctod_002_allow_validated_platform_release_status.sql`

## Result
PASS.

CTOD now has a proven Sandbox path for:

`Candidate -> Validate -> Approve -> Pilot Schedule -> Activate -> Rollback -> Retire`

## Important production boundary
CTOD 1.1.0 remains blocked from Production approval until all real Production security requirements pass. The Sandbox rollout acceptance did not waive or satisfy the remaining Auth leaked-password-protection requirement.
