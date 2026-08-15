# CTOD PDF Export System Contract 1.0

Applies to all tenants, locations, managers, employees, and finalized review summaries.

## Required output
- Exactly two PDF pages for the CTOD review summary.
- Letter portrait page size, one review page per PDF page.
- Download PDF and Print 2 Portrait Pages must use the same generated PDF.
- Export must preserve the approved on-screen summary design and spacing.
- The export renderer must use a fixed 816 x 1056 pixel capture frame corresponding to Letter portrait at 96 DPI.
- CTOD branding must render at a fixed bounded size and may not expand based on SVG intrinsic dimensions.
- Export must not rely on the live browser viewport, browser zoom, app container width, or printer driver to determine page layout.
- No two-up, landscape, fit-to-sheet, or browser HTML print interpretation is allowed in the CTOD-generated PDF.

## Regression gate
Before promotion, verify:
1. summary preview shows two portrait pages;
2. Download PDF yields exactly two portrait pages;
3. header dimensions match the preview;
4. question/rating/reason/note spacing is preserved;
5. page 2 career, voice, compensation and acknowledgment remain readable;
6. the same renderer works without employee-, manager-, location-, or tenant-specific code.
