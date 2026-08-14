import { cpSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const publicDir = resolve(root, 'public');
const outputDir = resolve(root, 'dist');
const productionConfig = JSON.parse(
  readFileSync(resolve(root, 'config/environments/production.public.json'), 'utf8'),
);
const sandboxConfig = JSON.parse(
  readFileSync(resolve(root, 'config/environments/sandbox.public.json'), 'utf8'),
);

function argument(name) {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : undefined;
}

function requireValue(value, name) {
  if (!String(value || '').trim()) throw new Error(`${name} is required for this build.`);
  return String(value).trim();
}

function projectRef(value) {
  const url = new URL(value);
  if (url.protocol !== 'https:') throw new Error('CTOD_SUPABASE_URL must use HTTPS.');
  const match = url.hostname.match(/^([a-z0-9-]+)\.supabase\.co$/i);
  if (!match) throw new Error('CTOD_SUPABASE_URL must be a hosted Supabase project URL.');
  return match[1];
}

function normalizedAppUrl(value) {
  const url = new URL(value);
  if (url.protocol !== 'https:') throw new Error('CTOD_APP_URL must use HTTPS.');
  url.pathname = '/';
  url.search = '';
  url.hash = '';
  return url.toString();
}

function environmentName() {
  const explicit = argument('--environment') || process.env.CTOD_ENVIRONMENT;
  if (explicit) return explicit;
  if (process.env.VERCEL_ENV === 'production') return 'production';
  if (process.env.VERCEL_ENV === 'preview') return 'sandbox';
  throw new Error(
    'CTOD_ENVIRONMENT is required outside Vercel. Set it to production or sandbox.',
  );
}

const environment = environmentName();
if (!['production', 'sandbox'].includes(environment)) {
  throw new Error('CTOD_ENVIRONMENT must be production or sandbox.');
}

const productionProjectRef =
  process.env.CTOD_PRODUCTION_PROJECT_REF || productionConfig.productionProjectRef;
const defaults = environment === 'production' ? productionConfig : sandboxConfig;
const supabaseUrl = requireValue(
  process.env.CTOD_SUPABASE_URL || defaults.supabaseUrl,
  'CTOD_SUPABASE_URL',
);
const supabasePublishableKey = requireValue(
  process.env.CTOD_SUPABASE_PUBLISHABLE_KEY || defaults.supabasePublishableKey,
  'CTOD_SUPABASE_PUBLISHABLE_KEY',
);
const resolvedProjectRef = projectRef(supabaseUrl);
const vercelUrl = process.env.VERCEL_PROJECT_PRODUCTION_URL || process.env.VERCEL_URL;
const appUrl = normalizedAppUrl(
  requireValue(
    process.env.CTOD_APP_URL || defaults.appUrl || (vercelUrl ? `https://${vercelUrl}` : ''),
    'CTOD_APP_URL',
  ),
);
const sandboxProjectRef = String(
  process.env.CTOD_SANDBOX_PROJECT_REF || defaults.sandboxProjectRef || '',
).trim();

if (environment === 'production' && resolvedProjectRef !== productionProjectRef) {
  throw new Error('Production build refused: Supabase URL does not match the production project ref.');
}
if (environment === 'sandbox') {
  requireValue(sandboxProjectRef, 'CTOD_SANDBOX_PROJECT_REF');
  if (resolvedProjectRef === productionProjectRef) {
    throw new Error('Sandbox build refused: production Supabase project detected.');
  }
  if (resolvedProjectRef !== sandboxProjectRef) {
    throw new Error('Sandbox build refused: URL and CTOD_SANDBOX_PROJECT_REF do not match.');
  }
}
if (!supabasePublishableKey.startsWith('sb_publishable_')) {
  throw new Error('Use a Supabase publishable key; secret and service-role keys are forbidden.');
}

const emailAllowlist = String(
  process.env.CTOD_EMAIL_ALLOWLIST || defaults.emailAllowlist?.join(',') || '',
)
  .split(',')
  .map((value) => value.trim().toLowerCase())
  .filter(Boolean);

let featureFlags = {};
try {
  featureFlags = JSON.parse(
    process.env.CTOD_FEATURE_FLAGS_JSON || JSON.stringify(defaults.featureFlags || {}),
  );
} catch {
  throw new Error('CTOD_FEATURE_FLAGS_JSON must be valid JSON.');
}
if (!featureFlags || Array.isArray(featureFlags) || typeof featureFlags !== 'object') {
  throw new Error('CTOD_FEATURE_FLAGS_JSON must be a JSON object.');
}

const runtimeConfig = {
  environment,
  appName: environment === 'sandbox' ? 'CTOD Sandbox' : productionConfig.appName,
  appUrl,
  supabaseUrl,
  supabasePublishableKey,
  productionProjectRef,
  sandboxProjectRef: environment === 'sandbox' ? sandboxProjectRef : null,
  emailAllowlist,
  featureFlags,
  buildId:
    process.env.VERCEL_GIT_COMMIT_SHA ||
    process.env.CTOD_BUILD_ID ||
    `local-${environment}`,
};

rmSync(outputDir, { recursive: true, force: true });
mkdirSync(outputDir, { recursive: true });
cpSync(publicDir, outputDir, { recursive: true });
writeFileSync(
  resolve(outputDir, 'runtime-config.js'),
  `window.__CTOD_RUNTIME_CONFIG__ = Object.freeze(${JSON.stringify(runtimeConfig)});\n`,
  'utf8',
);

console.log(
  `Built ${runtimeConfig.appName} for ${environment} using Supabase project ${resolvedProjectRef}.`,
);
