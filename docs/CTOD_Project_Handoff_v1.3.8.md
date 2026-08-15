# CTOD Project Handoff v1.3.8

Updated: 2026-08-15
Checkpoint: Commercial Tire 001 Review Summary / PDF / Print Stabilization

## LOCKED ARCHITECTURE
CTOD remains one commercial multi-tenant SaaS platform with Platform Owner control, private customer Company Masters, location workspaces, tenant isolation, preserved review/coaching/history, customer configuration/versioning, and non-destructive upgrades. Do not redesign this architecture.

## LOCKED RELEASE PIPELINE
- Vercel `ctod-sandbox` tracks Git branch `ctod-sandbox`.
- Vercel Production `ctod` tracks Git branch `main`.
- Required path remains: Sandbox build -> automatic Sandbox deploy -> validate real customer replica -> fix/retest -> approve -> promote exact tested code to `main` -> automatic Production deploy -> verify Production.
- Production customer workspaces are not the first QA target for feature work.

## COMMERCIAL TIRE 001 / LOC040
Commercial Tire remains reference tenant 001. LOC040 Meridian is the real pilot workspace. Noah Blythe's first finalized review is preserved and must not be recreated or overwritten. Finalized review data, employee voice answers, career direction, readiness, compensation discussion, ratings/reasons, notes, and history are saved.

## CUSTOMER WORKSPACE CONTRACT
Navigation remains locked as:

`Master | Reviews | Coaching | Employees | People | Review Schedule | Depth Chart`

Master remains first/default. Approved Master Presentation Mode, company-wide 55-location aggregate map, People Pulse, talent filters, question-level analytics, and Depth Chart lineage remain protected.

## REVIEW SUMMARY CONTENT CONTRACT
The finalized review summary must remain clean, modern, professional, resume/report quality, and adaptive to as many portrait pages as needed. Do NOT hard-limit the report to two pages.

The approved content includes:
- customer company name
- employee identity, role, location, employee number
- review date, overall rating, readiness, next review date
- Key Strengths with full question, rating, reason, and manager note when present
- Development Areas when present
- Career Direction
- Why this path
- desired next position
- desired long-term position
- manager readiness
- next-year goal
- Employee Voice
- compensation / raise discussion including employee timing, manager timing, and manager comment
- goals when present
- coaching included when present
- acknowledgment / agreement
- employee signature/date line
- manager signature/date line

Manager Summary and Employee Comments remain intentionally removed from the summary.

## APPROVED VISUAL STATE
The current adaptive report layout itself is considered visually approved when it renders in the polished report format:
- portrait Letter-style pages
- black/gold CTOD branding
- compact professional header
- strong section hierarchy
- labels separated from bold values
- Key Strengths stacked with question -> rating/reason -> manager note
- no overlap, clipping, or compressed unreadable text
- signatures protected above footer

Do not redesign this visual language during the next export fix.

## CURRENT CRITICAL DEFECT
As of this checkpoint, summary data/content is correct and the polished report can render correctly, but the output workflow is still inconsistent.

Observed current behavior from Production:
1. The on-screen summary can initially render in a degraded/unpolished legacy-looking layout.
2. Invoking Print can cause the polished layout to appear.
3. Browser printing can still place two portrait report pages side-by-side on a single landscape sheet / landscape-style print output instead of one portrait report page per physical sheet.
4. The UI has regressed to a combined `Print / Save PDF` action in some states. This is NOT the desired product behavior.
5. The final product must have TWO distinct actions:
   - `Download PDF`
   - `Print Portrait Report`
6. Download PDF must create the real adaptive report PDF directly without requiring Print first.
7. Print must print the same generated PDF/report one portrait page per sheet.
8. Printing must not mutate or improve the on-screen summary as a side effect. On-screen render, PDF generation, and print must all consume the same canonical finalized report model/layout.

## ROOT ARCHITECTURE RULE FOR NEXT FIX
Stop layering more DOM observers, legacy print handlers, or competing button owners.

There must be ONE canonical report pipeline:

`Finalized Review Data -> Canonical Report Model -> Canonical Adaptive Portrait Renderer -> PDF Artifact`

Then:
- `Download PDF` downloads that artifact.
- `Print Portrait Report` prints that SAME artifact one portrait page per sheet.

The browser print engine must not be responsible for deciding the document layout.

## REQUIRED NEXT-SESSION ENGINEERING PLAN
1. Verify `main`, `ctod-sandbox`, Vercel Production, and Sandbox before editing.
2. Audit and remove/disable every legacy summary/print owner that can still render `Print / Save PDF` or legacy summary HTML.
3. Identify the one canonical Generate Summary click owner and enforce single ownership.
4. Build a stable in-memory report model from finalized review data before touching DOM.
5. Render the polished adaptive report from that model once.
6. Generate PDF from the same model/render tree without using print as a prerequisite.
7. Restore two separate buttons: `Download PDF` and `Print Portrait Report`.
8. Print must consume the generated PDF artifact and guarantee portrait, one report page per physical sheet.
9. Add explicit output assertions/tests:
   - report renders polished before any print action
   - no legacy `Print / Save PDF` button
   - Download PDF succeeds independently
   - PDF page count equals adaptive report page count
   - every PDF page is portrait Letter
   - Print uses one report page per sheet
   - signatures remain visible and separate from footer
   - long coaching/goals/development content adds pages rather than clipping
10. Run controlled LOC040 Noah finalized-review QA in Sandbox end-to-end before promotion.
11. Only after visual and functional approval promote exact tested Sandbox build to `main`.

## CURRENT PRODUCTION CHECKPOINT
Last Production merge during this session: `38e968bdf048ed86459687c70a3f5ba2fcdb8b4e`.

Important: this commit does NOT mean PDF/Print is finished. Production still exhibits the output behavior documented above.

## GUARDRAILS
Do not:
- alter or erase Noah's finalized review
- destroy historical review/coaching data
- redesign multi-tenancy
- expose unauthorized employee detail
- remove manager readiness
- restore `A balance of both`
- downgrade approved Master / Presentation Mode
- hard-limit summaries to two pages
- use browser print layout as the canonical report generator
- allow multiple modules to own Generate Summary / Download PDF / Print actions
- fix the output defect by degrading the approved report design

## RESTART PHRASE
Resume CTOD build from Handoff v1.3.8 Commercial Tire 001 Review Summary / PDF / Print Stabilization checkpoint. Verify GitHub `main`, `ctod-sandbox`, Vercel Production, and Sandbox first. Preserve Noah Blythe's finalized LOC040 review and the approved adaptive professional report design. Fix the report architecture so the polished summary renders correctly before any export action, restore separate `Download PDF` and `Print Portrait Report` buttons, generate both from one canonical adaptive portrait report artifact, and guarantee one portrait report page per printed sheet. Remove all legacy/duplicate summary and print owners. Do not redesign locked multi-tenant architecture, Master Presentation Mode, history, Employee Voice, readiness, or intelligence features.
