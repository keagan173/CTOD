# CTOD Current Project Handoff

Updated: 2026-08-14
Handoff: v1.3.7 Commercial Tire 001 Sandbox Stabilization + Intelligence checkpoint

## Locked architecture

CTOD remains one commercial multi-tenant SaaS platform. Do not fork the product per customer. Platform Owner, customer Company Masters, location workspaces, customer configuration/versioning, tenant isolation, audit/history, and non-destructive upgrades remain locked.

Permanent invariant: **CTOD never replaces the past; it adds the next version on top of the past.** Existing employees, assignments, reviews, coaching, goals, access, configuration versions, release history, finalized outcomes, and historical intelligence must survive future upgrades.

## Release pipeline is now locked

The Vercel projects are intentionally separated:
- `ctod-sandbox` Vercel project tracks Git branch `ctod-sandbox`.
- Production `ctod` Vercel project tracks Git branch `main`.

Required release path:
1. Build only on `ctod-sandbox`.
2. Automatic Sandbox deploy.
3. GitHub validation gate must pass.
4. Inspect the real customer-workspace replica in Sandbox.
5. Fix and retest there until approved.
6. Promote the exact tested code to `main`.
7. Vercel Production deploys automatically from `main`.
8. Verify Production deployment before telling customers the release is live.

Do not intentionally use Production customer workspaces as the first QA target for front-end changes.

## Commercial Tire 001 pilot

- Commercial Tire = customer/template `001` reference tenant.
- Location `040` Meridian = real pilot workspace.
- Managers add and maintain employees in their authorized location(s).
- Manager activity writes to the tenant history and becomes visible to higher authorized levels automatically.
- Production history must not be replaced with fictional test data.

## Customer workspace shell now locked in Sandbox

Approved navigation order:
**Master | Reviews | Coaching | Employees | People | Review Schedule | Depth Chart**

Rules:
- Master is the first/default tab.
- Master remains visible to every active customer user.
- People remains visible.
- Depth Chart remains visible.
- Older modules must not hide, duplicate, rename away, or recreate these navigation items.
- One customer brand header only.

The restored Master lineage is the approved presentation-quality experience with the real interactive company map and Presentation Mode. Future stabilization may simplify plumbing underneath it but must not downgrade an approved visual/product experience.

## Branding

CTOD black/gold brand system remains locked.

The customer primary logo asset was corrected because the SVG canvas itself was cropping the `OD` from `CTOD`. The Sandbox asset now contains a wider viewBox and full CTOD wordmark.

## Company-wide accountability map

The Master map is visible to every active customer user regardless of their employee-detail access.

Commercial Tire currently has **55 active locations across 4 states, 7 areas, and 10 markets** in the aggregate map source.

Important security split:
- Everyone may see all active company location markers and aggregate location accountability status.
- A location manager does NOT gain employee names, reviews, compensation, coaching detail, or confidential people data from another location.
- Employee-level detail remains access-scoped.

The map now uses a dedicated safe aggregate company RPC rather than direct RLS-scoped customer tables. This prevents Location 040 managers from seeing only LOC040 while preserving confidentiality.

Current accountability inputs include active location, state/area/market, scheduled reviews, overdue reviews, finalized reviews, completion %, and green/yellow/red health.

## Master intelligence contract

The Master is CTOD's leadership intelligence surface. It must turn data collected during normal product use into filterable, comparable organizational information instead of merely storing forms.

Current/required data domains:
- Employee Voice
- Review performance
- Review question ratings and reasons
- Coaching
- Goals
- Career direction
- Desired next role
- Long-term role direction where used
- Manager readiness
- Specialist growth path
- Compensation/raise discussion
- Review comments and finalized summaries
- Succession/depth coverage

All employee-level analytics respect the viewer's authorized location scope unless a specific aggregate-only company-wide contract has been intentionally defined, like the location accountability map.

## Employee Voice analytics

Structured historical questions:
1. Safety is a priority in current position? Yes / No
2. Feels they have a career? Yes / No
3. More money / more hours OR more flexibility / flexible hours
4. Willing to relocate? Yes / No / Maybe depending on opportunity

`A balance of both` remains removed because leadership wants hard comparative data.

People Pulse / Intelligence Explorer supports one, multiple, or all job-role selections and recalculates percentages from raw response counts rather than averaging percentages.

Required examples:
- Compare Tire Tech + Service Tech + Inside Sales safety sentiment.
- Which role has the highest Safety Yes percentage?
- Which role has the highest Safety No percentage?
- Which role most prefers more money / more hours?
- Which role most prefers flexibility?
- Which role most strongly/weakly feels they have a career?
- Which role is most open to relocation?

## Review question intelligence

Sandbox now includes question-level review analytics from finalized review answers.

Required capabilities:
- filter one, several, or all job roles
- show weighted score by review question
- show Meets-or-better percentage
- show Needs Improvement / Unsatisfactory percentage
- show response count
- show most common rating reason
- identify strongest and weakest questions/roles

Leadership use cases include:
- Which job role scores lowest on Customer Service?
- What rating reason appears most often for Tire Techs?
- Compare Inside Sales + Assistant Managers on leadership questions.

## Career, readiness and Depth Chart

Career directions remain:
- Advancement / another position
- Satisfied in current position
- Specialist / technical career path
- Still exploring career direction

Advancement requires:
- Next position desired
- Long-term position desired
- Manager readiness for next position

Locked readiness values:
- Ready Now
- 30-90 Days
- Within 1 Year
- Not Yet Ready

Readiness must remain searchable, reportable, included in summaries, and drive Master/Depth Chart intelligence.

Depth Chart target layout:
- Current incumbent(s)
- Ready Now bench
- 30-90 Days bench
- Within 1 Year bench
- Not Yet Ready / development pipeline
- gap / concern signal

## Coaching and goals intelligence

Coaching fields collected include type, category, reason, notes, expected outcome, review inclusion, status, resolved streak, active carry-forward, review cycle, and timestamps.

Master intelligence should expose patterns such as corrective/development/recognition counts, active carry-forward, repeat categories, resolution patterns, and role/location concentration while keeping notes confidential to authorized scope.

Goals include goal text/type, status, target date, completion, raise linkage, promotion linkage, carry-forward, and origin review. Analytics should expose active/completed, promotion-linked, raise-linked, overdue, carry-forward, goal type, and role/location patterns.

## Compensation intelligence

Compensation decisions include raise requested, reason/basis, employee request note, requested timing/date, manager timing/comment, decision status, planned effective date, amount type/value, and linked development goal.

Master analytics should support authorized-scope comparisons such as raise-request rate by role, top reasons, timing patterns, approval/decision patterns, and linkage to goals or promotion readiness.

## Two-page review summary contract

The finalized printable summary must carry the important historical intelligence, not only ratings:
- ratings and reasons
- career direction
- next desired position
- long-term direction when used
- manager readiness
- specialist growth path when applicable
- next-year goal
- all Employee Voice answers
- compensation/raise discussion
- coaching/carry-forward information intended for the review
- final manager summary and employee comments

Finalized historical records remain protected from destructive overwrite.

## Role library

Commercial Tire 001 includes the existing location/service/sales/management roles plus recently added:
- Market Manager Level 1
- Market Manager Level 2
- Market Manager Level 3
- AP Specialist
- IT Administrator
- Administrative Assistant
- Director of Sales
- Regional Sales Manager
- Human Resources

Each new role has five role-specific Current Role Performance questions and rating/reason structures.

## Support / commercial readiness

A customer browser freeze exposed the need for commercial support tooling. The build now includes runtime telemetry direction and Owner-side System Health / Support Control Tower work so the Platform Owner can diagnose customer workspace failures without customer passwords or unrestricted access to confidential employee content.

The commercial support model is:
Customer reports problem -> Owner health view identifies tenant/location/release/module -> Sandbox reproduces and fixes -> validation -> exact tested release promoted to Production.

## Current Sandbox checkpoint

Current tested Sandbox code checkpoint before this documentation update:
`179542ccb94c76c68a9310142ab2d1fbd51a0bd2`

Recent verified components in Sandbox:
- stable single customer header
- full CTOD logo asset fix
- Master tab first and persistent
- restored interactive Master map + Presentation Mode
- 55-location company-wide aggregate map source
- People and Depth Chart persistent navigation
- Intelligence Explorer with multi-role selection
- Employee Voice role rankings
- review/coaching/goals/career/compensation intelligence surfaces
- question-level review analytics
- runtime telemetry / support direction
- GitHub Sandbox validation gate

Latest observed Vercel Sandbox deployment: SUCCESS.
Production remains on `main` and has not been intentionally promoted to this current Sandbox feature set yet.

## Immediate next build block

1. Visually verify full CTOD logo after hard refresh.
2. Continue full Intelligence Explorer UX polish and verify all collected fields have a display/filter/aggregation contract.
3. Add richer location/market/area/date-range filtering where appropriate.
4. Harden question-level rankings and reason analytics.
5. Finish Depth Chart presentation and gap/bench signals.
6. Validate the two-page review summary end to end.
7. Run a controlled Sandbox LOC040 review through finalization and confirm Review -> Summary -> Master -> People Pulse -> Talent Search -> Depth Chart.
8. Test repeated tab switching, Presentation Mode, filters, map, and analytics for responsiveness/no duplicate DOM modules.
9. Only after explicit approval, promote the exact tested Sandbox code to `main` and verify Production.

## Guardrails

- Do not redesign the locked multi-tenant architecture.
- Do not destroy or overwrite history.
- Do not expose unauthorized employee detail through company-wide aggregate surfaces.
- Do not remove or make manager readiness optional for Advancement.
- Do not restore `A balance of both` to work preference.
- Do not downgrade the approved Master map/Presentation Mode experience.
- Do not push new customer-facing feature work directly to Production first.
- Do not assume 'saved in repository' means released; Sandbox QA and exact promotion are required.
- Preserve Platform Owner separation from customer memberships.
- Keep customer differences configuration-driven rather than code forks.

## Exact restart phrase

`Resume CTOD build from Handoff v1.3.7 Commercial Tire 001 Sandbox Stabilization + Intelligence checkpoint. Verify ctod-sandbox branch, Sandbox deployment, validation gate, and Production main first. Continue the full intelligence audit/Explorer, company-wide 55-location aggregate map, question-level review analytics, Depth Chart, People Pulse, two-page summary, and end-to-end LOC040 Sandbox QA. Preserve approved Master Presentation Mode, all history, tenant isolation, and the locked Sandbox -> approve -> main -> Production release gate.`
