import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2.112.2";

const DEFAULT_PRODUCTION_PROJECT_REF = "wezcuprboyvbmlnuqdoi";
const CTOD_SANDBOX_PROJECT_REF = "zgwkjyezpgboysiklodj";
const BUILT_IN_SANDBOX_EMAILS = new Set([
  "sandbox-master@ctod.test",
  "sandbox-operator@ctod.test",
  "sandbox-customer-owner@ctod.test",
]);
const url = Deno.env.get("SUPABASE_URL")!;
const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const admin = createClient(url, service, {
  auth: { autoRefreshToken: false, persistSession: false },
});
const cors = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "content-type, authorization, apikey",
  "access-control-allow-methods": "GET, POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "content-type": "application/json" },
  });

function currentProjectRef() {
  return new URL(url).hostname.match(/^([a-z0-9-]+)\.supabase\.co$/i)?.[1] || "";
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
        ? "Sandbox account creation blocked. Use an approved test address."
        : "Sandbox account creation is disabled until CTOD_EMAIL_ALLOWLIST is configured.",
    );
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    if (req.method === "GET") {
      const token = String(new URL(req.url).searchParams.get("token") || "");
      if (!token) return json({ ok: false, error: "Invite token required" }, 400);
      const { data: inv, error } = await admin
        .from("access_invites")
        .select("company_id,email,intended_role,accepted_at,revoked_at,expires_at")
        .eq("token", token)
        .maybeSingle();
      if (error) throw error;
      if (!inv) return json({ ok: false, error: "Invite is invalid" }, 404);
      assertSandboxEmailAllowed(String(inv.email));
      const { data: company, error: companyError } = await admin
        .from("companies")
        .select("status")
        .eq("id", inv.company_id)
        .single();
      if (companyError || !company) throw new Error("Customer not found");
      const expired = new Date(inv.expires_at) <= new Date();
      const customerActive = company.status === "active";
      return json({
        ok: true,
        email: inv.email,
        role: inv.intended_role,
        active: customerActive && !inv.accepted_at && !inv.revoked_at && !expired,
        accepted: !!inv.accepted_at,
        revoked: !!inv.revoked_at,
        expired,
        customer_active: customerActive,
        inactive_reason: customerActive ? null : "Customer access is suspended",
        expires_at: inv.expires_at,
      });
    }

    const body = await req.json();
    const token = String(body.token || "");
    const password = String(body.password || "");
    if (!token) throw new Error("Invite token required");
    if (password.length < 8) throw new Error("Password must be at least 8 characters");
    const { data: inv, error: inviteError } = await admin
      .from("access_invites")
      .select("id,company_id,email,intended_role,accepted_at,revoked_at,expires_at,invited_by_user_id")
      .eq("token", token)
      .maybeSingle();
    if (inviteError) throw inviteError;
    if (!inv || inv.accepted_at || inv.revoked_at || new Date(inv.expires_at) <= new Date()) {
      throw new Error("Invite is invalid or expired");
    }

    const { data: company, error: companyError } = await admin
      .from("companies")
      .select("status")
      .eq("id", inv.company_id)
      .single();
    if (companyError || !company) throw new Error("Customer not found");
    if (company.status !== "active") throw new Error("Customer access is suspended");

    const email = String(inv.email).trim().toLowerCase();
    assertSandboxEmailAllowed(email);
    const { data: list, error: listError } = await admin.auth.admin.listUsers({ page: 1, perPage: 1000 });
    if (listError) throw listError;
    let user = list.users.find((candidate: any) => String(candidate.email || "").toLowerCase() === email);
    if (user) {
      const { data: updated, error: updateError } = await admin.auth.admin.updateUserById(user.id, {
        password,
        email_confirm: true,
      });
      if (updateError) throw updateError;
      user = updated.user;
    } else {
      const { data: created, error: createError } = await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      });
      if (createError) throw createError;
      user = created.user;
    }

    const uid = user.id;
    const { error: profileError } = await admin
      .from("profiles")
      .upsert({ id: uid, display_name: email.split("@")[0] }, { onConflict: "id" });
    if (profileError) throw profileError;
    const { error: membershipError } = await admin.from("company_memberships").upsert(
      {
        company_id: inv.company_id,
        user_id: uid,
        role: inv.intended_role,
        location_id: null,
        active: true,
      },
      { onConflict: "company_id,user_id" },
    );
    if (membershipError) throw membershipError;

    const { data: locations, error: locationsError } = await admin
      .from("access_invite_locations")
      .select("location_id")
      .eq("invite_id", inv.id);
    if (locationsError) throw locationsError;
    const now = new Date().toISOString();
    const { error: revokeError } = await admin
      .from("user_location_access")
      .update({ active: false, revoked_at: now })
      .eq("company_id", inv.company_id)
      .eq("user_id", uid);
    if (revokeError) throw revokeError;
    for (const location of locations || []) {
      const { error: accessError } = await admin.from("user_location_access").upsert(
        {
          company_id: inv.company_id,
          user_id: uid,
          location_id: location.location_id,
          access_role: inv.intended_role,
          active: true,
          revoked_at: null,
          granted_by_user_id: inv.invited_by_user_id,
          granted_at: now,
        },
        { onConflict: "user_id,location_id" },
      );
      if (accessError) throw accessError;
    }
    const { error: acceptError } = await admin
      .from("access_invites")
      .update({ accepted_at: now })
      .eq("id", inv.id);
    if (acceptError) throw acceptError;
    return json({ ok: true, email, role: inv.intended_role, location_count: (locations || []).length });
  } catch (error) {
    return json({ ok: false, error: error instanceof Error ? error.message : String(error) }, 400);
  }
});
