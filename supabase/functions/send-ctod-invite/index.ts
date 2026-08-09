import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

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

    const { invite_id } = await req.json();
    const { data: inv, error: invErr } = await admin
      .from("access_invites")
      .select("id,company_id,email,intended_role,token,accepted_at,revoked_at,expires_at,invited_by_user_id")
      .eq("id", invite_id)
      .single();
    if (invErr || !inv) throw new Error("Invite not found");

    const { data: ownerMembership } = await admin
      .from("company_memberships")
      .select("role,active")
      .eq("company_id", inv.company_id)
      .eq("user_id", user.id)
      .eq("active", true)
      .maybeSingle();
    if (!ownerMembership || !["owner", "admin"].includes(ownerMembership.role)) {
      return json({ error: "Owner/Admin access required" }, 403);
    }

    if (inv.accepted_at || inv.revoked_at || new Date(inv.expires_at) <= new Date()) {
      throw new Error("Invite is no longer active");
    }

    const { data: locs, error: locErr } = await admin
      .from("access_invite_locations")
      .select("location_id")
      .eq("invite_id", inv.id);
    if (locErr) throw locErr;

    const normalized = String(inv.email).trim().toLowerCase();
    const inviteUrl = `https://ctod.vercel.app/?invite=${inv.token}`;

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
      if (activeMembership) {
        const { error: memErr } = await admin.from("company_memberships").upsert(
          {
            company_id: inv.company_id,
            user_id: existing.id,
            role: inv.intended_role,
            location_id: null,
            active: true,
          },
          { onConflict: "company_id,user_id" },
        );
        if (memErr) throw memErr;

        const now = new Date().toISOString();
        const { error: disableErr } = await admin
          .from("user_location_access")
          .update({ active: false, revoked_at: now })
          .eq("company_id", inv.company_id)
          .eq("user_id", existing.id)
          .eq("active", true);
        if (disableErr) throw disableErr;

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

        await admin.from("access_invites").update({ accepted_at: now }).eq("id", inv.id);
        await admin.from("audit_events").insert({
          company_id: inv.company_id,
          actor_user_id: user.id,
          event_type: "access.existing_user_updated",
          entity_type: "user",
          entity_id: existing.id,
          after_json: {
            role: inv.intended_role,
            invite_id: inv.id,
            locations: (locs || []).map((x: any) => x.location_id),
          },
        });

        return json({
          ok: true,
          existing_user_updated: true,
          onboarding_required: false,
          email_sent: false,
          email: normalized,
          role: inv.intended_role,
          location_count: (locs || []).length,
        });
      }

      // Auth record exists, but the person has not finished CTOD onboarding yet.
      // Keep the access invite pending and send them back through CTOD to create a password.
      const { error: recoveryErr } = await admin.auth.resetPasswordForEmail(inv.email, {
        redirectTo: inviteUrl,
      });
      if (recoveryErr) {
        return json({
          ok: true,
          existing_user_updated: false,
          onboarding_required: true,
          email_sent: false,
          invite_url: inviteUrl,
          message: recoveryErr.message,
        });
      }

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
        },
      });

      return json({
        ok: true,
        existing_user_updated: false,
        onboarding_required: true,
        email_sent: true,
        email: normalized,
        invite_url: inviteUrl,
      });
    }

    const { data: inviteData, error: emailErr } = await admin.auth.admin.inviteUserByEmail(inv.email, {
      redirectTo: inviteUrl,
    });
    if (emailErr) {
      return json({
        ok: true,
        email_sent: false,
        existing_user_updated: false,
        onboarding_required: true,
        invite_url: inviteUrl,
        message: emailErr.message,
      });
    }

    return json({
      ok: true,
      email_sent: true,
      existing_user_updated: false,
      onboarding_required: true,
      invite_url: inviteUrl,
      auth_user_id: inviteData?.user?.id || null,
    });
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : String(e) }, 400);
  }
});
