# CTOD Branded Domain Plan

Status: PURCHASE REQUIRED BEFORE IMPLEMENTATION

## Locked customer-facing domain plan

- Primary CTOD customer application: `https://ctod.app`
- CTOD Platform Owner application: `https://owner.ctod.app`
- Vercel remains the hosting layer only and should not appear in customer-facing links once the branded domain is connected.

## Manual prerequisite

`ctod.app` was verified available through Vercel at $9.99/year on 2026-08-14. The CTOD owner must purchase the domain before final wiring can be completed.

## After purchase, complete all of the following

1. Attach `ctod.app` to the Production customer Vercel project.
2. Attach `owner.ctod.app` to the Production Owner Platform project.
3. Configure DNS and verify SSL certificates.
4. Update Supabase Auth Site URL and allowed redirect URLs to the branded domains.
5. Update all invitation, password reset, recovery, magic-link, and authentication callback URLs.
6. Replace any hard-coded `*.vercel.app` customer-facing links in CTOD application code and documentation.
7. Add canonical redirects so old Vercel production URLs redirect to the branded CTOD domains where appropriate.
8. Validate login, invite activation, password reset, manager workspace, customer master, and Owner Platform flows end-to-end.
9. Keep Vercel deployment URLs as infrastructure/debug addresses only.

## Commercial rule

Customers should never need to know CTOD is hosted on Vercel or backed by Supabase. The professional product identity begins at `ctod.app`.
