const required = (name) => {
  const value = String(process.env[name] || '').trim();
  if (!value) throw new Error(`${name} is required.`);
  return value;
};

const supabaseUrl = new URL(required('CTOD_SUPABASE_URL'));
const secretKey = required('CTOD_SUPABASE_SECRET_KEY');
const productionRef = required('CTOD_PRODUCTION_PROJECT_REF');
const sandboxRef = required('CTOD_SANDBOX_PROJECT_REF');
const email = required('CTOD_SANDBOX_EMAIL').toLowerCase();
const password = required('CTOD_SANDBOX_PASSWORD');
const projectRef = supabaseUrl.hostname.match(/^([a-z0-9-]+)\.supabase\.co$/i)?.[1] || '';

if (projectRef !== sandboxRef || projectRef === productionRef) {
  throw new Error('Sandbox user bootstrap refused: project-ref guard failed.');
}
if (secretKey.startsWith('sb_publishable_')) {
  throw new Error('CTOD_SUPABASE_SECRET_KEY must be a server-side secret/service-role key.');
}
if (password.length < 16) throw new Error('CTOD_SANDBOX_PASSWORD must be at least 16 characters.');

const allowlist = required('CTOD_EMAIL_ALLOWLIST')
  .split(',')
  .map((value) => value.trim().toLowerCase())
  .filter(Boolean);
if (!allowlist.includes(email)) throw new Error('CTOD_SANDBOX_EMAIL is not allowlisted.');

async function request(path, { method = 'GET', body, prefer } = {}) {
  const response = await fetch(new URL(path, supabaseUrl), {
    method,
    headers: {
      apikey: secretKey,
      authorization: `Bearer ${secretKey}`,
      ...(body ? { 'content-type': 'application/json' } : {}),
      ...(prefer ? { prefer } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  const result = text ? JSON.parse(text) : null;
  if (!response.ok) {
    throw new Error(result?.message || result?.error_description || result?.error || `HTTP ${response.status}`);
  }
  return result;
}

const users = await request('/auth/v1/admin/users?page=1&per_page=50');
const memberships = await request('/rest/v1/company_memberships?select=id&limit=1');
if ((users?.users || []).length || memberships.length) {
  throw new Error('Sandbox user bootstrap is closed because an Auth user or membership already exists.');
}

let userId = '';
try {
  const user = await request('/auth/v1/admin/users', {
    method: 'POST',
    body: {
      email,
      password,
      email_confirm: true,
      app_metadata: { ctod_environment: 'sandbox' },
      user_metadata: { display_name: 'Sandbox Master' },
    },
  });
  userId = user.id;

  const [company] = await request('/rest/v1/companies?select=id&order=created_at.asc&limit=1');
  if (!company?.id) throw new Error('Sandbox company configuration is missing.');

  await request('/rest/v1/profiles?on_conflict=id', {
    method: 'POST',
    prefer: 'resolution=merge-duplicates,return=minimal',
    body: { id: userId, display_name: 'Sandbox Master' },
  });
  await request('/rest/v1/company_memberships?on_conflict=company_id,user_id', {
    method: 'POST',
    prefer: 'resolution=merge-duplicates,return=minimal',
    body: {
      company_id: company.id,
      user_id: userId,
      role: 'owner',
      location_id: null,
      active: true,
    },
  });
  await request('/rest/v1/audit_events', {
    method: 'POST',
    prefer: 'return=minimal',
    body: {
      company_id: company.id,
      actor_user_id: userId,
      event_type: 'sandbox.master.created',
      entity_type: 'environment',
      entity_id: userId,
      after_json: { environment: 'sandbox', login_role: 'owner' },
      reason: 'One-time CTOD sandbox bootstrap',
    },
  });

  console.log(`Created the single CTOD Sandbox Master login: ${email} (${userId}).`);
} catch (error) {
  if (userId) {
    await request(`/auth/v1/admin/users/${userId}`, { method: 'DELETE' }).catch(() => undefined);
  }
  throw error;
}
