begin;

create table if not exists private.platform_operators (
  user_id uuid primary key references auth.users(id) on delete cascade,
  operator_role text not null default 'platform_admin' check (operator_role in ('platform_admin','support','read_only')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
revoke all on private.platform_operators from public,anon,authenticated;
grant select,insert,update,delete on private.platform_operators to service_role;

create table if not exists private.customer_accounts (
  company_id uuid primary key references public.companies(id) on delete restrict,
  account_status text not null default 'trial' check (account_status in ('trial','active','suspended','closed')),
  plan_code text not null default 'standard',
  customer_since date,
  trial_ends_at timestamptz,
  support_notes text,
  external_billing_customer_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
revoke all on private.customer_accounts from public,anon,authenticated;
grant select,insert,update on private.customer_accounts to service_role;

insert into private.customer_accounts(company_id,account_status,customer_since)
select c.id,case when c.status='active' then 'active' else 'suspended' end,c.created_at::date from public.companies c
on conflict(company_id) do nothing;

create or replace function private.is_platform_operator(p_user_id uuid default auth.uid()) returns boolean
language sql stable security definer set search_path='' as $$
  select exists(select 1 from private.platform_operators po where po.user_id=p_user_id and po.active=true);
$$;
revoke all on function private.is_platform_operator(uuid) from public,anon,authenticated;
grant execute on function private.is_platform_operator(uuid) to service_role;

create or replace function private.operator_set_customer_status(p_company_id uuid,p_status text,p_note text default null) returns void
language plpgsql security definer set search_path='' as $$
begin
  if p_status not in ('trial','active','suspended','closed') then raise exception 'Invalid customer account status'; end if;
  insert into private.customer_accounts(company_id,account_status,support_notes,customer_since,updated_at)
  values(p_company_id,p_status,p_note,case when p_status='active' then current_date else null end,now())
  on conflict(company_id) do update set account_status=excluded.account_status,support_notes=coalesce(excluded.support_notes,private.customer_accounts.support_notes),customer_since=coalesce(private.customer_accounts.customer_since,excluded.customer_since),updated_at=now();
  update public.companies set status=case when p_status in ('active','trial') then 'active' else 'inactive' end,updated_at=now() where id=p_company_id;
end;$$;
revoke all on function private.operator_set_customer_status(uuid,text,text) from public,anon,authenticated;
grant execute on function private.operator_set_customer_status(uuid,text,text) to service_role;

create or replace view public.v_my_company_master with (security_invoker=true) as
select c.id company_id,c.name company_name,c.slug,c.timezone,c.status,coalesce(s.organization_mode,'single_site') organization_mode,s.primary_location_id,
count(distinct l.id) filter(where l.status='active') active_locations,
count(distinct e.id) filter(where e.employment_status='active') active_employees,
count(distinct r.id) filter(where r.active=true) active_roles
from public.companies c
left join public.company_settings s on s.company_id=c.id
left join public.locations l on l.company_id=c.id
left join public.employees e on e.company_id=c.id
left join public.roles r on r.company_id=c.id
group by c.id,c.name,c.slug,c.timezone,c.status,s.organization_mode,s.primary_location_id;
grant select on public.v_my_company_master to authenticated;

commit;