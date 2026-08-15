# CTOD Project Handoff v1.3.7

Updated: 2026-08-14
Checkpoint: Commercial Tire 001 Sandbox Stabilization + Intelligence

## Locked architecture
CTOD remains one commercial multi-tenant SaaS platform. Platform Owner, customer Company Masters, location workspaces, tenant isolation, audit/history, customer configuration/versioning, and non-destructive upgrades remain locked. CTOD never replaces the past; it adds the next version on top of the past.

## Locked release pipeline
- Vercel `ctod-sandbox` tracks Git branch `ctod-sandbox`.
- Vercel Production `ctod` tracks Git branch `main`.
- Required path: build in Sandbox -> automatic Sandbox deploy -> validation gate -> inspect real customer replica -> fix/retest -> explicitly approve -> promote exact tested code to `main` -> automatic Production deploy -> verify Production.
- Production customer workspaces are not the first QA target for new front-end work.

## Commercial Tire 001
Commercial Tire is the 001 reference tenant. LOC040 Meridian is the real pilot workspace. Managers maintain their employees. Production history must never be replaced with fictional persistent test data.

## Approved customer workspace shell
Navigation is locked as:
**Master | Reviews | Coaching | Employees | People | Review Schedule | Depth Chart**

Master is first/default and remains visible to every active customer user. People and Depth Chart remain persistent. One customer brand header only. Older modules must not hide, duplicate, rename away, or recreate these items.

The approved Master lineage is the presentation-quality experience with the real interactive company map and Presentation Mode. Stabilization may simplify internal plumbing but must not downgrade approved product experience.

## Branding
The CTOD black/gold system remains locked. The primary SVG itself was corrected because its original viewBox cropped the `OD` from `CTOD`; Sandbox now contains the corrected full wordmark asset.

## Company-wide accountability map
Every active customer user can see the entire active company location map as accountability context. Commercial Tire currently exposes **55 active locations across 4 states, 7 areas, and 10 markets** through a dedicated aggregate-only company RPC.

Employee confidentiality remains access-scoped. Location Managers do not gain names, reviews, coaching, compensation, goals, or other confidential detail from unauthorized locations. The map may expose aggregate location identity and people-management health only.

Current map metrics include scheduled reviews, overdue reviews, finalized reviews, completion percentage, and green/yellow/red status.

## Full intelligence contract
The Master must turn normal CTOD use into filterable organizational intelligence across:
- Employee Voice
- overall review performance
- question-level ratings/reasons
- coaching
- goals
- career direction
- desired next position
- manager readiness
- specialist growth path
- compensation/raise discussion
- finalized comments/summaries
- succession/depth coverage

Employee-level analytics remain access-scoped except where a deliberate aggregate-only company-wide contract exists.

## Employee Voice
Structured historical questions:
1. Safety priority? Yes / No
2. Feels they have a career? Yes / No
3. More money / more hours OR more flexibility / flexible hours
4. Relocation openness? Yes / No / Maybe depending on opportunity

`A balance of both` remains removed.

The Intelligence Explorer supports one, multiple, or all job roles and recalculates percentages from raw counts. It must answer questions such as which roles rank highest/lowest on safety, career confidence, money/hours preference, flexibility, and relocation openness.

## Review question intelligence
Sandbox includes question-level analytics from finalized review answers with one/multiple/all role selection, weighted score, Meets-or-better %, Needs Improvement/Unsatisfactory %, response count, common rating reason, and strongest/weakest ranking.

## Career/readiness
Career directions:
- Advancement / another position
- Satisfied in current position
- Specialist / technical career path
- Still exploring career direction

Advancement requires next desired position, long-term position, and manager readiness.

Locked readiness:
- Ready Now
- 30-90 Days
- Within 1 Year
- Not Yet Ready

Readiness stays searchable/reportable and drives Master/Depth Chart intelligence.

## Depth Chart
Target role-by-role view:
- incumbent(s)
- Ready Now bench
- 30-90 Days bench
- Within 1 Year bench
- Not Yet Ready/development pipeline
- gap/concern signal

## Coaching/goals/compensation
Coaching analytics should surface type/category/carry-forward/resolution and role/location patterns while keeping notes access-scoped. Goals should expose active/completed, type, target/overdue, promotion linkage, raise linkage, carry-forward, and role/location patterns. Compensation should expose authorized-scope raise-request rate, reasons, timing, manager decisions, planned effective timing, amounts where authorized, and goal/readiness linkage.

## Two-page summary
Finalized summary must carry ratings/reasons, career direction, desired roles, readiness, specialist path, next-year goal, all Employee Voice answers, compensation discussion, relevant coaching/carry-forward, manager summary, and employee comments. Finalized history must remain protected from destructive overwrite.

## Role library
001 includes Market Manager Level 1/2/3, AP Specialist, IT Administrator, Administrative Assistant, Director of Sales, Regional Sales Manager, and Human Resources in addition to existing customer roles. Each new role has five role-specific performance questions and rating/reason structures.

## Commercial support
The browser freeze exposed the need for Owner-side System Health / Support Control Tower and customer runtime telemetry. The commercial model is: customer reports issue -> Owner identifies tenant/location/release/module without customer password -> reproduce/fix in Sandbox -> validate -> promote exact tested build.

## Current Sandbox checkpoint
Code checkpoint before this documentation update: `179542ccb94c76c68a9310142ab2d1fbd51a0bd2`.

Verified/current Sandbox direction includes stable single header, full-logo asset fix, persistent Master/People/Depth Chart navigation, restored map + Presentation Mode, 55-location aggregate map, multi-role Intelligence Explorer, Employee Voice rankings, review/coaching/goals/career/compensation surfaces, question-level analytics, runtime telemetry direction, and the GitHub validation gate.

Production remains on `main`; this current Sandbox feature set has not been intentionally promoted yet.

## Immediate next build block
1. Visually verify full CTOD logo after hard refresh.
2. Continue full Intelligence Explorer UX and field-coverage audit.
3. Add richer location/market/area/date-range filters where appropriate.
4. Harden question/reason rankings.
5. Finish Depth Chart presentation and bench-gap signals.
6. Validate two-page summary end to end.
7. Run controlled LOC040 Sandbox review through Review -> Summary -> Master -> People Pulse -> Talent Search -> Depth Chart.
8. Stress-test repeated tab switching, Presentation Mode, filters, map and analytics for responsiveness and duplicate prevention.
9. Only after explicit approval promote exact tested Sandbox code to `main`, then verify Production.

## Guardrails
Do not redesign multi-tenancy, destroy history, expose unauthorized employee detail through aggregate surfaces, remove readiness, restore `A balance of both`, downgrade approved Master/Presentation Mode, or push customer-facing feature work directly to Production first. Sandbox QA and exact promotion are required.

## Restart phrase
`Resume CTOD build from Handoff v1.3.7 Commercial Tire 001 Sandbox Stabilization + Intelligence checkpoint. Verify ctod-sandbox branch, Sandbox deployment, validation gate, and Production main first. Continue the full intelligence audit/Explorer, company-wide 55-location aggregate map, question-level review analytics, Depth Chart, People Pulse, two-page summary, and end-to-end LOC040 Sandbox QA. Preserve approved Master Presentation Mode, all history, tenant isolation, and the locked Sandbox -> approve -> main -> Production release gate.`
