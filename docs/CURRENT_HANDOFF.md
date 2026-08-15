# CTOD Current Project Handoff

Updated: 2026-08-14
Handoff: v1.3.6 Commercial Tire 001 Talent Intelligence checkpoint

## Locked architecture

CTOD remains one multi-tenant SaaS platform. Do not fork the product per customer. Platform Owner, customer Company Masters, location workspaces, customer sandbox/versioning, tenant isolation, audit/history, and non-destructive upgrades remain locked.

Permanent rule: **CTOD never replaces the past; it adds the next version on top of the past.** Existing employees, assignments, reviews, coaching, access, configuration versions, release history, and finalized outcomes must survive future upgrades.

## Production tenant / pilot

- Commercial Tire = customer/template `001` reference tenant.
- Location `040` Meridian = active real pilot workspace.
- Managers add and maintain their own employees.
- Manager-added employee data writes directly to Production tenant history and is visible to higher authorized levels automatically.
- Review scheduling now uses the manager-entered employee review date as authoritative; subsequent date defaults to six months later.
- Location 040 currently has real employees/reviews and should not be replaced with fictional test data.

## Review reconciliation completed this session

### Employee Development & Career

Next-year goal is a dropdown, not free text. Current options include Pay increase, Experience in another role, Training / certification, Promotion to the next role, Improve performance in current role, More responsibility, Leadership development, Technical skill development, Sales / customer development, and Other development goal.

The prior five-year-position question was removed from the active review. Historical database fields were preserved rather than deleted.

### Career Direction

Use one authoritative Career Direction block only. A prior MutationObserver bug created duplicate Career Direction panels; this was fixed by canonical panel ID/deduplication.

Career directions:
- Advancement / another position
- Satisfied in current position
- Specialist / technical career path
- Still exploring career direction

When Advancement is selected, the manager must see and complete:
- Next position desired
- Long-term position desired
- **Manager readiness for next position**

Locked readiness values:
- Ready Now
- 30-90 Days
- Within 1 Year
- Not Yet Ready

Readiness is a major CTOD intelligence field. It must remain searchable, reportable, included in summaries, and drive succession/depth analytics.

When Specialist / technical career path is selected, manager specialist-growth options include Training / certifications, Mentorship / training others, More responsibility in current specialty, Management responsibility, Higher-level specialist / broader organizational scope, Advanced technical mastery, and Cross-functional specialist experience.

### Employee Voice

Employee Voice answers are structured dropdowns and permanent historical data.

1. Do you feel like safety is a priority in your current position? Yes / No
2. Do you feel like you have a career? Yes / No
3. Which is more important to you in your current position? More money / more hours OR More flexibility / flexible hours
4. Would you be willing to relocate for the right career opportunity? Yes / No / Maybe, depending on the opportunity

Do not restore `A balance of both` for work preference. Leadership wants hard comparative data.

### Compensation / comments

- Development Goal / Raise Conditions belongs with or after the raise discussion when development conditions apply.
- Manager Summary and Employee Comments belong together at the end of the review.
- Career Direction styling must match the dark CTOD review UI.

## Two-page review summary contract

The printable/finalized two-page review summary must include meaningful review intelligence: ratings, career direction, next desired position, long-term direction when used, manager readiness, specialist growth path when applicable, next-year goal, Employee Voice answers, compensation/raise data, coaching/carry-forward data, and final manager/employee comments.

Do not allow key career or Employee Voice information to exist only on the interactive review screen.

## 001 role library expansion

Added active Commercial Tire roles:
- Market Manager Level 1
- Market Manager Level 2
- Market Manager Level 3
- AP Specialist
- IT Administrator
- Administrative Assistant
- Director of Sales
- Regional Sales Manager
- Human Resources

Each received 5 role-specific Current Role Performance questions and standard rating/reason structures.

## Shared Master / access model

Every customer workspace should expose a **Master** intelligence tab.

Locked behavior:
- Everyone may see the company location accountability map.
- A location manager must NOT see employee names, reviews, or confidential detail from unauthorized locations.
- Employee-level drill-down, People Pulse, talent search, reviews, and depth detail are restricted to the viewer's authorized scope.
- Location manager = own authorized location(s).
- Market leader = authorized market/location scope.
- Area leader = authorized area/location scope.
- Executive = company-wide customer scope.
- Platform Owner remains above customer scope with platform governance rights.

### Company-wide location accountability map

Every workspace should see all company locations as shared accountability context.

Current starter rule:
- Green = review schedules current
- Yellow = some overdue / insufficient schedule data
- Red = materially overdue; starter threshold currently >20% scheduled reviews overdue

The purpose is visible accountability without exposing unauthorized employee records.

## People Pulse / analytics

People Pulse is a leadership intelligence surface based on finalized Employee Voice data within the viewer's authorized scope.

Current modernized UI includes dark circular gauges, Safety priority %, Career confidence %, Relocation openness %, Flexibility vs money/hours preference, role comparison/response counts, and job-role drilldown.

Long-term goal: compare sentiment by job role, location, market, area, and company scope and quickly identify patterns.

Example leadership signals:
- 40% answered No to Safety is a Priority => strong red/critical signal
- only 5% are relocation-open => caution/yellow mobility signal
- role-level comparisons for career confidence or work preference

## Talent Search / career intelligence

The Master should support filtering authorized employees by at least Career Direction, Next Position, Readiness, and Job Role.

Core use case: `Show everyone who wants Assistant Manager and is Ready Now.`

This is central to CTOD's purpose: managing employee careers and giving leaders real-time bench intelligence.

## Depth Chart

Every workspace should have a Depth Chart (formerly Succession).

Desired role-by-role layout:
- Current incumbent(s)
- Ready Now bench
- 30-90 Days bench
- Within 1 Year bench
- Not Yet Ready / development pipeline
- gap / concern signal when bench is weak or absent

Depth detail obeys viewer authorization.

## Manager password recovery

Customer login includes Forgot Password / reset flow. Password reset preserves existing company/location access, employees, reviews, and history.

## Branding / domain

Established CTOD black/gold identity remains locked. Customer brand bar safe-area was adjusted to prevent the primary mark from being clipped.

Domain plan remains in `docs/BRANDED_DOMAIN_PLAN.md`:
- preferred customer address: `ctod.app` or branded customer app domain once owned
- preferred owner address: `owner.ctod.app` if using `ctod.app`
- migrate Supabase auth redirects, invitations, password recovery and canonical links away from `*.vercel.app`

User upgraded Vercel to Pro on 2026-08-14. Build-rate throttling is no longer the active blocker.

## UI fixes completed this session

- duplicate Location Command Center fixed/deduped
- duplicate Career Direction panels fixed/deduped
- Career Direction dark styling aligned with review
- readiness explicitly forced visible for Advancement
- People Pulse white cards replaced with modern gauges/charts
- job-role People Pulse drilldown added
- customer brand mark safe-area enlarged
- Master exposed across workspaces with shared-map + scoped-intelligence direction

## Current deployment checkpoint

Code checkpoint before handoff documentation: `884729777f9d69cec8d6698ff1728e5d1df822a5` (`deploy: modern people pulse analytics and brand fix`).

At that checkpoint:
- Vercel Production `ctod`: SUCCESS
- Vercel Sandbox `ctod-sandbox`: SUCCESS
- Vercel Pro active

Always verify GitHub `main` and Vercel at the start of the next session because documentation commits advance `main` beyond the code checkpoint.

## Immediate next build block

1. Hard-QA LOC040 Career Direction after fresh load: exactly one panel, Advancement displays required readiness dropdown, value saves/reloads correctly.
2. Finish Depth Chart into role -> incumbent -> Ready Now -> 30-90 Days -> Within 1 Year -> gap/concern presentation.
3. Verify Talent Search filters career direction + next position + readiness + current job role and returns only authorized employee detail.
4. Complete Master map visualization for all Commercial Tire locations with green/yellow/red health while preventing unauthorized employee drilldown.
5. Validate People Pulse gauges/charts against real finalized review data and define/lock red-yellow-green thresholds for each sentiment metric.
6. Complete two-page review summary acceptance so career/readiness/specialist/Employee Voice/compensation/comment data appears correctly.
7. Run one controlled end-to-end LOC040 review: open -> ratings -> development/career -> Employee Voice -> compensation -> comments -> finalize -> two-page summary -> Master/People Pulse -> Depth Chart -> next six-month cycle.
8. After 001 review/talent acceptance, return to branded-domain setup (`ctod.app`) and commercial onboarding polish.

## Guardrails

- Do not redesign the multi-tenant architecture.
- Do not destroy or overwrite historical customer data.
- Do not expose unauthorized employee detail through the shared company map.
- Do not remove readiness from the review or treat it as optional analytics decoration.
- Do not use fictional persistent Production employees/reviews for testing.
- Preserve Platform Owner separation from customer memberships.
- Keep role/question differences configuration-driven rather than customer-specific code forks.

## Exact restart phrase

`Resume CTOD build from Handoff v1.3.6 Commercial Tire 001 Talent Intelligence checkpoint. Verify GitHub main and Production/Sandbox first. Continue LOC040 QA with manager readiness as a required career field, finish the access-scoped Master + company-wide green/yellow/red location map, searchable talent filters, Depth Chart, People Pulse analytics, and two-page review summary. Preserve all history and do not redesign the locked multi-tenant architecture.`
