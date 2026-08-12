import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2.112.2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const DEFAULT_PRODUCTION_PROJECT_REF = "wezcuprboyvbmlnuqdoi";
const CTOD_SANDBOX_PROJECT_REF = "zgwkjyezpgboysiklodj";
const BUILT_IN_SANDBOX_EMAILS = new Set([
  "sandbox-master@ctod.test",
  "sandbox-operator@ctod.test",
  "sandbox-customer-owner@ctod.test",
]);

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
});

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

type JsonRecord = Record<string, unknown>;

class HttpError extends Error {
  status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...cors,
      "content-type": "application/json",
      "cache-control": "no-store, max-age=0",
      "x-content-type-options": "nosniff",
      "referrer-policy": "no-referrer",
    },
  });
}

function currentProjectRef() {
  return new URL(SUPABASE_URL).hostname.match(/^([a-z0-9-]+)\.supabase\.co$/i)?.[1] || "";
}

function ctodEnvironment() {
  const configured = String(Deno.env.get("CTOD_ENVIRONMENT") || "").trim().toLowerCase();
  if (configured && !["production", "sandbox"].includes(configured)) {
    throw new HttpError(500, "CTOD environment is invalid");
  }
  if (configured) return configured;
  const productionRef = Deno.env.get("CTOD_PRODUCTION_PROJECT_REF") || DEFAULT_PRODUCTION_PROJECT_REF;
  return currentProjectRef() === productionRef ? "production" : "sandbox";
}

function assertSandboxEmailAllowed(email: string) {
  if (ctodEnvironment() !== "sandbox") return;
  const normalized = email.trim().toLowerCase();
  const configured = new Set(
    String(Deno.env.get("CTOD_EMAIL_ALLOWLIST") || "")
      .split(",")
      .map((value) => value.trim().toLowerCase())
      .filter(Boolean),
  );
  const builtInAllowed = currentProjectRef() === CTOD_SANDBOX_PROJECT_REF && BUILT_IN_SANDBOX_EMAILS.has(normalized);
  if (!configured.has(normalized) && !builtInAllowed) {
    throw new HttpError(400, "Sandbox account creation blocked. Use an approved test address.");
  }
}

function textValue(value: unknown, name: string, { required = false, max = 5000 } = {}) {
  const result = String(value ?? "").trim();
  if (required && !result) throw new HttpError(400, `${name} is required`);
  if (result.length > max) throw new HttpError(400, `${name} is too long`);
  return result;
}

function emailValue(value: unknown, name = "Email") {
  const email = textValue(value, name, { required: true, max: 320 }).toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw new HttpError(400, `${name} is invalid`);
  return email;
}

function uuidValue(value: unknown, name: string) {
  const result = textValue(value, name, { required: true, max: 36 }).toLowerCase();
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/.test(result)) {
    throw new HttpError(400, `${name} is invalid`);
  }
  return result;
}

function integerValue(value: unknown, name: string, minimum: number, maximum: number) {
  const result = Number(value);
  if (!Number.isInteger(result) || result < minimum || result > maximum) {
    throw new HttpError(400, `${name} must be between ${minimum} and ${maximum}`);
  }
  return result;
}

function nullableIsoDate(value: unknown, name: string) {
  const result = textValue(value, name, { max: 64 });
  if (!result) return null;
  const parsed = new Date(result);
  if (Number.isNaN(parsed.getTime())) throw new HttpError(400, `${name} is invalid`);
  return parsed.toISOString();
}

function recordValue(value: unknown) {
  return value && typeof value === "object" && !Array.isArray(value) ? value as JsonRecord : {};
}

async function callRpc<T>(name: string, args: JsonRecord) {
  const { data, error } = await admin.rpc(name, args);
  if (error) {
    const status = /access required|administrator access required/i.test(error.message) ? 403 : 400;
    throw new HttpError(status, error.message);
  }
  return data as T;
}

async function authenticatedOperator(req: Request) {
  const jwt = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  if (!jwt) throw new HttpError(401, "Authentication required");
  const { data, error } = await admin.auth.getUser(jwt);
  if (error || !data.user) throw new HttpError(401, "Authentication required");
  const operator = await callRpc<JsonRecord | null>("operator_service_touch", { p_user_id: data.user.id });
  if (!operator) throw new HttpError(403, "Platform operator access required");
  return { jwt, user: data.user, operator };
}

async function listAuthUsers() {
  const users: Array<{ id: string; email?: string | null }> = [];
  for (let page = 1; page <= 20; page += 1) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 1000 });
    if (error) throw new HttpError(500, "Could not resolve account metadata");
    users.push(...data.users.map((user) => ({ id: user.id, email: user.email })));
    if (data.users.length < 1000) break;
  }
  return users;
}

async function authEmailMap(ids: string[]) {
  const wanted = new Set(ids.filter(Boolean));
  if (!wanted.size) return new Map<string, string>();
  const users = await listAuthUsers();
  return new Map(
    users
      .filter((user) => wanted.has(user.id))
      .map((user) => [user.id, String(user.email || "")]),
  );
}

async function enrichDashboard(value: unknown) {
  const dashboard = recordValue(value);
  const operators = Array.isArray(dashboard.operators) ? dashboard.operators.map(recordValue) : [];
  const emails = await authEmailMap(operators.map((operator) => String(operator.user_id || "")));
  dashboard.operators = operators.map((operator) => ({
    ...operator,
    email: emails.get(String(operator.user_id || "")) || null,
  }));
  return dashboard;
}

async function enrichDiagnostics(value: unknown) {
  const diagnostics = recordValue(value);
  const access = Array.isArray(diagnostics.access) ? diagnostics.access.map(recordValue) : [];
  const audit = Array.isArray(diagnostics.audit) ? diagnostics.audit.map(recordValue) : [];
  const releases = Array.isArray(diagnostics.release_history) ? diagnostics.release_history.map(recordValue) : [];
  const ids = [
    ...access.map((row) => String(row.user_id || "")),
    ...audit.map((row) => String(row.actor_user_id || "")),
    ...releases.map((row) => String(row.actor_user_id || "")),
  ];
  const emails = await authEmailMap(ids);
  diagnostics.access = access.map((row) => ({ ...row, email: emails.get(String(row.user_id || "")) || null }));
  diagnostics.audit = audit.map((row) => ({ ...row, actor_email: emails.get(String(row.actor_user_id || "")) || null }));
  diagnostics.release_history = releases.map((row) => ({ ...row, actor_email: emails.get(String(row.actor_user_id || "")) || null }));
  return diagnostics;
}

function inviteUrl(token: unknown) {
  const raw = ctodEnvironment() === "production"
    ? Deno.env.get("CTOD_APP_URL") || "https://ctod.vercel.app/"
    : Deno.env.get("CTOD_APP_URL") || "";
  if (!raw || !token) return null;
  const url = new URL(raw);
  if (url.protocol !== "https:") throw new HttpError(500, "CTOD application URL must use HTTPS");
  url.pathname = "/";
  url.search = "";
  url.hash = "";
  url.searchParams.set("invite", String(token));
  return url.toString();
}

async function sendProvisionedInvite(jwt: string, inviteId: string) {
  const response = await fetch(`${SUPABASE_URL}/functions/v1/send-ctod-invite`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${jwt}`,
      apikey: SERVICE_ROLE_KEY,
      "content-type": "application/json",
    },
    body: JSON.stringify({ invite_id: inviteId, delivery_request_id: crypto.randomUUID() }),
  });
  const result = await response.json().catch(() => ({}));
  if (!response.ok) {
    return { ok: false, error: textValue(recordValue(result).error, "Delivery error", { max: 1000 }) || "Invite delivery failed" };
  }
  return result;
}

async function findAuthUser(email: string) {
  const users = await listAuthUsers();
  return users.find((user) => String(user.email || "").toLowerCase() === email) || null;
}

async function handleAction(req: Request, action: string, payload: JsonRecord) {
  const identity = await authenticatedOperator(req);
  const requestId = crypto.randomUUID();

  if (action === "context") {
    return {
      ok: true,
      environment: ctodEnvironment(),
      project_ref: currentProjectRef(),
      operator: { ...identity.operator, email: identity.user.email || null },
      privacy_boundary: "Aggregate customer health and access-account metadata only. Employee identities and review content are excluded.",
    };
  }

  if (action === "dashboard") {
    const result = await callRpc<unknown>("operator_service_dashboard", { p_actor_user_id: identity.user.id });
    return { ok: true, request_id: requestId, dashboard: await enrichDashboard(result) };
  }

  if (action === "diagnostics") {
    const companyId = uuidValue(payload.company_id, "Company ID");
    const result = await callRpc<unknown>("operator_service_customer_diagnostics", {
      p_actor_user_id: identity.user.id,
      p_company_id: companyId,
      p_record: payload.record !== false,
    });
    return { ok: true, request_id: requestId, diagnostics: await enrichDiagnostics(result) };
  }

  if (action === "provision_customer") {
    const ownerEmail = textValue(payload.owner_email, "Owner email", { max: 320 });
    if (ownerEmail) assertSandboxEmailAllowed(emailValue(ownerEmail, "Owner email"));
    const result = recordValue(await callRpc<unknown>("operator_service_provision_customer", {
      p_actor_user_id: identity.user.id,
      p_name: textValue(payload.name, "Company name", { required: true, max: 160 }),
      p_slug: textValue(payload.slug, "Company slug", { required: true, max: 120 }).toLowerCase(),
      p_timezone: textValue(payload.timezone, "Timezone", { required: true, max: 100 }),
      p_owner_email: ownerEmail || null,
      p_plan_code: textValue(payload.plan_code, "Plan code", { required: true, max: 40 }).toLowerCase(),
      p_provisioning_key: textValue(payload.provisioning_key, "Provisioning key", { required: true, max: 200 }),
      p_trial_days: integerValue(payload.trial_days, "Trial days", 0, 365),
      p_request_id: requestId,
    }));
    const response: JsonRecord = {
      ok: true,
      request_id: requestId,
      customer: result,
      invite_url: inviteUrl(result.invite_token),
    };
    if (payload.send_owner_invite === true && result.invite_id) {
      response.invite_delivery = await sendProvisionedInvite(identity.jwt, String(result.invite_id));
    }
    return response;
  }

  if (action === "set_status") {
    const result = await callRpc<unknown>("operator_service_set_customer_status", {
      p_actor_user_id: identity.user.id,
      p_company_id: uuidValue(payload.company_id, "Company ID"),
      p_status: textValue(payload.status, "Status", { required: true, max: 20 }).toLowerCase(),
      p_reason: textValue(payload.reason, "Reason", { max: 1000 }) || null,
      p_request_id: requestId,
    });
    return { ok: true, request_id: requestId, customer: result };
  }

  if (action === "update_customer") {
    const result = await callRpc<unknown>("operator_service_update_customer", {
      p_actor_user_id: identity.user.id,
      p_company_id: uuidValue(payload.company_id, "Company ID"),
      p_plan_code: textValue(payload.plan_code, "Plan code", { required: true, max: 40 }).toLowerCase(),
      p_deployment_status: textValue(payload.deployment_status, "Deployment status", { required: true, max: 30 }),
      p_deployment_url: textValue(payload.deployment_url, "Deployment URL", { max: 500 }) || null,
      p_database_project_ref: textValue(payload.database_project_ref, "Database project reference", { max: 100 }) || null,
      p_backup_status: textValue(payload.backup_status, "Backup status", { required: true, max: 30 }),
      p_last_backup_at: nullableIsoDate(payload.last_backup_at, "Last backup time"),
      p_support_notes: textValue(payload.support_notes, "Support notes", { max: 5000 }) || null,
      p_request_id: requestId,
    });
    return { ok: true, request_id: requestId, customer: result };
  }

  if (action === "set_release") {
    const result = await callRpc<unknown>("operator_service_set_release", {
      p_actor_user_id: identity.user.id,
      p_company_id: uuidValue(payload.company_id, "Company ID"),
      p_action: textValue(payload.release_action, "Release action", { required: true, max: 20 }),
      p_version: textValue(payload.version, "Version", { max: 40 }) || null,
      p_reason: textValue(payload.reason, "Reason", { max: 1000 }) || null,
      p_request_id: requestId,
    });
    return { ok: true, request_id: requestId, release: result };
  }

  if (action === "create_operator") {
    const email = emailValue(payload.email);
    assertSandboxEmailAllowed(email);
    const password = textValue(payload.password, "Temporary password", { required: true, max: 200 });
    if (password.length < 14) throw new HttpError(400, "Temporary password must be at least 14 characters");
    if (await findAuthUser(email)) throw new HttpError(409, "An Auth account already exists for this email");
    const displayName = textValue(payload.display_name, "Display name", { required: true, max: 120 });
    const operatorRole = textValue(payload.operator_role, "Operator role", { required: true, max: 30 });
    const { data, error } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      app_metadata: { ctod_identity_type: "platform_operator" },
      user_metadata: { display_name: displayName },
    });
    if (error || !data.user) throw new HttpError(400, error?.message || "Could not create operator account");
    try {
      const operator = await callRpc<unknown>("operator_service_upsert_operator", {
        p_actor_user_id: identity.user.id,
        p_user_id: data.user.id,
        p_operator_role: operatorRole,
        p_display_name: displayName,
        p_active: true,
        p_request_id: requestId,
      });
      return { ok: true, request_id: requestId, operator: { ...recordValue(operator), email } };
    } catch (error) {
      await admin.auth.admin.deleteUser(data.user.id).catch(() => undefined);
      throw error;
    }
  }

  if (action === "update_operator") {
    const result = await callRpc<unknown>("operator_service_upsert_operator", {
      p_actor_user_id: identity.user.id,
      p_user_id: uuidValue(payload.user_id, "Operator user ID"),
      p_operator_role: textValue(payload.operator_role, "Operator role", { required: true, max: 30 }),
      p_display_name: textValue(payload.display_name, "Display name", { required: true, max: 120 }),
      p_active: payload.active !== false,
      p_request_id: requestId,
    });
    return { ok: true, request_id: requestId, operator: result };
  }

  throw new HttpError(404, "Operator action not found");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    if (!SERVICE_ROLE_KEY || !SUPABASE_URL) throw new HttpError(500, "Operator service is not configured");
    const url = new URL(req.url);
    const body = req.method === "POST" ? recordValue(await req.json().catch(() => ({}))) : {};
    const action = textValue(body.action || url.searchParams.get("action") || "dashboard", "Action", {
      required: true,
      max: 80,
    });
    const payload = req.method === "POST" ? body : Object.fromEntries(url.searchParams.entries());
    return json(await handleAction(req, action, payload));
  } catch (error) {
    const status = error instanceof HttpError ? error.status : 500;
    const message = error instanceof Error ? error.message : String(error);
    return json({ ok: false, error: status === 500 ? "Operator service failed" : message }, status);
  }
});
