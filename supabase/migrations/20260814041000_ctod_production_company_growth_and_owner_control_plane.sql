begin;

create table if not exists public.company_settings (
  company_id uuid primary key references public.companies(id) on delete cascade,
  review_cadence_months integer not null default 6,
  terminology jsonb not null default '{}'::jsonb,
  coaching_categories jsonb not null default '["Recognition","Development","Corrective"]'::jsonb,
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  organization_mode text not null default 'single_site',
  primary_location_id uuid
);

alter table public.company_settings drop constraint if exists company_settings_organization_mode_check;
alter table public.company_settings add constraint company_settings_organization_mode_check check (organization_mode in ('single_site','multi_site'));
do $$ begin
 if not exists(select 1 from pg_constraint where conname='company_settings_primary_location_fk') then
  alter table public.company_settings add constraint company_settings_primary_location_fk foreign key(primary_location_id) references public.locations(id) on delete set null;
 end if;
end $$;

insert into public.company_settings(company_id,organization_mode)
select c.id,case when (select count(*) from public.locations l where l.company_id=c.id and l.status='active')>1 then 'multi_site' else 'single_site' end
from public.companies c
on conflict(company_id) do update set organization_mode=excluded.organization_mode,updated_at=now();

update public.company_settings s set primary_location_id=x.location_id
from (select distinct on(l.company_id) l.company_id,l.id location_id from public.locations l where l.status='active' order by l.company_id,l.created_at,l.location_code) x
where x.company_id=s.company_id and s.primary_location_id is null;

create table if not exists public.company_provisioning_runs (
 id uuid primary key default gen_random_uuid(), provisioning_key text not null unique, template_code text not null,
 requested_name text not null, requested_slug text not null, company_id uuid references public.companies(id) on delete restrict,
 status text not null default 'pending' check(status in ('pending','completed','failed')), created_at timestamptz not null default now(), completed_at timestamptz
);
alter table public.company_provisioning_runs enable row level security;
revoke all on public.company_provisioning_runs from anon,authenticated;
grant select,insert,update on public.company_provisioning_runs to service_role;

create table if not exists private.platform_operators (
 user_id uuid primary key references auth.users(id) on delete cascade,
 operator_role text not null default 'platform_admin' check(operator_role in ('platform_admin','support','read_only')),
 active boolean not null default true, display_name text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
revoke all on private.platform_operators from public,anon,authenticated;
grant select,insert,update,delete on private.platform_operators to service_role;

create table if not exists private.customer_accounts (
 company_id uuid primary key references public.companies(id) on delete restrict,
 account_status text not null default 'trial' check(account_status in ('trial','active','suspended','closed')),
 plan_code text not null default 'standard', customer_since date, trial_ends_at timestamptz, support_notes text,
 external_billing_customer_id text, core_version text not null default '1.0.1', target_core_version text,
 previous_core_version text, release_status text not null default 'current',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
revoke all on private.customer_accounts from public,anon,authenticated;
grant select,insert,update on private.customer_accounts to service_role;

insert into private.customer_accounts(company_id,account_status,customer_since,core_version,release_status)
select c.id,case when c.status='active' then 'active' else 'suspended' end,c.created_at::date,'1.0.1','current' from public.companies c
on conflict(company_id) do nothing;

create or replace function private.is_platform_operator(p_user_id uuid default auth.uid()) returns boolean
language sql stable security definer set search_path='' as $$ select exists(select 1 from private.platform_operators po where po.user_id=p_user_id and po.active=true); $$;
revoke all on function private.is_platform_operator(uuid) from public,anon,authenticated;
grant execute on function private.is_platform_operator(uuid) to service_role;

create or replace function private.provision_blank_company(p_name text,p_slug text,p_timezone text,p_provisioning_key text) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_company_id uuid; v_template_id uuid; v_template_version_id uuid; v_template_version text; v_schema_version text; v_existing_status text;
begin
 if nullif(btrim(p_name),'') is null then raise exception 'Company name is required'; end if;
 if p_slug is null or p_slug !~ '^[a-z0-9]+(?:-[a-z0-9]+)*$' then raise exception 'Company slug must contain lowercase letters, numbers, and single hyphens only'; end if;
 if nullif(btrim(p_timezone),'') is null then raise exception 'Company timezone is required'; end if;
 if nullif(btrim(p_provisioning_key),'') is null then raise exception 'Provisioning key is required'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_provisioning_key,0));
 select r.company_id,r.status into v_company_id,v_existing_status from public.company_provisioning_runs r where r.provisioning_key=p_provisioning_key;
 if v_existing_status='completed' and v_company_id is not null then return v_company_id; end if;
 select t.id,v.id,v.version_code,v.schema_version into v_template_id,v_template_version_id,v_template_version,v_schema_version
 from public.industry_templates t join public.industry_template_versions v on v.industry_template_id=t.id
 where t.template_code='BLANK' and t.status='published' and t.is_blank_standard=true and v.status='published'
 order by v.published_at desc nulls last,v.created_at desc limit 1;
 if v_template_id is null then raise exception 'Published Blank Standard Master template is unavailable'; end if;
 insert into public.company_provisioning_runs(provisioning_key,template_code,requested_name,requested_slug,status)
 values(p_provisioning_key,'BLANK',btrim(p_name),p_slug,'pending')
 on conflict(provisioning_key) do update set requested_name=excluded.requested_name,requested_slug=excluded.requested_slug returning company_id into v_company_id;
 if v_company_id is not null then return v_company_id; end if;
 insert into public.companies(industry_code,name,slug,timezone,status,branding,industry_template_id,industry_template_version_id,provisioned_at)
 values('BLANK',btrim(p_name),p_slug,p_timezone,'active','{}'::jsonb,v_template_id,v_template_version_id,now()) returning id into v_company_id;
 insert into public.configuration_versions(company_id,schema_version,version_label,status,minimum_client_version,published_at)
 values(v_company_id,v_schema_version,'Blank Standard Master '||v_template_version,'published'::public.config_status,v_schema_version,now());
 insert into public.company_template_lineage(company_id,industry_template_id,industry_template_version_id,provisioning_key,active,provisioned_at,metadata)
 values(v_company_id,v_template_id,v_template_version_id,p_provisioning_key,true,now(),jsonb_build_object('source','blank_standard_master','template_version',v_template_version));
 insert into public.company_settings(company_id,organization_mode) values(v_company_id,'single_site') on conflict(company_id) do nothing;
 insert into private.customer_accounts(company_id,account_status,plan_code,trial_ends_at,core_version,release_status)
 values(v_company_id,'trial','standard',now()+interval '30 days','1.0.1','current') on conflict(company_id) do nothing;
 update public.company_provisioning_runs set company_id=v_company_id,status='completed',completed_at=now() where provisioning_key=p_provisioning_key;
 return v_company_id;
end $$;
revoke all on function private.provision_blank_company(text,text,text,text) from public,anon,authenticated;
grant execute on function private.provision_blank_company(text,text,text,text) to service_role;

create or replace view public.v_company_operating_model with(security_invoker=true) as
select c.id company_id,c.name company_name,coalesce(s.organization_mode,'single_site') organization_mode,s.primary_location_id,
 pl.name primary_site_name,pl.location_code primary_site_code,count(l.id) filter(where l.status='active') active_site_count,
 (count(l.id) filter(where l.status='active')>1) has_multiple_sites
from public.companies c left join public.company_settings s on s.company_id=c.id left join public.locations pl on pl.id=s.primary_location_id left join public.locations l on l.company_id=c.id
group by c.id,c.name,s.organization_mode,s.primary_location_id,pl.name,pl.location_code;
grant select on public.v_company_operating_model to authenticated;

commit;
