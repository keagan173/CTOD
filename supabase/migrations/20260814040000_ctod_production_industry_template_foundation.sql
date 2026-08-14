begin;

create table if not exists public.industry_templates (
  id uuid primary key default gen_random_uuid(),
  template_code text not null unique,
  name text not null,
  description text,
  status text not null default 'draft' check (status in ('draft','published','retired')),
  is_blank_standard boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists industry_templates_one_blank_standard_idx
  on public.industry_templates (is_blank_standard)
  where is_blank_standard = true;

create table if not exists public.industry_template_versions (
  id uuid primary key default gen_random_uuid(),
  industry_template_id uuid not null references public.industry_templates(id) on delete restrict,
  version_code text not null,
  schema_version text not null,
  status text not null default 'draft' check (status in ('draft','published','retired')),
  configuration jsonb not null default '{}'::jsonb,
  minimum_client_version text,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  unique (industry_template_id, version_code),
  unique (id, industry_template_id)
);

alter table public.companies
  add column if not exists industry_template_id uuid,
  add column if not exists industry_template_version_id uuid,
  add column if not exists provisioned_at timestamptz;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'companies_industry_template_fk') then
    alter table public.companies add constraint companies_industry_template_fk
      foreign key (industry_template_id) references public.industry_templates(id) on delete restrict;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'companies_industry_template_version_fk') then
    alter table public.companies add constraint companies_industry_template_version_fk
      foreign key (industry_template_version_id, industry_template_id)
      references public.industry_template_versions(id, industry_template_id) on delete restrict;
  end if;
end $$;

create table if not exists public.company_template_lineage (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  industry_template_id uuid not null references public.industry_templates(id) on delete restrict,
  industry_template_version_id uuid not null,
  provisioning_key text not null,
  active boolean not null default true,
  provisioned_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  unique (company_id, provisioning_key),
  foreign key (industry_template_version_id, industry_template_id)
    references public.industry_template_versions(id, industry_template_id) on delete restrict
);

create unique index if not exists company_template_lineage_one_active_idx
  on public.company_template_lineage(company_id) where active = true;

alter table public.industry_templates enable row level security;
alter table public.industry_template_versions enable row level security;
alter table public.company_template_lineage enable row level security;

revoke all on public.industry_templates from anon;
revoke all on public.industry_template_versions from anon;
revoke all on public.company_template_lineage from anon;

grant select on public.industry_templates to authenticated;
grant select on public.industry_template_versions to authenticated;
grant select on public.company_template_lineage to authenticated;

drop policy if exists industry_templates_published_select on public.industry_templates;
create policy industry_templates_published_select on public.industry_templates for select to authenticated using (status = 'published');

drop policy if exists industry_template_versions_published_select on public.industry_template_versions;
create policy industry_template_versions_published_select on public.industry_template_versions for select to authenticated using (status = 'published');

drop policy if exists company_template_lineage_member_select on public.company_template_lineage;
create policy company_template_lineage_member_select on public.company_template_lineage for select to authenticated
  using (company_id in (select private.current_company_ids()));

insert into public.industry_templates (template_code,name,description,status,is_blank_standard,metadata)
values
 ('BLANK','Blank Standard Master','Customer-neutral CTOD platform template with no customer operational data.','published',true,'{"seed_operational_data":false,"purpose":"new_customer"}'::jsonb),
 ('001','Industry 001 Reference Template','Validated reference implementation retained for compatibility while CTOD Core is productized.','published',false,'{"purpose":"reference_implementation"}'::jsonb)
on conflict (template_code) do update set
 name=excluded.name,description=excluded.description,status=excluded.status,is_blank_standard=excluded.is_blank_standard,metadata=excluded.metadata,updated_at=now();

insert into public.industry_template_versions (industry_template_id,version_code,schema_version,status,configuration,minimum_client_version,published_at)
select t.id,'1.0.0','1.0.1','published','{"seed_locations":false,"seed_employees":false,"seed_roles":false,"seed_questions":false,"seed_history":false}'::jsonb,'1.0.1',now()
from public.industry_templates t where t.template_code='BLANK'
on conflict (industry_template_id,version_code) do nothing;

insert into public.industry_template_versions (industry_template_id,version_code,schema_version,status,configuration,minimum_client_version,published_at)
select t.id,'1.0.1','1.0.1','published','{"reference_only":true,"preserve_existing_configuration":true}'::jsonb,'1.0.1',now()
from public.industry_templates t where t.template_code='001'
on conflict (industry_template_id,version_code) do nothing;

update public.companies c
set industry_template_id=t.id,industry_template_version_id=v.id,provisioned_at=coalesce(c.provisioned_at,c.created_at)
from public.industry_templates t join public.industry_template_versions v on v.industry_template_id=t.id and v.version_code='1.0.1'
where c.industry_code='001' and t.template_code='001'
  and (c.industry_template_id is null or c.industry_template_version_id is null);

insert into public.company_template_lineage (company_id,industry_template_id,industry_template_version_id,provisioning_key,active,provisioned_at,metadata)
select c.id,c.industry_template_id,c.industry_template_version_id,'legacy-industry-001-baseline',true,coalesce(c.provisioned_at,now()),'{"source":"ctod_001_validated_baseline"}'::jsonb
from public.companies c
where c.industry_code='001' and c.industry_template_id is not null and c.industry_template_version_id is not null
on conflict (company_id,provisioning_key) do nothing;

create or replace view public.v_company_template_context with (security_invoker=true) as
select c.id company_id,c.name company_name,c.slug company_slug,c.status company_status,c.industry_code,
 t.id industry_template_id,t.template_code,t.name template_name,v.id industry_template_version_id,
 v.version_code template_version,v.schema_version,c.provisioned_at
from public.companies c
left join public.industry_templates t on t.id=c.industry_template_id
left join public.industry_template_versions v on v.id=c.industry_template_version_id and v.industry_template_id=c.industry_template_id;

grant select on public.v_company_template_context to authenticated;

commit;
