begin;

create table if not exists public.company_provisioning_runs (
  id uuid primary key default gen_random_uuid(),
  provisioning_key text not null unique,
  template_code text not null,
  requested_name text not null,
  requested_slug text not null,
  company_id uuid references public.companies(id) on delete restrict,
  status text not null default 'pending' check (status in ('pending','completed','failed')),
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

alter table public.company_provisioning_runs enable row level security;
revoke all on public.company_provisioning_runs from anon, authenticated;
grant select, insert, update on public.company_provisioning_runs to service_role;

create or replace function private.provision_blank_company(
  p_name text,
  p_slug text,
  p_timezone text,
  p_provisioning_key text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_company_id uuid;
  v_template_id uuid;
  v_template_version_id uuid;
  v_template_version text;
  v_schema_version text;
  v_existing_status text;
begin
  if nullif(btrim(p_name), '') is null then
    raise exception 'Company name is required';
  end if;

  if p_slug is null or p_slug !~ '^[a-z0-9]+(?:-[a-z0-9]+)*$' then
    raise exception 'Company slug must contain lowercase letters, numbers, and single hyphens only';
  end if;

  if nullif(btrim(p_timezone), '') is null then
    raise exception 'Company timezone is required';
  end if;

  if nullif(btrim(p_provisioning_key), '') is null then
    raise exception 'Provisioning key is required';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_provisioning_key, 0));

  select r.company_id, r.status
    into v_company_id, v_existing_status
  from public.company_provisioning_runs r
  where r.provisioning_key = p_provisioning_key;

  if v_existing_status = 'completed' and v_company_id is not null then
    return v_company_id;
  end if;

  select t.id, v.id, v.version_code, v.schema_version
    into v_template_id, v_template_version_id, v_template_version, v_schema_version
  from public.industry_templates t
  join public.industry_template_versions v on v.industry_template_id = t.id
  where t.template_code = 'BLANK'
    and t.status = 'published'
    and t.is_blank_standard = true
    and v.status = 'published'
  order by v.published_at desc nulls last, v.created_at desc
  limit 1;

  if v_template_id is null or v_template_version_id is null then
    raise exception 'Published Blank Standard Master template is unavailable';
  end if;

  insert into public.company_provisioning_runs (
    provisioning_key, template_code, requested_name, requested_slug, status
  )
  values (
    p_provisioning_key, 'BLANK', btrim(p_name), p_slug, 'pending'
  )
  on conflict (provisioning_key) do update
    set requested_name = excluded.requested_name,
        requested_slug = excluded.requested_slug
  returning company_id into v_company_id;

  if v_company_id is not null then
    return v_company_id;
  end if;

  insert into public.companies (
    industry_code,
    name,
    slug,
    timezone,
    status,
    branding,
    industry_template_id,
    industry_template_version_id,
    provisioned_at
  )
  values (
    'BLANK',
    btrim(p_name),
    p_slug,
    p_timezone,
    'active',
    '{}'::jsonb,
    v_template_id,
    v_template_version_id,
    now()
  )
  returning id into v_company_id;

  insert into public.configuration_versions (
    company_id,
    schema_version,
    version_label,
    status,
    minimum_client_version,
    published_at
  )
  values (
    v_company_id,
    v_schema_version,
    'Blank Standard Master ' || v_template_version,
    'published'::public.config_status,
    v_schema_version,
    now()
  );

  insert into public.company_template_lineage (
    company_id,
    industry_template_id,
    industry_template_version_id,
    provisioning_key,
    active,
    provisioned_at,
    metadata
  )
  values (
    v_company_id,
    v_template_id,
    v_template_version_id,
    p_provisioning_key,
    true,
    now(),
    jsonb_build_object('source', 'blank_standard_master', 'template_version', v_template_version)
  );

  update public.company_provisioning_runs
  set company_id = v_company_id,
      status = 'completed',
      completed_at = now()
  where provisioning_key = p_provisioning_key;

  return v_company_id;
end;
$$;

revoke all on function private.provision_blank_company(text, text, text, text) from public;
revoke all on function private.provision_blank_company(text, text, text, text) from anon;
revoke all on function private.provision_blank_company(text, text, text, text) from authenticated;
grant execute on function private.provision_blank_company(text, text, text, text) to service_role;

comment on table public.company_provisioning_runs is 'Internal idempotency ledger for CTOD customer provisioning. Not exposed to customer roles.';
comment on function private.provision_blank_company(text, text, text, text) is 'Service-role-only idempotent provisioning of a customer from Blank Standard Master.';

commit;
