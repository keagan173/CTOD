begin;

-- Sandbox migration history version: 20260812044420.

-- CTOD operator control plane
--
-- Customer users remain ordinary company members. Platform operators live in
-- private.platform_operators and never require a company membership. All
-- browser-facing operator activity is brokered by an authenticated Edge
-- Function which calls the service-role-only functions below.

alter table private.platform_operators
  add column if not exists display_name text,
  add column if not exists last_seen_at timestamptz;

alter table private.customer_accounts
  add column if not exists core_version text not null default '1.0.1',
  add column if not exists target_core_version text,
  add column if not exists previous_core_version text,
  add column if not exists release_status text not null default 'current',
  add column if not exists deployment_status text not null default 'not_configured',
  add column if not exists deployment_url text,
  add column if not exists database_project_ref text,
  add column if not exists backup_status text not null default 'not_verified',
  add column if not exists last_backup_at timestamptz,
  add column if not exists health_status text not null default 'unknown',
  add column if not exists health_summary jsonb not null default '{}'::jsonb,
  add column if not exists last_health_check_at timestamptz,
  add column if not exists suspended_at timestamptz,
  add column if not exists suspended_by_user_id uuid,
  add column if not exists reactivated_at timestamptz,
  add column if not exists closed_at timestamptz;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'customer_accounts_release_status_check'
      and conrelid = 'private.customer_accounts'::regclass
  ) then
    alter table private.customer_accounts
      add constraint customer_accounts_release_status_check
      check (release_status in ('current','scheduled','upgrade_pending','rollback_available','rollback_completed'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'customer_accounts_deployment_status_check'
      and conrelid = 'private.customer_accounts'::regclass
  ) then
    alter table private.customer_accounts
      add constraint customer_accounts_deployment_status_check
      check (deployment_status in ('not_configured','provisioning','ready','degraded','failed'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'customer_accounts_backup_status_check'
      and conrelid = 'private.customer_accounts'::regclass
  ) then
    alter table private.customer_accounts
      add constraint customer_accounts_backup_status_check
      check (backup_status in ('not_verified','current','stale','failed'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'customer_accounts_health_status_check'
      and conrelid = 'private.customer_accounts'::regclass
  ) then
    alter table private.customer_accounts
      add constraint customer_accounts_health_status_check
      check (health_status in ('unknown','healthy','setup_required','warning','blocked'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'customer_accounts_suspended_by_fkey'
      and conrelid = 'private.customer_accounts'::regclass
  ) then
    alter table private.customer_accounts
      add constraint customer_accounts_suspended_by_fkey
      foreign key (suspended_by_user_id) references auth.users(id) on delete set null;
  end if;
end $$;

create table if not exists private.platform_releases (
  id uuid primary key default extensions.gen_random_uuid(),
  version_code text not null unique,
  status text not null default 'candidate' check (status in ('candidate','available','retired')),
  minimum_schema_version text,
  release_notes text,
  released_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists private.operator_audit_events (
  id uuid primary key default extensions.gen_random_uuid(),
  request_id uuid not null unique,
  actor_user_id uuid not null references auth.users(id) on delete restrict,
  company_id uuid references public.companies(id) on delete restrict,
  action text not null,
  target_type text not null,
  target_id uuid,
  reason text,
  before_json jsonb,
  after_json jsonb,
  occurred_at timestamptz not null default now()
);

create table if not exists private.customer_health_snapshots (
  id uuid primary key default extensions.gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  checked_by_user_id uuid not null references auth.users(id) on delete restrict,
  health_status text not null check (health_status in ('healthy','setup_required','warning','blocked')),
  snapshot jsonb not null,
  checked_at timestamptz not null default now()
);

create table if not exists private.customer_release_history (
  id uuid primary key default extensions.gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  actor_user_id uuid not null references auth.users(id) on delete restrict,
  action text not null check (action in ('scheduled','activated','rolled_back','cancelled')),
  from_version text,
  to_version text,
  reason text,
  occurred_at timestamptz not null default now()
);

create table if not exists private.customer_access_holds (
  id uuid primary key default extensions.gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  membership_id uuid references public.company_memberships(id) on delete cascade,
  location_access_id uuid references public.user_location_access(id) on delete cascade,
  held_by_user_id uuid not null references auth.users(id) on delete restrict,
  held_at timestamptz not null default now(),
  released_at timestamptz,
  check (num_nonnulls(membership_id, location_access_id) = 1)
);

create index if not exists operator_audit_company_time_idx
  on private.operator_audit_events(company_id, occurred_at desc);
create index if not exists operator_audit_actor_time_idx
  on private.operator_audit_events(actor_user_id, occurred_at desc);
create index if not exists customer_health_company_time_idx
  on private.customer_health_snapshots(company_id, checked_at desc);
create index if not exists customer_release_history_company_time_idx
  on private.customer_release_history(company_id, occurred_at desc);
create index if not exists customer_access_holds_company_idx
  on private.customer_access_holds(company_id, released_at);
create index if not exists customer_access_holds_held_by_idx
  on private.customer_access_holds(held_by_user_id);
create index if not exists customer_access_holds_membership_fk_idx
  on private.customer_access_holds(membership_id);
create index if not exists customer_access_holds_location_access_fk_idx
  on private.customer_access_holds(location_access_id);
create index if not exists customer_accounts_suspended_by_idx
  on private.customer_accounts(suspended_by_user_id);
create index if not exists customer_health_checked_by_idx
  on private.customer_health_snapshots(checked_by_user_id);
create index if not exists customer_release_actor_idx
  on private.customer_release_history(actor_user_id);
create unique index if not exists customer_access_holds_open_membership_idx
  on private.customer_access_holds(company_id, membership_id)
  where membership_id is not null and released_at is null;
create unique index if not exists customer_access_holds_open_location_idx
  on private.customer_access_holds(company_id, location_access_id)
  where location_access_id is not null and released_at is null;

revoke all on private.platform_releases from public, anon, authenticated;
revoke all on private.operator_audit_events from public, anon, authenticated;
revoke all on private.customer_health_snapshots from public, anon, authenticated;
revoke all on private.customer_release_history from public, anon, authenticated;
revoke all on private.customer_access_holds from public, anon, authenticated;

grant usage on schema private to service_role;
grant select, insert, update on private.platform_releases to service_role;
grant select, insert on private.operator_audit_events to service_role;
grant select, insert on private.customer_health_snapshots to service_role;
grant select, insert on private.customer_release_history to service_role;
grant select, insert, update on private.customer_access_holds to service_role;

insert into private.platform_releases(version_code,status,minimum_schema_version,release_notes,released_at)
values
  ('1.0.1','available','1.0.1','Validated CTOD 001 production baseline.',now()),
  ('1.1.0','candidate','1.0.1','Isolated sandbox and CTOD 002 configuration foundation.',null)
on conflict(version_code) do update
set status=excluded.status,
    minimum_schema_version=excluded.minimum_schema_version,
    release_notes=excluded.release_notes,
    released_at=coalesce(private.platform_releases.released_at,excluded.released_at);

-- Suspension must be authoritative even for older privileged RPCs. Operational
-- scope now requires both an active membership/access row and an active company.
create or replace function private.company_is_active(p_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists(
    select 1 from public.companies c
    where c.id=p_company_id and c.status='active'
  );
$$;

create or replace function private.current_company_ids()
returns setof uuid
language sql
stable
security definer
set search_path=''
as $$
  select m.company_id
  from public.company_memberships m
  join public.companies c on c.id=m.company_id and c.status='active'
  where m.user_id=(select auth.uid()) and m.active=true;
$$;

create or replace function private.current_location_ids()
returns setof uuid
language sql
stable
security definer
set search_path=''
as $$
  select ula.location_id
  from public.user_location_access ula
  join public.companies c on c.id=ula.company_id and c.status='active'
  where ula.user_id=(select auth.uid()) and ula.active=true
  union
  select cm.location_id
  from public.company_memberships cm
  join public.companies c on c.id=cm.company_id and c.status='active'
  where cm.user_id=(select auth.uid()) and cm.active=true and cm.location_id is not null;
$$;

create or replace function private.has_company_role(
  p_company_id uuid,
  allowed public.membership_role[]
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists(
    select 1
    from public.company_memberships m
    join public.companies c on c.id=m.company_id and c.status='active'
    where m.company_id=p_company_id
      and m.user_id=(select auth.uid())
      and m.active=true
      and m.role=any(allowed)
  );
$$;

create or replace function private.is_company_leader(p_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists(
    select 1
    from public.company_memberships m
    join public.companies c on c.id=m.company_id and c.status='active'
    where m.company_id=p_company_id
      and m.user_id=(select auth.uid())
      and m.active=true
      and m.role in ('owner','admin','executive')
  );
$$;

create or replace function private.can_access_location(
  p_company_id uuid,
  p_location_id uuid
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select private.company_is_active(p_company_id)
    and (
      private.is_company_leader(p_company_id)
      or exists(
        select 1 from public.user_location_access ula
        where ula.company_id=p_company_id
          and ula.user_id=(select auth.uid())
          and ula.location_id=p_location_id
          and ula.active=true
      )
      or exists(
        select 1 from public.company_memberships m
        where m.company_id=p_company_id
          and m.user_id=(select auth.uid())
          and m.active=true
          and m.location_id=p_location_id
      )
    );
$$;

create or replace function private.can_access_employee(
  p_company_id uuid,
  p_employee_id uuid
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select private.company_is_active(p_company_id)
    and (
      private.is_company_leader(p_company_id)
      or exists(
        select 1
        from public.employment_assignments a
        where a.company_id=p_company_id
          and a.employee_id=p_employee_id
          and a.effective_to is null
          and private.can_access_location(p_company_id,a.location_id)
      )
    );
$$;

revoke all on function private.company_is_active(uuid) from public, anon;
revoke all on function private.current_company_ids() from public, anon;
revoke all on function private.current_location_ids() from public, anon;
revoke all on function private.has_company_role(uuid,public.membership_role[]) from public, anon;
revoke all on function private.is_company_leader(uuid) from public, anon;
revoke all on function private.can_access_location(uuid,uuid) from public, anon;
revoke all on function private.can_access_employee(uuid,uuid) from public, anon;

grant execute on function private.company_is_active(uuid) to authenticated, service_role;
grant execute on function private.current_company_ids() to authenticated, service_role;
grant execute on function private.current_location_ids() to authenticated, service_role;
grant execute on function private.has_company_role(uuid,public.membership_role[]) to authenticated, service_role;
grant execute on function private.is_company_leader(uuid) to authenticated, service_role;
grant execute on function private.can_access_location(uuid,uuid) to authenticated, service_role;
grant execute on function private.can_access_employee(uuid,uuid) to authenticated, service_role;

-- A suspended user may read only their own membership and basic company status
-- so the app can explain the suspension. Operational tables remain inaccessible.
drop policy if exists memberships_member_select on public.company_memberships;
create policy memberships_member_select
on public.company_memberships
for select
to authenticated
using (
  user_id=(select auth.uid())
  or company_id in (select private.current_company_ids())
);

drop policy if exists companies_member_select on public.companies;
drop policy if exists companies_self_member_status_select on public.companies;
create policy companies_member_select
on public.companies
for select
to authenticated
using (
  id in (select private.current_company_ids())
  or exists(
      select 1 from public.company_memberships m
      where m.company_id=companies.id
        and m.user_id=(select auth.uid())
    )
);

-- Service-role-only operator authorization probe for the Edge Function.
create or replace function public.operator_service_authorize(p_user_id uuid)
returns jsonb
language sql
stable
security invoker
set search_path=''
as $$
  select jsonb_build_object(
    'user_id',po.user_id,
    'role',po.operator_role,
    'display_name',po.display_name,
    'active',po.active
  )
  from private.platform_operators po
  where po.user_id=p_user_id and po.active=true;
$$;

create or replace function public.operator_service_touch(p_user_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_result jsonb;
begin
  update private.platform_operators
  set last_seen_at=now(),updated_at=now()
  where user_id=p_user_id and active=true
  returning jsonb_build_object(
    'user_id',user_id,
    'role',operator_role,
    'display_name',display_name,
    'active',active,
    'last_seen_at',last_seen_at
  ) into v_result;
  return v_result;
end;
$$;

create or replace function public.operator_service_dashboard(p_actor_user_id uuid)
returns jsonb
language plpgsql
stable
security invoker
set search_path=''
as $$
declare
  v_operator jsonb;
begin
  select public.operator_service_authorize(p_actor_user_id) into v_operator;
  if v_operator is null then raise exception 'Platform operator access required'; end if;

  return jsonb_build_object(
    'operator',v_operator,
    'summary',(
      select jsonb_build_object(
        'customers',count(*),
        'active',count(*) filter(where coalesce(ca.account_status,'trial')='active'),
        'trial',count(*) filter(where coalesce(ca.account_status,'trial')='trial'),
        'suspended',count(*) filter(where coalesce(ca.account_status,'trial')='suspended'),
        'closed',count(*) filter(where coalesce(ca.account_status,'trial')='closed'),
        'healthy',count(*) filter(where coalesce(ca.health_status,'unknown')='healthy'),
        'attention',count(*) filter(where coalesce(ca.health_status,'unknown') in ('setup_required','warning','blocked','unknown'))
      )
      from public.companies c
      left join private.customer_accounts ca on ca.company_id=c.id
    ),
    'customers',coalesce((
      select jsonb_agg(to_jsonb(x) order by x.company_name,x.company_id)
      from (
        select
          c.id as company_id,
          c.name as company_name,
          c.slug,
          c.timezone,
          c.status as company_status,
          c.created_at,
          coalesce(ca.account_status,'trial') as account_status,
          coalesce(ca.plan_code,'standard') as plan_code,
          ca.customer_since,
          ca.trial_ends_at,
          ca.support_notes,
          coalesce(ca.core_version,'1.0.1') as core_version,
          ca.target_core_version,
          ca.previous_core_version,
          coalesce(ca.release_status,'current') as release_status,
          coalesce(ca.deployment_status,'not_configured') as deployment_status,
          ca.deployment_url,
          ca.database_project_ref,
          coalesce(ca.backup_status,'not_verified') as backup_status,
          ca.last_backup_at,
          coalesce(ca.health_status,'unknown') as health_status,
          coalesce(ca.health_summary,'{}'::jsonb) as health_summary,
          ca.last_health_check_at,
          t.template_code,
          t.name as template_name,
          tv.version_code as template_version,
          cv.version_label as configuration_version,
          cv.status::text as configuration_status,
          coalesce(l.active_locations,0) as active_locations,
          coalesce(e.active_employees,0) as active_employees,
          coalesce(r.active_roles,0) as active_roles,
          coalesce(rv.review_count,0) as reviews,
          coalesce(m.active_memberships,0) as active_memberships,
          coalesce(m.owner_admin_count,0) as owner_admin_count,
          coalesce(i.pending_invites,0) as pending_invites
        from public.companies c
        left join private.customer_accounts ca on ca.company_id=c.id
        left join public.industry_templates t on t.id=c.industry_template_id
        left join public.industry_template_versions tv on tv.id=c.industry_template_version_id
        left join lateral (
          select z.version_label,z.status
          from public.configuration_versions z
          where z.company_id=c.id
          order by case when z.status='published' then 0 when z.status='draft' then 1 else 2 end,
                   z.created_at desc
          limit 1
        ) cv on true
        left join lateral (
          select count(*) filter(where status='active') as active_locations
          from public.locations where company_id=c.id
        ) l on true
        left join lateral (
          select count(*) filter(where employment_status='active') as active_employees
          from public.employees where company_id=c.id
        ) e on true
        left join lateral (
          select count(*) filter(where active=true) as active_roles
          from public.roles where company_id=c.id
        ) r on true
        left join lateral (
          select count(*) as review_count
          from public.reviews where company_id=c.id
        ) rv on true
        left join lateral (
          select
            count(*) filter(where active=true) as active_memberships,
            count(*) filter(where active=true and role in ('owner','admin')) as owner_admin_count
          from public.company_memberships where company_id=c.id
        ) m on true
        left join lateral (
          select count(*) as pending_invites
          from public.access_invites ai
          where ai.company_id=c.id
            and ai.accepted_at is null
            and ai.revoked_at is null
            and ai.expires_at>now()
        ) i on true
      ) x
    ),'[]'::jsonb),
    'templates',coalesce((
      select jsonb_agg(jsonb_build_object(
        'template_id',t.id,
        'template_code',t.template_code,
        'name',t.name,
        'description',t.description,
        'version_id',v.id,
        'version_code',v.version_code,
        'schema_version',v.schema_version,
        'minimum_client_version',v.minimum_client_version
      ) order by t.template_code,v.created_at desc)
      from public.industry_templates t
      join public.industry_template_versions v on v.industry_template_id=t.id
      where t.status='published' and v.status='published'
    ),'[]'::jsonb),
    'releases',coalesce((
      select jsonb_agg(to_jsonb(pr) order by pr.created_at desc)
      from private.platform_releases pr
    ),'[]'::jsonb),
    'operators',coalesce((
      select jsonb_agg(jsonb_build_object(
        'user_id',po.user_id,
        'display_name',po.display_name,
        'role',po.operator_role,
        'active',po.active,
        'created_at',po.created_at,
        'updated_at',po.updated_at,
        'last_seen_at',po.last_seen_at
      ) order by po.created_at)
      from private.platform_operators po
    ),'[]'::jsonb)
  );
end;
$$;

create or replace function public.operator_service_customer_diagnostics(
  p_actor_user_id uuid,
  p_company_id uuid,
  p_record boolean default true
)
returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_operator_role text;
  v_company public.companies%rowtype;
  v_account private.customer_accounts%rowtype;
  v_locations integer;
  v_employees integer;
  v_roles integer;
  v_reviews integer;
  v_finalized integer;
  v_members integer;
  v_owner_admins integer;
  v_pending_invites integer;
  v_published_config integer;
  v_draft_config integer;
  v_health text;
  v_snapshot jsonb;
  v_result jsonb;
begin
  select po.operator_role into v_operator_role
  from private.platform_operators po
  where po.user_id=p_actor_user_id and po.active=true;
  if v_operator_role is null then raise exception 'Platform operator access required'; end if;

  select * into v_company from public.companies where id=p_company_id;
  if not found then raise exception 'Customer not found'; end if;

  select * into v_account from private.customer_accounts where company_id=p_company_id;

  select count(*) filter(where status='active') into v_locations
  from public.locations where company_id=p_company_id;
  select count(*) filter(where employment_status='active') into v_employees
  from public.employees where company_id=p_company_id;
  select count(*) filter(where active=true) into v_roles
  from public.roles where company_id=p_company_id;
  select count(*),count(*) filter(where status='finalized') into v_reviews,v_finalized
  from public.reviews where company_id=p_company_id;
  select count(*) filter(where active=true),
         count(*) filter(where active=true and role in ('owner','admin'))
    into v_members,v_owner_admins
  from public.company_memberships where company_id=p_company_id;
  select count(*) into v_pending_invites
  from public.access_invites
  where company_id=p_company_id
    and accepted_at is null and revoked_at is null and expires_at>now();
  select count(*) filter(where status='published'),count(*) filter(where status='draft')
    into v_published_config,v_draft_config
  from public.configuration_versions where company_id=p_company_id;

  v_health:=case
    when v_company.status<>'active'
      or coalesce(v_account.account_status,'trial') in ('suspended','closed') then 'blocked'
    when coalesce(v_account.account_status,'trial')='trial'
      and (v_owner_admins=0 or v_locations=0) then 'setup_required'
    when v_owner_admins=0 or v_published_config<>1 or v_locations=0 then 'warning'
    else 'healthy'
  end;

  v_snapshot:=jsonb_build_object(
    'company_status',v_company.status,
    'account_status',coalesce(v_account.account_status,'trial'),
    'active_locations',v_locations,
    'active_employees',v_employees,
    'active_roles',v_roles,
    'reviews',v_reviews,
    'finalized_reviews',v_finalized,
    'active_memberships',v_members,
    'owner_admin_count',v_owner_admins,
    'pending_invites',v_pending_invites,
    'published_configurations',v_published_config,
    'draft_configurations',v_draft_config,
    'checked_at',now()
  );

  if p_record and v_operator_role<>'read_only' then
    insert into private.customer_health_snapshots(
      company_id,checked_by_user_id,health_status,snapshot
    ) values(p_company_id,p_actor_user_id,v_health,v_snapshot);

    update private.customer_accounts
    set health_status=v_health,
        health_summary=v_snapshot,
        last_health_check_at=now(),
        updated_at=now()
    where company_id=p_company_id;
  end if;

  select jsonb_build_object(
    'company',jsonb_build_object(
      'company_id',v_company.id,
      'company_name',v_company.name,
      'slug',v_company.slug,
      'timezone',v_company.timezone,
      'company_status',v_company.status,
      'account_status',coalesce(v_account.account_status,'trial'),
      'plan_code',coalesce(v_account.plan_code,'standard'),
      'core_version',coalesce(v_account.core_version,'1.0.1'),
      'target_core_version',v_account.target_core_version,
      'previous_core_version',v_account.previous_core_version,
      'release_status',coalesce(v_account.release_status,'current'),
      'deployment_status',coalesce(v_account.deployment_status,'not_configured'),
      'deployment_url',v_account.deployment_url,
      'database_project_ref',v_account.database_project_ref,
      'backup_status',coalesce(v_account.backup_status,'not_verified'),
      'last_backup_at',v_account.last_backup_at,
      'support_notes',v_account.support_notes,
      'trial_ends_at',v_account.trial_ends_at,
      'last_health_check_at',v_account.last_health_check_at
    ),
    'health_status',v_health,
    'snapshot',v_snapshot,
    'access',coalesce((
      select jsonb_agg(jsonb_build_object(
        'user_id',m.user_id,
        'role',m.role,
        'active',m.active,
        'created_at',m.created_at,
        'location_count',(
          select count(*) from public.user_location_access ula
          where ula.company_id=m.company_id and ula.user_id=m.user_id and ula.active=true
        )
      ) order by m.role,m.created_at)
      from public.company_memberships m where m.company_id=p_company_id
    ),'[]'::jsonb),
    'audit',coalesce((
      select jsonb_agg(to_jsonb(a) order by a.occurred_at desc)
      from (
        select id,request_id,actor_user_id,action,target_type,target_id,reason,before_json,after_json,occurred_at
        from private.operator_audit_events
        where company_id=p_company_id
        order by occurred_at desc
        limit 50
      ) a
    ),'[]'::jsonb),
    'release_history',coalesce((
      select jsonb_agg(to_jsonb(h) order by h.occurred_at desc)
      from (
        select id,actor_user_id,action,from_version,to_version,reason,occurred_at
        from private.customer_release_history
        where company_id=p_company_id
        order by occurred_at desc
        limit 25
      ) h
    ),'[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;

create or replace function public.operator_service_provision_customer(
  p_actor_user_id uuid,
  p_name text,
  p_slug text,
  p_timezone text,
  p_owner_email text,
  p_plan_code text,
  p_provisioning_key text,
  p_trial_days integer,
  p_request_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_company_id uuid;
  v_prior_company_id uuid;
  v_invite_id uuid;
  v_token uuid;
  v_email text:=lower(nullif(btrim(p_owner_email),''));
  v_core_version text;
  v_template_code text;
  v_template_version text;
begin
  if not exists(
    select 1 from private.platform_operators
    where user_id=p_actor_user_id and active=true and operator_role='platform_admin'
  ) then raise exception 'Platform administrator access required'; end if;

  if p_request_id is null then raise exception 'Request ID is required'; end if;
  if coalesce(p_trial_days,0) not between 0 and 365 then raise exception 'Trial days must be between 0 and 365'; end if;
  if coalesce(p_plan_code,'') !~ '^[a-z0-9][a-z0-9_-]{1,39}$' then raise exception 'Plan code is invalid'; end if;
  if v_email is not null and (position('@' in v_email)<=1 or length(v_email)>320) then raise exception 'Owner email is invalid'; end if;

  select company_id into v_prior_company_id
  from public.company_provisioning_runs where provisioning_key=p_provisioning_key;

  v_company_id:=private.provision_blank_company(
    p_name,p_slug,p_timezone,p_provisioning_key
  );

  select version_code into v_core_version
  from private.platform_releases
  where status='available'
  order by released_at desc nulls last,created_at desc
  limit 1;

  insert into private.customer_accounts(
    company_id,account_status,plan_code,trial_ends_at,core_version,
    deployment_status,backup_status,health_status,updated_at
  ) values(
    v_company_id,'trial',p_plan_code,
    case when p_trial_days>0 then now()+make_interval(days=>p_trial_days) else null end,
    coalesce(v_core_version,'1.0.1'),'provisioning','not_verified','setup_required',now()
  )
  on conflict(company_id) do update
  set plan_code=excluded.plan_code,
      trial_ends_at=coalesce(private.customer_accounts.trial_ends_at,excluded.trial_ends_at),
      core_version=coalesce(private.customer_accounts.core_version,excluded.core_version),
      updated_at=now();

  if v_email is not null then
    if exists(
      select 1
      from private.platform_operators po
      join auth.users u on u.id=po.user_id
      where lower(u.email)=v_email
    ) then raise exception 'A platform operator cannot be assigned as a customer owner'; end if;

    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(v_company_id::text||'|'||v_email||'|owner',0)
    );

    update public.access_invites
    set revoked_at=now()
    where company_id=v_company_id
      and lower(email)=v_email
      and intended_role='owner'
      and accepted_at is null
      and revoked_at is null
      and expires_at<=now();

    select id,token into v_invite_id,v_token
    from public.access_invites
    where company_id=v_company_id
      and lower(email)=v_email
      and intended_role='owner'
      and accepted_at is null
      and revoked_at is null
      and expires_at>now()
    order by created_at desc
    limit 1;

    if v_invite_id is null then
      insert into public.access_invites(
        company_id,email,intended_role,invited_by_user_id,expires_at
      ) values(
        v_company_id,v_email,'owner',p_actor_user_id,now()+interval '14 days'
      ) returning id,token into v_invite_id,v_token;
    else
      update public.access_invites
      set expires_at=now()+interval '14 days',invited_by_user_id=p_actor_user_id
      where id=v_invite_id;
    end if;
  end if;

  select t.template_code,v.version_code
    into v_template_code,v_template_version
  from public.companies c
  left join public.industry_templates t on t.id=c.industry_template_id
  left join public.industry_template_versions v on v.id=c.industry_template_version_id
  where c.id=v_company_id;

  insert into private.operator_audit_events(
    request_id,actor_user_id,company_id,action,target_type,target_id,after_json
  ) values(
    p_request_id,p_actor_user_id,v_company_id,
    case when v_prior_company_id is null then 'customer.provisioned' else 'customer.provision_retried' end,
    'company',v_company_id,
    jsonb_build_object(
      'name',btrim(p_name),'slug',p_slug,'timezone',p_timezone,
      'plan_code',p_plan_code,'owner_email',v_email,
      'template_code',v_template_code,'template_version',v_template_version
    )
  ) on conflict(request_id) do nothing;

  return jsonb_build_object(
    'company_id',v_company_id,
    'account_status',(select account_status from private.customer_accounts where company_id=v_company_id),
    'template_code',v_template_code,
    'template_version',v_template_version,
    'invite_id',v_invite_id,
    'invite_token',v_token,
    'owner_email',v_email,
    'reused',v_prior_company_id is not null
  );
end;
$$;

create or replace function public.operator_service_set_customer_status(
  p_actor_user_id uuid,
  p_company_id uuid,
  p_status text,
  p_reason text,
  p_request_id uuid
)
returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_before private.customer_accounts%rowtype;
  v_after private.customer_accounts%rowtype;
  v_held_memberships integer:=0;
  v_held_locations integer:=0;
  v_restored_memberships integer:=0;
  v_restored_locations integer:=0;
begin
  if not exists(
    select 1 from private.platform_operators
    where user_id=p_actor_user_id and active=true and operator_role='platform_admin'
  ) then raise exception 'Platform administrator access required'; end if;
  if p_request_id is null then raise exception 'Request ID is required'; end if;
  if p_status not in ('trial','active','suspended','closed') then raise exception 'Invalid customer account status'; end if;
  if p_status in ('suspended','closed') and nullif(btrim(p_reason),'') is null then
    raise exception 'A reason is required to suspend or close a customer';
  end if;
  if not exists(select 1 from public.companies where id=p_company_id) then raise exception 'Customer not found'; end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('ctod-customer-status|'||p_company_id::text,0)
  );

  insert into private.customer_accounts(company_id,account_status,customer_since)
  select c.id,case when c.status='active' then 'active' else 'suspended' end,c.created_at::date
  from public.companies c where c.id=p_company_id
  on conflict(company_id) do nothing;

  select * into v_before from private.customer_accounts where company_id=p_company_id for update;

  if v_before.account_status=p_status then
    return jsonb_build_object('company_id',p_company_id,'status',p_status,'changed',false);
  end if;

  if p_status in ('suspended','closed') then
    insert into private.customer_access_holds(
      company_id,membership_id,held_by_user_id
    )
    select p_company_id,m.id,p_actor_user_id
    from public.company_memberships m
    where m.company_id=p_company_id and m.active=true
    on conflict do nothing;
    get diagnostics v_held_memberships=row_count;

    insert into private.customer_access_holds(
      company_id,location_access_id,held_by_user_id
    )
    select p_company_id,a.id,p_actor_user_id
    from public.user_location_access a
    where a.company_id=p_company_id and a.active=true
    on conflict do nothing;
    get diagnostics v_held_locations=row_count;

    update public.user_location_access
    set active=false,revoked_at=now()
    where company_id=p_company_id and active=true;

    update public.company_memberships
    set active=false
    where company_id=p_company_id and active=true;

    -- The legacy helper's third argument is a support-note field. Lifecycle
    -- reasons belong in the immutable operator audit trail and must never
    -- overwrite the customer's standing support notes.
    perform private.operator_set_customer_status(p_company_id,p_status,null);

    update private.customer_accounts
    set suspended_at=case when p_status='suspended' then now() else suspended_at end,
        suspended_by_user_id=p_actor_user_id,
        closed_at=case when p_status='closed' then now() else closed_at end,
        health_status='blocked',
        updated_at=now()
    where company_id=p_company_id;
  else
    perform private.operator_set_customer_status(p_company_id,p_status,null);

    with restored as (
      update public.company_memberships m
      set active=true
      from private.customer_access_holds h
      where h.company_id=p_company_id
        and h.membership_id=m.id
        and h.released_at is null
      returning m.id
    ) select count(*) into v_restored_memberships from restored;

    with restored as (
      update public.user_location_access a
      set active=true,revoked_at=null
      from private.customer_access_holds h
      where h.company_id=p_company_id
        and h.location_access_id=a.id
        and h.released_at is null
      returning a.id
    ) select count(*) into v_restored_locations from restored;

    update private.customer_access_holds
    set released_at=now()
    where company_id=p_company_id and released_at is null;

    update private.customer_accounts
    set reactivated_at=now(),
        suspended_at=null,
        suspended_by_user_id=null,
        closed_at=case when p_status='active' then null else closed_at end,
        health_status='unknown',
        updated_at=now()
    where company_id=p_company_id;
  end if;

  select * into v_after from private.customer_accounts where company_id=p_company_id;

  insert into private.operator_audit_events(
    request_id,actor_user_id,company_id,action,target_type,target_id,reason,before_json,after_json
  ) values(
    p_request_id,p_actor_user_id,p_company_id,'customer.status_changed','company',p_company_id,
    nullif(btrim(p_reason),''),
    jsonb_build_object('account_status',v_before.account_status),
    jsonb_build_object(
      'account_status',v_after.account_status,
      'held_memberships',v_held_memberships,
      'held_location_access',v_held_locations,
      'restored_memberships',v_restored_memberships,
      'restored_location_access',v_restored_locations
    )
  ) on conflict(request_id) do nothing;

  insert into public.audit_events(
    company_id,actor_user_id,event_type,entity_type,entity_id,before_json,after_json,reason
  ) values(
    p_company_id,p_actor_user_id,'operator.customer_status_changed','company',p_company_id,
    jsonb_build_object('account_status',v_before.account_status),
    jsonb_build_object('account_status',v_after.account_status),
    nullif(btrim(p_reason),'')
  );

  return jsonb_build_object(
    'company_id',p_company_id,
    'status',v_after.account_status,
    'changed',true,
    'held_memberships',v_held_memberships,
    'held_location_access',v_held_locations,
    'restored_memberships',v_restored_memberships,
    'restored_location_access',v_restored_locations
  );
end;
$$;

create or replace function public.operator_service_update_customer(
  p_actor_user_id uuid,
  p_company_id uuid,
  p_plan_code text,
  p_deployment_status text,
  p_deployment_url text,
  p_database_project_ref text,
  p_backup_status text,
  p_last_backup_at timestamptz,
  p_support_notes text,
  p_request_id uuid
)
returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_before jsonb;
  v_after jsonb;
begin
  if not exists(
    select 1 from private.platform_operators
    where user_id=p_actor_user_id and active=true and operator_role='platform_admin'
  ) then raise exception 'Platform administrator access required'; end if;
  if p_request_id is null then raise exception 'Request ID is required'; end if;
  if coalesce(p_plan_code,'') !~ '^[a-z0-9][a-z0-9_-]{1,39}$' then raise exception 'Plan code is invalid'; end if;
  if p_deployment_status not in ('not_configured','provisioning','ready','degraded','failed') then raise exception 'Deployment status is invalid'; end if;
  if p_backup_status not in ('not_verified','current','stale','failed') then raise exception 'Backup status is invalid'; end if;
  if nullif(btrim(p_deployment_url),'') is not null and p_deployment_url !~ '^https://' then raise exception 'Deployment URL must use HTTPS'; end if;

  select to_jsonb(ca) into v_before from private.customer_accounts ca where company_id=p_company_id;
  if v_before is null then raise exception 'Customer account not found'; end if;

  update private.customer_accounts as ca
  set plan_code=p_plan_code,
      deployment_status=p_deployment_status,
      deployment_url=nullif(btrim(p_deployment_url),''),
      database_project_ref=nullif(btrim(p_database_project_ref),''),
      backup_status=p_backup_status,
      last_backup_at=p_last_backup_at,
      support_notes=nullif(btrim(p_support_notes),''),
      updated_at=now()
  where company_id=p_company_id
  returning to_jsonb(ca) into v_after;

  insert into private.operator_audit_events(
    request_id,actor_user_id,company_id,action,target_type,target_id,before_json,after_json
  ) values(
    p_request_id,p_actor_user_id,p_company_id,'customer.operations_updated','company',p_company_id,
    v_before,v_after
  ) on conflict(request_id) do nothing;

  return v_after;
end;
$$;

create or replace function public.operator_service_set_release(
  p_actor_user_id uuid,
  p_company_id uuid,
  p_action text,
  p_version text,
  p_reason text,
  p_request_id uuid
)
returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_account private.customer_accounts%rowtype;
  v_from text;
  v_to text;
  v_history_action text;
begin
  if not exists(
    select 1 from private.platform_operators
    where user_id=p_actor_user_id and active=true and operator_role='platform_admin'
  ) then raise exception 'Platform administrator access required'; end if;
  if p_request_id is null then raise exception 'Request ID is required'; end if;
  if p_action not in ('schedule','activate','rollback','cancel') then raise exception 'Release action is invalid'; end if;

  select * into v_account from private.customer_accounts where company_id=p_company_id for update;
  if not found then raise exception 'Customer account not found'; end if;
  v_from:=v_account.core_version;

  if p_action in ('schedule','activate') then
    if not exists(
      select 1 from private.platform_releases
      where version_code=p_version and status='available'
    ) then raise exception 'Release is not available'; end if;
    v_to:=p_version;
  elsif p_action='rollback' then
    if v_account.previous_core_version is null then raise exception 'No rollback version is available'; end if;
    v_to:=v_account.previous_core_version;
  else
    v_to:=null;
  end if;

  if p_action='schedule' then
    update private.customer_accounts
    set target_core_version=v_to,release_status='scheduled',updated_at=now()
    where company_id=p_company_id;
    v_history_action:='scheduled';
  elsif p_action='activate' then
    update private.customer_accounts
    set previous_core_version=core_version,
        core_version=v_to,
        target_core_version=null,
        release_status='rollback_available',
        updated_at=now()
    where company_id=p_company_id;
    v_history_action:='activated';
  elsif p_action='rollback' then
    update private.customer_accounts
    set core_version=v_to,
        previous_core_version=v_from,
        target_core_version=null,
        release_status='rollback_completed',
        updated_at=now()
    where company_id=p_company_id;
    v_history_action:='rolled_back';
  else
    update private.customer_accounts
    set target_core_version=null,release_status='current',updated_at=now()
    where company_id=p_company_id;
    v_history_action:='cancelled';
  end if;

  insert into private.customer_release_history(
    company_id,actor_user_id,action,from_version,to_version,reason
  ) values(
    p_company_id,p_actor_user_id,v_history_action,v_from,v_to,nullif(btrim(p_reason),'')
  );

  insert into private.operator_audit_events(
    request_id,actor_user_id,company_id,action,target_type,target_id,reason,before_json,after_json
  ) values(
    p_request_id,p_actor_user_id,p_company_id,'customer.release_'||v_history_action,
    'company',p_company_id,nullif(btrim(p_reason),''),
    jsonb_build_object('core_version',v_from,'target_version',v_account.target_core_version),
    (select jsonb_build_object(
      'core_version',core_version,'target_version',target_core_version,
      'previous_version',previous_core_version,'release_status',release_status
    ) from private.customer_accounts where company_id=p_company_id)
  ) on conflict(request_id) do nothing;

  return (
    select jsonb_build_object(
      'company_id',company_id,'core_version',core_version,
      'target_core_version',target_core_version,
      'previous_core_version',previous_core_version,
      'release_status',release_status
    ) from private.customer_accounts where company_id=p_company_id
  );
end;
$$;

create or replace function public.operator_service_upsert_operator(
  p_actor_user_id uuid,
  p_user_id uuid,
  p_operator_role text,
  p_display_name text,
  p_active boolean,
  p_request_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_before jsonb;
  v_after jsonb;
  v_active_admins integer;
begin
  if not exists(
    select 1 from private.platform_operators
    where user_id=p_actor_user_id and active=true and operator_role='platform_admin'
  ) then raise exception 'Platform administrator access required'; end if;
  if p_request_id is null then raise exception 'Request ID is required'; end if;
  if p_operator_role not in ('platform_admin','support','read_only') then raise exception 'Operator role is invalid'; end if;
  if not exists(select 1 from auth.users where id=p_user_id) then raise exception 'Auth user not found'; end if;
  if exists(select 1 from public.company_memberships where user_id=p_user_id) then
    raise exception 'Platform operators cannot also be customer company members';
  end if;

  select to_jsonb(po) into v_before from private.platform_operators po where user_id=p_user_id;

  if p_active=false and coalesce(v_before->>'operator_role','')='platform_admin' then
    select count(*) into v_active_admins
    from private.platform_operators
    where active=true and operator_role='platform_admin' and user_id<>p_user_id;
    if v_active_admins=0 then raise exception 'At least one active platform administrator is required'; end if;
  end if;

  insert into private.platform_operators as po(
    user_id,operator_role,display_name,active,created_at,updated_at
  ) values(
    p_user_id,p_operator_role,nullif(btrim(p_display_name),''),p_active,now(),now()
  )
  on conflict(user_id) do update
  set operator_role=excluded.operator_role,
      display_name=excluded.display_name,
      active=excluded.active,
      updated_at=now()
  returning to_jsonb(po) into v_after;

  insert into private.operator_audit_events(
    request_id,actor_user_id,action,target_type,target_id,before_json,after_json
  ) values(
    p_request_id,p_actor_user_id,
    case when v_before is null then 'operator.created' else 'operator.updated' end,
    'operator',p_user_id,v_before,v_after
  ) on conflict(request_id) do nothing;

  return v_after;
end;
$$;

-- Public operator endpoints are deliberately invisible to browsers. Only the
-- service key inside ctod-operator-admin may execute them.
revoke all on function public.operator_service_authorize(uuid) from public, anon, authenticated;
revoke all on function public.operator_service_touch(uuid) from public, anon, authenticated;
revoke all on function public.operator_service_dashboard(uuid) from public, anon, authenticated;
revoke all on function public.operator_service_customer_diagnostics(uuid,uuid,boolean) from public, anon, authenticated;
revoke all on function public.operator_service_provision_customer(uuid,text,text,text,text,text,text,integer,uuid) from public, anon, authenticated;
revoke all on function public.operator_service_set_customer_status(uuid,uuid,text,text,uuid) from public, anon, authenticated;
revoke all on function public.operator_service_update_customer(uuid,uuid,text,text,text,text,text,timestamptz,text,uuid) from public, anon, authenticated;
revoke all on function public.operator_service_set_release(uuid,uuid,text,text,text,uuid) from public, anon, authenticated;
revoke all on function public.operator_service_upsert_operator(uuid,uuid,text,text,boolean,uuid) from public, anon, authenticated;

grant execute on function public.operator_service_authorize(uuid) to service_role;
grant execute on function public.operator_service_touch(uuid) to service_role;
grant execute on function public.operator_service_dashboard(uuid) to service_role;
grant execute on function public.operator_service_customer_diagnostics(uuid,uuid,boolean) to service_role;
grant execute on function public.operator_service_provision_customer(uuid,text,text,text,text,text,text,integer,uuid) to service_role;
grant execute on function public.operator_service_set_customer_status(uuid,uuid,text,text,uuid) to service_role;
grant execute on function public.operator_service_update_customer(uuid,uuid,text,text,text,text,text,timestamptz,text,uuid) to service_role;
grant execute on function public.operator_service_set_release(uuid,uuid,text,text,text,uuid) to service_role;
grant execute on function public.operator_service_upsert_operator(uuid,uuid,text,text,boolean,uuid) to service_role;

comment on table private.platform_operators is 'CTOD platform identities independent of all customer memberships.';
comment on table private.operator_audit_events is 'Immutable operator control-plane audit trail with idempotent request IDs.';
comment on table private.customer_access_holds is 'Reversible access snapshot used to enforce customer suspension without deleting history.';
comment on function public.operator_service_dashboard(uuid) is 'Service-role-only lifecycle and aggregate health metadata; never returns employee or review content.';

commit;
