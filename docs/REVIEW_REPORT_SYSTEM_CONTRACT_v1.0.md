# CTOD Review Report System Contract v1.0

## Purpose
Finalized CTOD reviews must produce one professional adaptive portrait report regardless of employee, role, manager, location, tenant, coaching volume, goal volume, development volume, or report length.

## Single Owner
`public/review-report-system.js` is the only active finalized-review summary/export owner loaded by `public/index.html`.

Legacy modules `review-summary-v2.js`, `review-summary-polish.js`, `review-summary-adaptive.js`, and `review-pdf-export.js` must not be loaded by the customer workspace.

The canonical report owner intercepts `#previewSummary` before the legacy `app.js` target handler can execute.

## Lifecycle
Finalized review data -> canonical report model -> adaptive portrait pages -> canonical raster artifact -> PDF or Print.

The polished report must be complete before any export action is available. Export actions must never mutate or repair the report design.

## Controls
The report always exposes three distinct controls:
1. Download PDF
2. Print Portrait Report
3. Back to Review

A combined `Print / Save PDF` control is prohibited.

## Adaptive Pagination
- Letter portrait pages only: 8.5 x 11 inches.
- Page count is not fixed.
- Long development, goals, or coaching sections add pages.
- Individual review/coaching/goal items move to the next page rather than overlap or clip.
- Acknowledgment and signature lines remain at the end of the report and above the footer.
- Each page is numbered `Page X of Y`.

## Performance Summary
- Key Strengths use the approved stacked format: Question -> Rating -> Reason -> Manager note.
- Performance Detail is not duplicated.
- Manager Summary and Employee Comments are not rendered in the finalized report.

## Employee / Career Data
The report includes company, employee identity, role, location, employee number, review date, overall rating, readiness, next review date, career direction, path reason, next desired role, long-term role, readiness, next-year goal, Employee Voice, relocation openness, compensation discussion, goals, included coaching, acknowledgment, and signatures when present in the canonical payload.

## PDF Artifact
- PDF pages are Letter portrait.
- Every report page becomes exactly one PDF page.
- Download PDF uses the canonical page artifact, not browser HTML printing.

## Print Artifact
- Print Portrait Report uses the same canonical page images as Download PDF.
- Print source contains one 8.5 x 11 portrait sheet per report page with a forced page break after each sheet.
- Print does not use popup tabs and does not call the legacy `window.print()` flow on the customer workspace.

## Safety / Scale
- No MutationObservers or polling loops are permitted in the report/export lifecycle.
- Repeated clicks must not create duplicate owners or duplicate event handlers.
- Report generation must not alter finalized review history.
- Tenant isolation and authorized data scope remain unchanged.

## Release Gate
A report-system release must verify:
- Sandbox branch is based on current `main`.
- Sandbox Vercel check is green.
- Old report modules are absent from `index.html` imports.
- Separate Download PDF and Print Portrait Report controls exist.
- No `Print / Save PDF` control exists in the active report module.
- Production is promoted only from the exact tested Sandbox commit.