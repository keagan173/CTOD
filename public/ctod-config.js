import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.112.2';

const raw = window.__CTOD_RUNTIME_CONFIG__;
if (!raw || typeof raw !== 'object') {
  throw new Error('CTOD runtime configuration is missing. Run the environment build before serving CTOD.');
}

const environment = String(raw.environment || '');
if (!['production', 'sandbox'].includes(environment)) {
  throw new Error('CTOD runtime environment is invalid.');
}

const supabaseUrl = new URL(String(raw.supabaseUrl || ''));
const projectRef = supabaseUrl.hostname.match(/^([a-z0-9-]+)\.supabase\.co$/i)?.[1];
if (supabaseUrl.protocol !== 'https:' || !projectRef) {
  throw new Error('CTOD Supabase URL is invalid.');
}
if (environment === 'production' && projectRef !== raw.productionProjectRef) {
  throw new Error('CTOD production environment guard rejected the configured database.');
}
if (environment === 'sandbox') {
  if (projectRef === raw.productionProjectRef) {
    throw new Error('CTOD sandbox isolation guard blocked the production database.');
  }
  if (!raw.sandboxProjectRef || projectRef !== raw.sandboxProjectRef) {
    throw new Error('CTOD sandbox project reference does not match its configured database.');
  }
}

const emailAllowlist = Object.freeze(
  [...new Set((raw.emailAllowlist || []).map((value) => String(value).trim().toLowerCase()).filter(Boolean))],
);
const featureFlags = Object.freeze(raw.featureFlags && typeof raw.featureFlags === 'object' ? raw.featureFlags : {});

export const ctodConfig = Object.freeze({
  environment,
  appName: String(raw.appName || 'CTOD'),
  appUrl: String(raw.appUrl || location.origin),
  supabaseUrl: supabaseUrl.origin,
  projectRef,
  productionProjectRef: String(raw.productionProjectRef || ''),
  sandboxProjectRef: raw.sandboxProjectRef ? String(raw.sandboxProjectRef) : null,
  emailAllowlist,
  featureFlags,
  buildId: String(raw.buildId || 'unknown'),
  isSandbox: environment === 'sandbox',
  isProduction: environment === 'production',
});

export const ctodSupabase = createClient(
  ctodConfig.supabaseUrl,
  String(raw.supabasePublishableKey || ''),
  {
    auth: {
      storageKey: `ctod-${environment}-auth`,
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
    },
  },
);

export function sandboxEmailAllowed(email) {
  if (!ctodConfig.isSandbox) return true;
  return ctodConfig.emailAllowlist.includes(String(email || '').trim().toLowerCase());
}

export function assertSandboxEmailAllowed(email) {
  if (sandboxEmailAllowed(email)) return;
  throw new Error(
    ctodConfig.emailAllowlist.length
      ? 'Sandbox email blocked. Use an approved test address.'
      : 'Sandbox email delivery is disabled until an approved address is configured.',
  );
}

export function featureEnabled(name, locationCode = null) {
  const flag = ctodConfig.featureFlags?.[name];
  if (!flag || flag.enabled !== true) return false;
  const locations = Array.isArray(flag.locations)
    ? flag.locations.map((value) => String(value).padStart(3, '0'))
    : [];
  if (!locations.length) return true;
  return locationCode != null && locations.includes(String(locationCode).padStart(3, '0'));
}

function installEnvironmentMarker() {
  document.documentElement.dataset.ctodEnvironment = environment;
  document.documentElement.dataset.ctodProjectRef = projectRef;
  if (!ctodConfig.isSandbox || document.querySelector('#ctodSandboxBanner')) return;

  document.title = 'SANDBOX · CTOD';
  const style = document.createElement('style');
  style.id = 'ctodSandboxStyles';
  style.textContent = `
    #ctodSandboxBanner{position:sticky;top:0;z-index:100000;background:repeating-linear-gradient(135deg,#ffcf33,#ffcf33 14px,#f5b800 14px,#f5b800 28px);color:#211700;border-bottom:3px solid #8a5a00;padding:10px 16px;text-align:center;font:900 13px/1.25 Inter,system-ui,sans-serif;letter-spacing:.08em;text-transform:uppercase;box-shadow:0 4px 18px #0004}
    #ctodSandboxBanner small{display:block;font-size:10px;letter-spacing:.03em;margin-top:2px}
    @media print{#ctodSandboxBanner{display:none!important}}
  `;
  const banner = document.createElement('aside');
  banner.id = 'ctodSandboxBanner';
  banner.setAttribute('role', 'status');
  banner.innerHTML = '<span>SANDBOX — FAKE DATA ONLY</span><small>Changes here never update production CTOD</small>';
  document.head.appendChild(style);
  document.body.prepend(banner);
}

installEnvironmentMarker();
window.ctodConfig = ctodConfig;
window.ctodSupabase = ctodSupabase;
