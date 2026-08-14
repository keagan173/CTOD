# CTOD Operator Control Plane — Security and Sandbox Acceptance

Date: 2026-08-12

Candidate: `agent/ctod-operator-control-plane` / CTOD `1.1.0`

Sandbox Supabase project: `zgwkjyezpgboysiklodj`

Production changes: none

## Identity boundary

Platform operators live in `private.platform_operators`. They are authenticated users but are not customer employees, customer managers, or members of any customer company.

The accepted sandbox state has:

- one active platform administrator
- zero customer memberships for that platform administrator
- one Commercial Tire Sandbox Master membership
- no platform-operator row for the Sandbox Master

Database functions reject creation or activation of an operator identity that has any `company_memberships` row. Customer provisioning rejects assigning a known operator email as the initial customer owner.

## Authorization path

The browser calls `ctod-operator-admin` with its signed-in JWT. The Edge Function independently resolves the Auth user and then touches/authorizes the private operator row. It is the only browser-facing broker for operator actions.

All operator RPCs are revoked from `public`, `anon`, and `authenticated`; only `service_role` has execute permission. Authenticated customer sessions have no SELECT privilege on private operator, customer-account, release, health, hold, or audit tables.

Two narrowly scoped operator routines require `SECURITY DEFINER` because they validate Auth identities. Their signatures remain executable only by `service_role`, and both use an empty `search_path`. All other operator RPCs are security invokers.

## Privacy contract

The operator dashboard and diagnostics return:

- company identity and lifecycle metadata
- template/configuration/core version status
- aggregate counts for locations, employees, roles, reviews, and configuration state
- leader/owner Auth email, customer role, active state, and assigned-location count
- operator audit and release history

They do not select or return employee names, employee numbers, review answers, review comments, coaching notes, goals, compensation content, or review document content.

## Lifecycle behavior

Suspension and closure are authoritative:

1. Active customer memberships and location grants are recorded in `private.customer_access_holds`.
2. Those exact rows are made inactive without deletion.
3. The customer company becomes inactive.
4. Company-scoped RLS helpers require both active access and an active company, so operational queries return no rows even through older privileged customer RPCs.
5. The signed-in customer may read only its own inactive membership and basic company status so CTOD can explain why access is paused.
6. Reactivation restores only the held rows and records their release time.

Invitation delivery and activation both reject an inactive customer.

## Sandbox acceptance results

`CTOD Operator Acceptance Co` (`c2c023a8-e36b-450d-9f00-2e5467216bb4`) was provisioned through the operator API using the Blank Standard Master.

| Check | Result |
|---|---|
| Template lineage | `BLANK` / `1.0.0` |
| Initial lifecycle | Trial |
| Owner activation | Passed; one owner membership, zero location grants |
| Before suspension | Membership active; one published configuration visible |
| Suspension | One membership held; company inactive; configuration query returned zero rows |
| Reactivation | One membership restored; company active; published configuration visible again |
| Operations metadata | Deployment `ready`; backup `current`; support note saved |
| Aggregate diagnostics | One access account; health `warning` because blank tenant setup is intentionally incomplete |
| Privacy scan | No employee-name or review-content field in the dashboard/diagnostic payload |
| Operator separation | One active platform admin; zero company memberships |

The operator account creation path was also forced through two controlled backend failures during acceptance. In each case, the newly created Auth user was deleted automatically before the final successful retry, proving the compensating rollback.

## Advisor result

Supabase security advisor returned no finding tied to the new operator layer. Its 29 warnings are inherited from the existing application baseline. Performance advisor initially identified six uncovered control-plane foreign keys and a duplicate company SELECT policy; the candidate adds the covering indexes and consolidates the policy. Only expected unused-index informational notices remain for the newly created indexes.

Reference: [Supabase database linter guidance](https://supabase.com/docs/guides/database/database-linter)

## Release boundary

All migrations, Auth identities, fake acceptance data, and Edge Function deployments in this record are sandbox-only. The production Supabase project, production Vercel application, and GitHub `main` branch were not changed. Production adoption requires an explicit, separately reviewed release and operator bootstrap.
