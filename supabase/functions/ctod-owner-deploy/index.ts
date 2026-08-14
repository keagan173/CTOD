import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2.112.2";

const url = Deno.env.get("SUPABASE_URL")!;
const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const admin = createClient(url, service, { auth: { persistSession: false, autoRefreshToken: false } });

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  "Access-Control-Allow-Methods": "POST,OPTIONS",
};

const out = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...cors, "content-type": "application/json", "cache-control": "no-store" },
});

async function owner(req: Request) {
  const jwt = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  if (!jwt) throw new Error("Authentication required");
  const { data, error } = await admin.auth.getUser(jwt);
  if (error || !data.user) throw new Error("Authentication required");
  const { data: op, error: oe } = await admin.schema("private").from("platform_operators")
    .select("user_id,operator_role,active,display_name")
    .eq("user_id", data.user.id).eq("active", true).maybeSingle();
  if (oe || !op || op.operator_role !== "platform_admin") throw new Error("Platform Owner access required");
  return { user: data.user, op, jwt };
}

const id = (v: unknown) => {
  const s = String(v || "");
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(s)) throw new Error("Invalid ID");
  return s;
};
const ids = (v: unknown) => Array.isArray(v) ? v.map(id) : [];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const who = await owner(req);
    const b = await req.json().catch(() => ({}));
    const action = String(b.action || "home");

    if (action === "home") {
      const { data, error } = await admin.rpc("operator_service_dashboard", { p_actor_user_id: who.user.id });
      if (error) throw error;
      return out({ ok: true, owner_email: who.user.email, dashboard: data });
    }

    if (action === "security_review_status") {
      const { data, error } = await admin.rpc("operator_service_security_review_status", { p_actor_user_id: who.user.id });
      if (error) throw error;
      return out({ ok: true, security: data });
    }

    if (action === "platform_releases") {
      const { data, error } = await admin.rpc("operator_service_platform_releases", { p_actor_user_id: who.user.id });
      if (error) throw error;
      return out({ ok: true, releases: data });
    }

    if (action === "validate_platform_release") {
      const { data, error } = await admin.rpc("operator_service_validate_platform_release", {
        p_actor_user_id: who.user.id,
        p_release_id: id(b.release_id),
        p_source_commit_sha: String(b.source_commit_sha || ""),
        p_automated_tests_passed: !!b.automated_tests_passed,
        p_security_review_passed: !!b.security_review_passed,
        p_acceptance_test_passed: !!b.acceptance_test_passed,
        p_notes: String(b.notes || ""),
        p_request_id: crypto.randomUUID(),
      });
      if (error) throw error;
      return out({ ok: true, validation: data });
    }

    if (action === "approve_platform_release") {
      const reason = String(b.reason || "").trim();
      if (!reason) throw new Error("Approval reason is required");
      const { data, error } = await admin.rpc("operator_service_approve_platform_release", {
        p_actor_user_id: who.user.id,
        p_release_id: id(b.release_id),
        p_reason: reason,
        p_request_id: crypto.randomUUID(),
      });
      if (error) throw error;
      return out({ ok: true, release: data });
    }

    if (action === "schedule_platform_release") {
      const reason = String(b.reason || "").trim();
      if (!reason) throw new Error("Rollout reason is required");
      const { data, error } = await admin.rpc("operator_service_schedule_platform_release", {
        p_actor_user_id: who.user.id,
        p_release_id: id(b.release_id),
        p_company_ids: ids(b.company_ids),
        p_rollout_stage: String(b.rollout_stage || "selected"),
        p_reason: reason,
        p_request_id: crypto.randomUUID(),
      });
      if (error) throw error;
      return out({ ok: true, rollout: data });
    }

    if (action === "activate_platform_release") {
      const reason = String(b.reason || "").trim();
      if (!reason) throw new Error("Activation reason is required");
      const { data, error } = await admin.rpc("operator_service_activate_platform_release", {
        p_actor_user_id: who.user.id,
        p_release_id: id(b.release_id),
        p_company_ids: ids(b.company_ids),
        p_reason: reason,
        p_request_id: crypto.randomUUID(),
      });
      if (error) throw error;
      return out({ ok: true, rollout: data });
    }

    if (action === "rollback_platform_release") {
      const reason = String(b.reason || "").trim();
      if (!reason) throw new Error("Rollback reason is required");
      const { data, error } = await admin.rpc("operator_service_rollback_platform_release", {
        p_actor_user_id: who.user.id,
        p_release_id: id(b.release_id),
        p_company_ids: ids(b.company_ids),
        p_reason: reason,
        p_request_id: crypto.randomUUID(),
      });
      if (error) throw error;
      return out({ ok: true, rollout: data });
    }

    if (action === "create_industry_template") {
      const { data, error } = await admin.rpc("operator_service_create_industry_template", {
        p_actor_user_id: who.user.id,
        p_template_code: String(b.template_code || ""),
        p_name: String(b.name || ""),
        p_description: String(b.description || ""),
        p_request_id: crypto.randomUUID(),
      });
      if (error) throw error;
      return out({ ok: true, template: data });
    }

    if (action === "create_template_version") {
      let config = b.configuration;
      if (typeof config === "string") config = JSON.parse(config);
      const { data, error } = await admin.rpc("operator_service_create_template_version", {
        p_actor_user_id: who.user.id,
        p_template_id: id(b.template_id),
        p_version_code: String(b.version_code || ""),
        p_schema_version: String(b.schema_version || ""),
        p_configuration: config,
        p_minimum_client_version: String(b.minimum_client_version || ""),
        p_publish: !!b.publish,
        p_request_id: crypto.randomUUID(),
      });
      if (error) throw error;
      return out({ ok: true, template_version: data });
    }

    if (action === "provision_customer_v2") {
      const name = String(b.name || "").trim();
      const slug = String(b.slug || "").trim();
      const timezone = String(b.timezone || "America/Boise").trim();
      const plan = String(b.plan_code || "standard").trim();
      const template = String(b.template_code || "BLANK").trim();
      if (!name || !slug) throw new Error("Customer name and slug are required");
      const { data, error } = await admin.rpc("operator_service_provision_customer_v2", {
        p_actor_user_id: who.user.id,
        p_name: name,
        p_slug: slug,
        p_timezone: timezone,
        p_owner_email: String(b.owner_email || ""),
        p_plan_code: plan,
        p_provisioning_key: String(b.provisioning_key || crypto.randomUUID()),
        p_trial_days: Number(b.trial_days || 0),
        p_template_code: template,
        p_template_version_code: b.template_version_code ? String(b.template_version_code) : null,
        p_request_id: crypto.randomUUID(),
      });
      if (error) throw error;
      return out({ ok: true, customer: data });
    }

    const company = id(b.company_id);

    if (action === "status") {
      const { data: cfg, error } = await admin.rpc("operator_service_customer_configuration", {
        p_actor_user_id: who.user.id, p_company_id: company,
      });
      if (error) throw error;
      const draft = (cfg as any)?.draft_configuration;
      let validations: any[] = [];
      if (draft?.id) {
        const r = await admin.schema("private").from("customer_configuration_validations")
          .select("id,config_version_id,passed,checks,checksum,validated_at")
          .eq("company_id", company).eq("config_version_id", draft.id)
          .order("validated_at", { ascending: false }).limit(10);
        if (r.error) throw r.error;
        validations = r.data || [];
      }
      const h = await admin.schema("private").from("customer_configuration_release_history")
        .select("id,from_config_version_id,to_config_version_id,action,reason,created_at")
        .eq("company_id", company).order("created_at", { ascending: false }).limit(20);
      if (h.error) throw h.error;
      const versions = await admin.from("configuration_versions")
        .select("id,version_label,status,published_at,created_at")
        .eq("company_id", company).order("created_at", { ascending: false });
      if (versions.error) throw versions.error;
      const access = await admin.rpc("operator_service_customer_access", {
        p_actor_user_id: who.user.id, p_company_id: company,
      });
      return out({
        ok: true,
        configuration: cfg,
        validations,
        release_history: h.data || [],
        rollback_candidates: (versions.data || []).filter((v: any) => v.status === "retired" && v.published_at),
        access: access.data || null,
      });
    }

    if (action === "begin_customer_sandbox") {
      const { data, error } = await admin.rpc("operator_service_begin_configuration_draft", {
        p_actor_user_id: who.user.id,
        p_company_id: company,
        p_version_label: String(b.version_label || "").trim() || null,
        p_request_id: crypto.randomUUID(),
      });
      if (error) throw error;
      return out({ ok: true, configuration: data });
    }

    if (action === "mutate_customer_configuration") {
      const operation = String(b.operation || "").trim();
      if (!operation) throw new Error("Configuration operation is required");
      const payload = b.configuration_payload && typeof b.configuration_payload === "object" ? b.configuration_payload : {};
      const { data, error } = await admin.rpc("operator_service_mutate_configuration", {
        p_actor_user_id: who.user.id,
        p_company_id: company,
        p_operation: operation,
        p_payload: payload,
        p_request_id: crypto.randomUUID(),
      });
      if (error) throw error;
      return out({ ok: true, configuration: data });
    }

    if (action === "create_customer_invite") {
      const email = String(b.email || "").trim().toLowerCase();
      const role = String(b.customer_role || "executive").trim();
      if (!email) throw new Error("Invite email is required");
      const { data, error } = await admin.rpc("operator_service_create_customer_invite", {
        p_actor_user_id: who.user.id,
        p_company_id: company,
        p_email: email,
        p_role: role,
        p_location_ids: ids(b.location_ids),
        p_request_id: crypto.randomUUID(),
      });
      if (error) throw error;
      return out({ ok: true, invite: data });
    }

    if (action === "validate") {
      const { data, error } = await admin.rpc("operator_service_validate_configuration", {
        p_actor_user_id: who.user.id,
        p_company_id: company,
        p_config_version_id: id(b.config_version_id),
        p_request_id: crypto.randomUUID(),
      });
      if (error) throw error;
      return out({ ok: true, validation: data });
    }

    if (action === "promote") {
      const reason = String(b.reason || "").trim();
      if (!reason) throw new Error("Deployment reason is required");
      const { data, error } = await admin.rpc("operator_service_promote_configuration", {
        p_actor_user_id: who.user.id,
        p_company_id: company,
        p_config_version_id: id(b.config_version_id),
        p_reason: reason,
        p_request_id: crypto.randomUUID(),
      });
      if (error) throw error;
      return out({ ok: true, configuration: data });
    }

    if (action === "discard_draft") {
      const { data, error } = await admin.rpc("operator_service_discard_configuration_draft", {
        p_actor_user_id: who.user.id,
        p_company_id: company,
        p_config_version_id: id(b.config_version_id),
        p_reason: String(b.reason || "Discard owner sandbox draft"),
        p_request_id: crypto.randomUUID(),
      });
      if (error) throw error;
      return out({ ok: true, configuration: data });
    }

    if (action === "rollback") {
      const reason = String(b.reason || "").trim();
      if (!reason) throw new Error("Rollback reason is required");
      const { data, error } = await admin.rpc("operator_service_rollback_configuration", {
        p_actor_user_id: who.user.id,
        p_company_id: company,
        p_target_config_version_id: id(b.target_config_version_id),
        p_reason: reason,
        p_request_id: crypto.randomUUID(),
      });
      if (error) throw error;
      return out({ ok: true, configuration: data });
    }

    return out({ ok: false, error: "Unknown action" }, 404);
  } catch (e) {
    return out({ ok: false, error: e instanceof Error ? e.message : String(e) }, 400);
  }
});
