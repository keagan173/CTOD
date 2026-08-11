# CTOD Sandbox Architecture

Updated: 2026-08-11

## Outcome

CTOD now has a persistent test environment that cannot write to production. It uses the same browser application and database contract, but a separate Supabase project, separate Auth tenant, separate Vercel project/deployments, one test login, and synthetic operational data only.

| Boundary | Production CTOD | CTOD Sandbox |
|---|---|---|
| Supabase project | `wezcuprboyvbmlnuqdoi` | `zgwkjyezpgboysiklodj` |
| Database/Auth | Production tenant | Independent project and Auth tenant |
| Vercel project | `ctod` | `ctod-sandbox` |
| Git release path | GitHub `main` only | Candidate branch or direct sandbox artifact |
| Browser environment | `production` | `sandbox` |
| Operational employees | Real production records | Three deterministic fake records |
| Login users | Production users | One Sandbox Master |
| Email behavior | Production provider configuration | Exact allowlist; server functions fail closed when unset |

Employees are business records, not application users. The three sandbox employees do not have Auth accounts and cannot log in.

## Current endpoints

- Supabase: `https://zgwkjyezpgboysiklodj.supabase.co`
- Stable Vercel alias: `https://ctod-sandbox-keaganelsberry-4694s-projects.vercel.app`
- Vercel project: `ctod-sandbox`
- Production-target sandbox deployment: `dpl_A1FsbMDwKgFKfTPNLRmRan6yS6tR`
- Preview sandbox deployment: `dpl_5VSTar8LdW48jcLXA3HxZAXb6AQV`

The Vercel team currently enforces Vercel Authentication on both preview and production aliases. A tester must first have access to the Vercel team/deployment, then use the CTOD Sandbox Master credential. Deployment protection was not weakened and no claimable/public copy was uploaded.

## Current sandbox state

- Auth users: 1
- active memberships: 1 (`owner`)
- profiles: 1
- fake employees: 3
- active assignments: 3
- reviews, answers, coaching moments, and goals: 0 after the reset proof
- employee location: 040 / Meridian
- fake employees:
  - Avery Sandbox, employee `990001`, General Manager
  - Jordan Sandbox, employee `990002`, Assistant Manager
  - Riley Sandbox, employee `990003`, Tire Technician

The login email is `sandbox-master@ctod.test`. Its generated password is never written to Git, Vercel, Library files, SQL seed files, or documentation.

## Environment guards

`scripts/build.mjs` is the only source of browser runtime configuration.

- A production build refuses any Supabase URL whose ref is not `wezcuprboyvbmlnuqdoi`.
- A sandbox build refuses the production ref.
- A sandbox build also refuses a URL that does not match its declared sandbox ref.
- Only `sb_publishable_` browser keys are accepted; secret/service-role keys are rejected.
- Vercel production builds default to production configuration.
- Vercel preview builds default to sandbox configuration.
- Local builds require an explicit environment.
- `public/ctod-config.js` repeats the project-ref checks before creating the single shared Supabase client.
- Production and sandbox sessions use different browser storage keys.

Every sandbox page receives a sticky yellow banner:

> SANDBOX — FAKE DATA ONLY  
> Changes here never update production CTOD

## Email and account controls

The browser, `send-ctod-invite`, and `complete-ctod-invite` all enforce the sandbox allowlist. The Edge Functions infer sandbox mode from the project ref even if `CTOD_ENVIRONMENT` is missing. If the server-side allowlist is missing, invitation sending and account creation are denied.

The single owner account was created once with an administrative bootstrap and the deployed `bootstrap-ctod-sandbox` function was immediately replaced by the checked-in permanent HTTP 410 implementation. Reprovisioning uses `npm run sandbox:bootstrap-user` with a server-side Supabase secret supplied only at runtime. The script refuses production, requires an allowlisted address and 16-character password, and refuses to run if any Auth user or company membership already exists.

## Rebuild from an empty Supabase project

1. Create a new empty Supabase project. Do not reuse the production project or copy production data.
2. Apply `supabase/baseline/ctod_schema.sql` as the schema baseline.
3. Apply `supabase/baseline/ctod_configuration_seed.sql` for safe configuration libraries only.
4. Replace `__CTOD_SANDBOX_PROJECT_REF__` in `supabase/sandbox/000_bootstrap.sql`, then apply it once.
5. Apply `supabase/sandbox/020_seed.sql`.
6. Run `npm run sandbox:bootstrap-user` with the sandbox URL/ref, production ref, allowlist, email, generated password, and a server-side Supabase secret in process environment variables.
7. Deploy `send-ctod-invite` with JWT verification enabled and `complete-ctod-invite` with its invitation-token authentication.
8. Deploy the permanently closed `supabase/sandbox/functions/bootstrap-ctod-sandbox/index.ts` implementation.
9. Run `supabase/sandbox/030_verify.sql` and both Supabase advisors.

The baseline is deliberately outside `supabase/migrations`. It recreates a new environment and must never replay against the existing production database.

## Reset procedure

Run these files only against project `zgwkjyezpgboysiklodj`, in order:

1. `supabase/sandbox/010_reset.sql`
2. `supabase/sandbox/020_seed.sql`
3. `supabase/sandbox/030_verify.sql`

The reset transaction first checks `ctod_sandbox.environment_guard`. It preserves Auth users, profiles, company memberships, location access, schema/configuration libraries, and the bootstrap audit marker. It removes fake operational records, resets finalized-review immutability only inside the guarded transaction, and then restores the deterministic three-person roster.

## Verification record

| Check | Result |
|---|---|
| Schema baseline | 31 tables, 7 enums, 56 public/private functions, 14 security-invoker views, 48 RLS policies |
| Configuration seed | 1 company, 55 locations, 14 roles, 4 campaigns, 5 ratings, 80 questions, 1,217 reasons |
| Password sign-in | HTTP 200 from the real sandbox Auth password flow |
| User context | `owner`, `is_master: true` |
| Manager roster RPC | HTTP 200, exactly 3 employees |
| Reset proof | Fourth probe employee removed; login/membership preserved; 3 fake employees restored |
| Security advisors | No errors; same 29 inherited warnings as production |
| Performance advisors | Same 14 inherited warnings; fresh-project unused-index notices only |
| Bootstrap endpoint | Version 3 is permanently closed with HTTP 410 source |
| Production counts | Auth 3, locations 55, employees/reviews/answers/coaching/goals 0, audit events 13 — unchanged during sandbox work |

The account-backed Vercel URL was observed redirecting to Vercel Authentication, so an unauthenticated visual UI pass is not claimed. Functional Auth/RPC checks used the deployed Supabase APIs directly, and static builds, source syntax, asset serving, and environment guards are verified in CI/local checks.

## Release rule

Sandbox work is reviewed on its own branch. Merging application infrastructure to `main` requires normal review and will deploy only the production configuration. Database baseline/reset/seed files remain manual sandbox-only operations. Nothing in this runbook authorizes applying them to production.
