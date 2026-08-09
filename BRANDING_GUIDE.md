# CTOD Branding Guide

## Primary identity

**Logo 1 — Infinity CTOD** is the official primary CTOD logo.

File: `public/branding/ctod-logo-1-primary.svg`

Use it for:
- Application header / top-left primary identity
- Sign-in and welcome screens
- Master workbook cover/home page
- Location workbook cover/home page
- Printable executive summaries
- Formal CTOD documents and presentations

The primary tagline is:

**BUILDING PEOPLE. DRIVING PERFORMANCE.**

Secondary brand line:

**INSIGHT • DEVELOPMENT • RESULTS**

## Supporting marks

### Logo 2 — People Shield
File: `public/branding/ctod-logo-2-people-shield.svg`

Use for people, succession, leadership, employee development and Master talent intelligence. It may appear as a supporting watermark or section mark, but must never replace Logo 1 as the main application identity.

### Logo 3 — City Ring
File: `public/branding/ctod-logo-3-city-ring.svg`

Use for reviews, locations, organizational footprint and location-level reporting.

### Logo 4 — Performance Mark
File: `public/branding/ctod-logo-4-performance-mark.svg`

Use for performance, test/QA, goals, scorecards and operational-performance sections.

## Web placement rules

1. Logo 1 is displayed in a dedicated application brand bar above the dashboard title and navigation.
2. Supporting logos must never be absolutely positioned over buttons, dropdowns, badges, maps or data.
3. Supporting logos belong inside dedicated ribbons or safe watermark zones with reserved space.
4. Logo opacity must remain high enough to be intentional and recognizable; decorative marks should generally remain between 50% and 85% opacity.
5. Black and gold are the brand identity colors. Existing blue CTOD dashboard colors may remain as functional data/UI colors until a future full-theme conversion.
6. No page should contain more than one primary Logo 1 and one supporting mark in the initial viewport.

The production placement logic is implemented in `public/branding/ctod-branding.js`.

## Workbook placement rules

When Excel workbook artifacts are regenerated or revised:
- Put Logo 1 at the upper-left of `START HERE` / Home / Dashboard sheets.
- Use Logo 2 on succession, employee development and leadership sheets.
- Use Logo 3 on location and review-history sheets.
- Use Logo 4 on performance/test/reporting sheets.
- Maintain a black or dark graphite header band with gold accents around the logo.
- Never place a logo behind cell values, form controls or print-critical information.

Workbook branding is presentation-only. Employee identity, review logic and database architecture remain independent from branding assets so the same CTOD Core can support future Industry 002+ configurations.

## Source of truth

The `/public/branding/` directory is the source of truth for production CTOD logo assets. Do not embed ad-hoc screenshots or generated logo boards into the application. Use the individual production assets above.