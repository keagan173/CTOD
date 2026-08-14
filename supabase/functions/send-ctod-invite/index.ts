import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2.112.2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const DEFAULT_APP_URL = "https://ctod.vercel.app/";
const DEFAULT_FROM = "CTOD <invites@ctodsystem.com>";
const DEFAULT_PRODUCTION_PROJECT_REF = "wezcuprboyvbmlnuqdoi";
const CTOD_SANDBOX_PROJECT_REF = "zgwkjyezpgboysiklodj";
const BUILT_IN_SANDBOX_EMAILS = new Set([
  "sandbox-master@ctod.test",
  "sandbox-operator@ctod.test",
  "sandbox-customer-owner@ctod.test",
]);

function currentProjectRef() {
  const url = new URL(Deno.env.get("SUPABASE_URL") || "https://invalid.supabase.co");
  return url.hostname.match(/^([a-z0-9-]+)\.supabase\.co$/i)?.[1] || "";
}

function ctodEnvironment() {
  const configured = String(Deno.env.get("CTOD_ENVIRONMENT") || "").trim().toLowerCase();
  if (configured && !["production", "sandbox"].includes(configured)) {
    throw new Error("CTOD_ENVIRONMENT must be production or sandbox");
  }
  if (configured) return configured;
  const productionRef = Deno.env.get("CTOD_PRODUCTION_PROJECT_REF") || DEFAULT_PRODUCTION_PROJECT_REF;
  return currentProjectRef() === productionRef ? "production" : "sandbox";
}

function assertSandboxEmailAllowed(email: string) {
  if (ctodEnvironment() !== "sandbox") return;
  const normalized = email.trim().toLowerCase();
  const allowed = String(Deno.env.get("CTOD_EMAIL_ALLOWLIST") || "")
    .split(",")
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean);
  const builtInAllowed =
    currentProjectRef() === CTOD_SANDBOX_PROJECT_REF && BUILT_IN_SANDBOX_EMAILS.has(normalized);
  if (!allowed.includes(normalized) && !builtInAllowed) {
    throw new Error(
      allowed.length
        ? "Sandbox email blocked. Use an approved test address."
        : "Sandbox email delivery is disabled until CTOD_EMAIL_ALLOWLIST is configured.",
    );
  }
}

function escapeHtml(value: unknown) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function humanizeRole(value: unknown) {
  return String(value ?? "manager")
    .replaceAll("_", " ")
    .replace(/\b\w/g, (character) => character.toUpperCase());
}

function buildInviteUrl(token: string) {
  const configured =
    Deno.env.get("CTOD_APP_URL") || (ctodEnvironment() === "production" ? DEFAULT_APP_URL : "");
  if (!configured) throw new Error("Sandbox invitation URL is not configured");
  const appUrl = new URL(configured);
  if (appUrl.protocol !== "https:") throw new Error("CTOD_APP_URL must use HTTPS");
  appUrl.pathname = "/";
  appUrl.search = "";
  appUrl.hash = "";
  appUrl.searchParams.set("invite", token);
  return appUrl.toString();
}

function buildInviteEmail({
  inviteUrl,
  role,
  locations,
  expiresAt,
}: {
  inviteUrl: string;
  role: string;
  locations: string[];
  expiresAt: string;
}) {
  const roleLabel = humanizeRole(role);
  const locationLabel = locations.length ? locations.join(", ") : "your assigned CTOD workspace";
  const expiryLabel = new Date(expiresAt).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
    timeZone: "America/Denver",
  });
  const subjectLocation = locations.length === 1 ? ` — ${locations[0]}` : "";
  const safeUrl = escapeHtml(inviteUrl);

  return {
    subject: `${ctodEnvironment() === "sandbox" ? "[CTOD SANDBOX] " : ""}Your CTOD ${roleLabel} invitation${subjectLocation}`,
    text: [
      "You have been invited to CTOD.",
      "",
      `Role: ${roleLabel}`,
      `Access: ${locationLabel}`,
      "",
      "Create your password and activate access:",
      inviteUrl,
      "",
      `This invitation expires ${expiryLabel}.`,
      "If you were not expecting this invitation, you can ignore this email.",
    ].join("\n"),
    html: `<!doctype html>
<html lang="en">
  <body style="margin:0;background:#06111f;color:#eaf3f8;font-family:Arial,Helvetica,sans-serif">
    <div style="display:none;max-height:0;overflow:hidden">Create your CTOD password and activate ${escapeHtml(locationLabel)} access.</div>
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#06111f;padding:32px 12px">
      <tr><td align="center">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:560px;background:#0b1f33;border:1px solid #28506b;border-radius:16px;overflow:hidden">
          <tr><td style="padding:30px 32px 18px;text-align:center;border-bottom:1px solid #22445c">
            <div style="font-size:34px;font-weight:900;letter-spacing:4px;color:#e0b23d">CTOD</div>
            <div style="margin-top:7px;font-size:11px;font-weight:700;letter-spacing:2px;color:#9db4c4">BUILDING PEOPLE. DRIVING PERFORMANCE.</div>
          </td></tr>
          <tr><td style="padding:30px 32px">
            <h1 style="margin:0 0 14px;font-size:24px;line-height:1.25;color:#ffffff">You have been invited</h1>
            <p style="margin:0 0 22px;color:#bfd0dc;font-size:15px;line-height:1.6">Create your password to activate your CTOD access.</p>
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin:0 0 24px;background:#081827;border:1px solid #23465f;border-radius:12px">
              <tr><td style="padding:14px 16px;color:#8ca8ba;font-size:12px">ROLE</td><td style="padding:14px 16px;text-align:right;color:#ffffff;font-size:14px;font-weight:700">${escapeHtml(roleLabel)}</td></tr>
              <tr><td style="padding:14px 16px;border-top:1px solid #1f3c51;color:#8ca8ba;font-size:12px">ACCESS</td><td style="padding:14px 16px;border-top:1px solid #1f3c51;text-align:right;color:#ffffff;font-size:14px;font-weight:700">${escapeHtml(locationLabel)}</td></tr>
            </table>
            <div style="text-align:center;margin:28px 0">
              <a href="${safeUrl}" style="display:inline-block;background:#d8aa35;color:#07111d;text-decoration:none;font-size:15px;font-weight:900;padding:14px 24px;border-radius:10px">Create Password &amp; Open CTOD</a>
            </div>
            <p style="margin:0;color:#8ea8ba;font-size:12px;line-height:1.6;text-align:center">This invitation expires ${escapeHtml(expiryLabel)}. If you were not expecting it, you can ignore this email.</p>
          </td></tr>
        </table>
      </td></tr>
    </table>
  </body>
</html>`,
  };
}

async function sendInviteEmail({
  inviteId,
  deliveryRequestId,
  to,
  inviteUrl,
  role,
  locations,
  expiresAt,
}: {
  inviteId: string;
  deliveryRequestId: string;
  to: string;
  inviteUrl: string;
  role: string;
  locations: string[];
  expiresAt: string;
}) {
  const apiKey = Deno.env.get("RESEND_API_KEY");
  if (!apiKey) throw new Error("CTOD invitation email is not configured");

  const email = buildInviteEmail({ inviteUrl, role, locations, expiresAt });
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "Idempotency-Key": `ctod-access-invite-${inviteId}-${deliveryRequestId}`,
    },
    body: JSON.stringify({
      from: Deno.env.get("CTOD_INVITE_FROM") || DEFAULT_FROM,
      to: [to],
      subject: email.subject,
      html: email.html,
      text: email.text,
      tags: [
        { name: "category", value: "access_invite" },
        { name: "application", value: "ctod" },
      ],
    }),
  });

  const result: any = await response.json().catch(() => ({}));
  if (!response.ok) {
    const providerMessage = typeof result?.message === "string" ? result.message : "Email provider rejected the request";
    throw new Error(`CTOD invitation email failed: ${providerMessage}`);
  }
  if (!result?.id) throw new Error("CTOD invitation email did not return a delivery ID");
  return String(result.id);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...cors, "content-type": "application/json" },
    });

  try {
    const jwt = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
    const url = Deno.env.get("SUPABASE_URL")!;
    const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(url, service, {
      auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    });

    const {
      data: { user },
      error: userErr,
    } = await admin.auth.getUser(jwt);
    if (userErr || !user) return json({ error: "Authentication required" }, 401);

    const body = await req.json();
    const invite_id = String(body?.invite_id || "");
    const suppliedRequestId = String(body?.delivery_request_id || "");
    const deliveryRequestId = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(suppliedRequestId)
      ? suppliedRequestId.toLowerCase()
      : crypto.randomUUID();
    const { data: inv, error: invErr } = await admin
      .from("access_invites")
      .select("id,company_id,email,intended_role,token,accepted_at,revoked_at,expires_at,invited_by_user_id")
      .eq("id", invite_id)
      .single();
    if (invErr || !inv) throw new Error("Invite not found");

    const { data: company, error: companyErr } = await admin
      .from("companies")
      .select("status")
      .eq("id", inv.company_id)
      .single();
    if (companyErr || !company) throw new Error("Customer not found");
    if (company.status !== "active") return json({ error: "Customer access is suspended" }, 409);

    const { data: ownerMembership } = await admin
      .from("company_memberships")
      .select("role,active")
      .eq("company_id", inv.company_id)
      .eq("user_id", user.id)
      .eq("active", true)
      .maybeSingle();
    let authorized = !!ownerMembership && ["owner", "admin"].includes(ownerMembership.role);
    if (!authorized) {
      const { data: operator } = await admin.rpc("operator_service_authorize", { p_user_id: user.id });
      authorized = ["platform_admin", "support"].includes(String(operator?.role || ""));
    }
    if (!authorized) return json({ error: "Owner/Admin or operator access required" }, 403);

    if (inv.accepted_at || inv.revoked_at || new Date(inv.expires_at) <= new Date()) {
      throw new Error("Invite is no longer active");
    }

    const { data: locs, error: locErr } = await admin
      .from("access_invite_locations")
      .select("location_id,locations(location_code,name)")
      .eq("invite_id", inv.id);
    if (locErr) throw locErr;

    const normalized = String(inv.email).trim().toLowerCase();
    assertSandboxEmailAllowed(normalized);
    const inviteUrl = buildInviteUrl(String(inv.token));
    const locationLabels = (locs || []).map((row: any) => {
      const location = Array.isArray(row.locations) ? row.locations[0] : row.locations;
      if (!location) return "Assigned location";
      const code = String(location.location_code || "").padStart(3, "0");
      return `Location ${code} · ${location.name || "CTOD"}`;
    });

    const { data: list, error: listErr } = await admin.auth.admin.listUsers({ page: 1, perPage: 1000 });
    if (listErr) throw listErr;
    const existing = list.users.find((u: any) => String(u.email || "").toLowerCase() === normalized);

    if (existing) {
      const { data: activeMembership, error: activeMembershipErr } = await admin
        .from("company_memberships")
        .select("role,active")
        .eq("company_id", inv.company_id)
        .eq("user_id", existing.id)
        .eq("active", true)
        .maybeSingle();
      if (activeMembershipErr) throw activeMembershipErr;

      // A real, already-onboarded CTOD user gets access updated without creating a second account.
      // Existing location grants are additive: granting one new store must never silently remove
      // access to other stores. Company-wide roles are never downgraded by a location invite.
      if (activeMembership) {
        const now = new Date().toISOString();
        const companyWide = ["owner", "admin", "executive"].includes(activeMembership.role);

        if (!companyWide) {
          for (const l of locs || []) {
            const { error: accErr } = await admin.from("user_location_access").upsert(
              {
                company_id: inv.company_id,
                user_id: existing.id,
                location_id: l.location_id,
                access_role: inv.intended_role,
                active: true,
                revoked_at: null,
                granted_by_user_id: user.id,
                granted_at: now,
              },
              { onConflict: "user_id,location_id" },
            );
            if (accErr) throw accErr;
          }

          let effectiveRole = inv.intended_role;
          if (inv.intended_role !== "executive") {
            const { data: activeAccess, error: activeAccessErr } = await admin
              .from("user_location_access")
              .select("access_role")
              .eq("company_id", inv.company_id)
              .eq("user_id", existing.id)
              .eq("active", true);
            if (activeAccessErr) throw activeAccessErr;
            const roles = new Set((activeAccess || []).map((row: any) => row.access_role));
            effectiveRole = roles.has("area_leader")
              ? "area_leader"
              : roles.has("market_leader")
                ? "market_leader"
                : roles.has("manager")
                  ? "manager"
                  : "viewer";
          }

          const { error: memErr } = await admin.from("company_memberships").update({
            role: effectiveRole,
            location_id: null,
            active: true,
          }).eq("company_id", inv.company_id).eq("user_id", existing.id);
          if (memErr) throw memErr;
        }

        await admin.from("access_invites").update({ accepted_at: now }).eq("id", inv.id);
        await admin.from("audit_events").insert({
          company_id: inv.company_id,
          actor_user_id: user.id,
          event_type: "access.existing_user_updated",
          entity_type: "user",
          entity_id: existing.id,
          after_json: {
            role: companyWide ? activeMembership.role : inv.intended_role,
            invite_id: inv.id,
            locations: (locs || []).map((x: any) => x.location_id),
            mode: companyWide ? "already_company_wide" : "additive",
          },
        });

        return json({
          ok: true,
          existing_user_updated: true,
          onboarding_required: false,
          email_sent: false,
          email: normalized,
          role: companyWide ? activeMembership.role : inv.intended_role,
          location_count: (locs || []).length,
          already_company_wide: companyWide,
        });
      }

      // An Auth record may exist before CTOD onboarding is complete. Send the same branded,
      // token-based CTOD invitation in both cases; never route a manager through a raw
      // Supabase recovery email or an Auth redirect URL.
      const deliveryId = await sendInviteEmail({
        inviteId: inv.id,
        deliveryRequestId,
        to: normalized,
        inviteUrl,
        role: inv.intended_role,
        locations: locationLabels,
        expiresAt: inv.expires_at,
      });

      await admin.from("audit_events").insert({
        company_id: inv.company_id,
        actor_user_id: user.id,
        event_type: "access.onboarding_email_resent",
        entity_type: "user",
        entity_id: existing.id,
        after_json: {
          role: inv.intended_role,
          invite_id: inv.id,
          locations: (locs || []).map((x: any) => x.location_id),
          provider: "resend",
          delivery_id: deliveryId,
          delivery_request_id: deliveryRequestId,
        },
      });

      return json({
        ok: true,
        existing_user_updated: false,
        onboarding_required: true,
        email_sent: true,
        email: normalized,
        invite_url: inviteUrl,
        delivery_id: deliveryId,
      });
    }

    const deliveryId = await sendInviteEmail({
      inviteId: inv.id,
      deliveryRequestId,
      to: normalized,
      inviteUrl,
      role: inv.intended_role,
      locations: locationLabels,
      expiresAt: inv.expires_at,
    });

    await admin.from("audit_events").insert({
      company_id: inv.company_id,
      actor_user_id: user.id,
      event_type: "access.onboarding_email_sent",
      entity_type: "access_invite",
      entity_id: inv.id,
      after_json: {
        role: inv.intended_role,
        invite_id: inv.id,
        locations: (locs || []).map((x: any) => x.location_id),
        provider: "resend",
        delivery_id: deliveryId,
        delivery_request_id: deliveryRequestId,
      },
    });

    return json({
      ok: true,
      email_sent: true,
      existing_user_updated: false,
      onboarding_required: true,
      invite_url: inviteUrl,
      delivery_id: deliveryId,
    });
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : String(e) }, 400);
  }
});
