# CTOD Domain Architecture Lock v1.0

Status: APPROVED / LOCKED
Date: 2026-08-20

## Production domain architecture

- `https://app.ctodsystem.com` — official customer CTOD application/login.
- `https://owner.ctodsystem.com` — CTOD Platform Owner control plane.
- `https://ctod.vercel.app` — temporary technical fallback only; not customer-facing branding.
- `https://ctodsystem.com` — reserved for the future public CTOD marketing/sales website.
- `https://sandbox.ctodsystem.com` — designated professional Sandbox hostname once DNS is connected to the isolated `ctod-sandbox` Vercel project.

## Verified production state

On 2026-08-20, `app.ctodsystem.com` was connected through GoDaddy DNS to Vercel, SSL completed, Vercel reported Valid Configuration, and Commercial Tire 001 successfully loaded its Production workspace on the new domain. The company map, Master workspace, navigation, authenticated LOC040 access, and existing customer data remained intact.

## Permanent rules

1. Paying customers use `app.ctodsystem.com`, not a `vercel.app` URL.
2. Platform Owner administration uses `owner.ctodsystem.com`.
3. Sandbox/testing must remain isolated from Production and should use `sandbox.ctodsystem.com` once connected.
4. Do not point Sandbox at Production Supabase.
5. Keep `ctod.vercel.app` available as a temporary fallback until canonical-domain redirects and authentication/reset flows have been fully validated on `app.ctodsystem.com`.
6. Future customers, including River Birch Landscaping, use the same `app.ctodsystem.com` entry point. Tenant, role, location, branding, questions, and configuration are resolved after authentication. Do not create customer-specific codebases or domains unless explicitly approved later.
7. The root `ctodsystem.com` remains reserved for a future public marketing site and should not be permanently consumed by the authenticated application.

## Release intent

After auth/password-reset/invite links are fully verified against `app.ctodsystem.com`, legacy customer-facing links should be updated to the canonical domain and direct `ctod.vercel.app` visits may redirect to `app.ctodsystem.com` while retaining the Vercel fallback at the infrastructure level.
