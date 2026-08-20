# CTOD PROJECT HANDOFF v1.3.9

Date: 2026-08-20
Checkpoint: Post-Pilot Productization + Domain Stabilization

## 1. Pilot status

Commercial Tire 001 LOC040 pilot is COMPLETE and accepted operationally. All employee reviews were completed, finalized, printed, signed, and delivered to HR. Review data, Employee Voice, compensation, career/readiness, Master intelligence, Depth Chart, PDF/print summary generation, and history are functioning in Production. Treat 001 as the golden reference customer and do not use it for experimental development.

## 2. Locked Production domains

- Customer application: `https://app.ctodsystem.com`
- Platform Owner console: `https://owner.ctodsystem.com`
- Technical fallback: `https://ctod.vercel.app`
- Root `https://ctodsystem.com`: reserved for future CTOD public sales/marketing site
- Planned Sandbox hostname: `https://sandbox.ctodsystem.com`

On 2026-08-20, `app.ctodsystem.com` was connected through GoDaddy DNS to Vercel, SSL completed, Vercel reported Valid Configuration, and Commercial Tire 001 loaded successfully from the new domain with Master/map/navigation/data intact.

Do not remove `ctod.vercel.app` yet. First validate invite activation, password reset, auth callbacks, PDF/print, and customer navigation on the new canonical domain. After those checks, customer-facing links should prefer `app.ctodsystem.com`.

## 3. Commercial Tire 001 protection rules

001 is now the protected production baseline. Preserve:
- approved Master Presentation Mode and full 55-location map
- Reviews, Coaching, Employees, People, Review Schedule, Depth Chart
- finalized review history and carry-forward behavior
- Employee Voice and People Pulse analytics
- career direction, readiness, succession intelligence
- approved adaptive professional review summary
- separate Download PDF / Print Portrait Report actions
- tenant isolation and access tiers
- current Production database and working customer flow

Any new core-engine work must be proven in Sandbox / another tenant before 001 promotion.

## 4. Review summary lock

Approved summary policy remains locked:
- Key Strengths: Exceptional ratings only
- Development Areas: Needs Improvement and Unsatisfactory only
- Exceeds Expectations and Meets Expectations stay in source history/analytics but are omitted from the concise printed summary
- Coaching is summarized by total count and coaching type/category rather than dumping every narrative
- Career Direction, Employee Voice, Compensation, Goals, Acknowledgment, and signature lines remain
- adaptive Letter portrait pagination can expand beyond two pages
- one canonical report generator only

## 5. Universal Question & Intelligence Engine

Core target architecture:

Customer wording -> Question definition -> Metric binding -> Generic response -> Master / Summary / Talent / Depth Chart

Questions must be metadata-driven. The engine must determine:
- purpose/category
- required status
- answer type/options
- canonical metric key/value
- visualization type
- feeds Master/People Pulse
- feeds Review Summary
- feeds Talent Search
- feeds Depth Chart/Succession
- filter dimensions

Customer wording may vary by industry while the underlying metric remains stable.

## 6. River Birch Landscaping

River Birch Landscaping is the first intended external customer validation tenant and must remain separate from Commercial Tire 001 while under QA.

River Birch Sandbox configuration already established:
- LANDSCAPE customer configuration
- 11 landscaping roles
- 63 performance questions
- 5 Employee Voice questions
- 5 intelligence metric bindings
- structured reason library
- extra Employee Voice metric: manager expectation clarity
- QA roster with finalized and open reviews for Master/People/Depth Chart testing

River Birch should run the SAME CTOD application/engine as 001 with different tenant configuration only. No custom fork.

Next River Birch infrastructure step: connect the isolated `ctod-sandbox` Vercel project to `sandbox.ctodsystem.com` and ensure that deployment points only to the separate CTOD Sandbox Supabase project. Then complete live browser QA end to end before onboarding the real buyer.

## 7. Immediate next-session priorities

1. Verify GitHub `main`, Production Vercel, `ctod-sandbox`, Production Supabase, and CTOD Sandbox Supabase.
2. Verify `app.ctodsystem.com` login, logout, invite activation, password reset, PDF download, and portrait print against 001 without changing 001 data.
3. Connect `sandbox.ctodsystem.com` to the isolated Sandbox Vercel project via DNS.
4. Finish River Birch live Sandbox customer QA: login -> review -> configurable Employee Voice -> save -> finalization -> Master/People Pulse -> Depth Chart -> professional summary -> PDF/print.
5. Confirm the new manager-expectation-clarity metric appears through metadata-driven Master/Summary pathways without customer-specific source code.
6. Build/finish Owner provisioning and version-management workflow: template -> customer -> locations -> roles/questions -> Sandbox -> approve -> Production -> rollback.
7. After River Birch passes without custom code, prepare its real customer onboarding and invite flow.

## 8. Product direction

CTOD is one multi-tenant SaaS engine across industries. Commercial Tire, landscaping, restaurants, and future industries must use the same application version and schema architecture. Customer differences belong in configuration/versioned templates, not source-code forks.

The post-pilot goal is no longer proving a single review workflow. The goal is proving repeatable customer provisioning, configuration, upgrade safety, and release management.
