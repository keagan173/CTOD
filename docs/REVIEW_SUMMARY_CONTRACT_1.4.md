# CTOD Two-Page Review Summary Contract 1.4

The finalized review summary is a product output, not an ad-hoc PDF.

Locked rules:
- Exactly two Letter portrait pages.
- Tenant/company name comes from the review's company record and appears above employee information on both pages.
- Page 1 contains employee identity, review KPIs, strengths/development highlights, and performance detail.
- Page 2 contains career direction, readiness, next-year goal, Employee Voice, compensation, goals/coaching when present, acknowledgment, and signatures.
- Manager Summary and Employee Comments are not rendered because those fields are not part of the approved 001 review UI.
- Employee acknowledgment language states that signing means the employee agrees with the review information.
- Existing finalized history is immutable; re-generating a summary uses the current approved renderer against the stored finalized review data.
- Summary data is supplied through `public.get_review_summary_payload(review_id)` so customer identity is tenant-aware and not hard-coded.
