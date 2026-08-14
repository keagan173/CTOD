begin;

alter table public.company_settings
  add column if not exists organization_mode text not null default 'single_site',
  add column if not exists primary_location_id uuid;

alter table public.company_settings drop constraint if exists company_settings_organization_mode_check;
alter table public.company_settings add constraint company_settings_organization_mode_check check (organization_mode in ('single_site','multi_site'));

do $$
begin
  if not exists (select 1 from pg_constraint where conname='company_settings_primary_location_fk') then
    alter table public.company_settings add constraint company_settings_primary_location_fk foreign key (primary_location_id) references public.locations(id) on delete set null;
  end if;
end $$;

insert into public.company_settings(company_id,organization_mode)
select c.id,case when (select count(*) from public.locations l where l.company_id=c.id and l.status='active') > 1 then 'multi_site' else 'single_site' end
from public.companies c
on conflict (company_id) do update
set organization_mode=case when (select count(*) from public.locations l where l.company_id=excluded.company_id and l.status='active') > 1 then 'multi_site' else company_settings.organization_mode end;

update public.company_settings s
set primary_location_id=x.location_id
from (
  select distinct on (l.company_id) l.company_id,l.id location_id
  from public.locations l where l.status='active'
  order by l.company_id,l.created_at,l.location_code
) x
where x.company_id=s.company_id and s.primary_location_id is null;

create or replace function public.admin_initialize_primary_site(p_company_id uuid,p_site_name text default 'Primary Site',p_location_code text default 'MAIN')
returns uuid language plpgsql security invoker set search_path='' as $$
declare
  v_location_id uuid;
  v_site_name text:=coalesce(nullif(btrim(p_site_name),''),'Primary Site');
  v_code text:=upper(coalesce(nullif(btrim(p_location_code),''),'MAIN'));
begin
  if not private.has_company_role(p_company_id,array['owner'::public.membership_role,'admin'::public.membership_role]) then raise exception 'Owner or admin access is required'; end if;
  insert into public.company_settings(company_id,organization_mode) values(p_company_id,'single_site') on conflict(company_id) do nothing;
  select s.primary_location_id into v_location_id from public.company_settings s where s.company_id=p_company_id;
  if v_location_id is not null then return v_location_id; end if;
  select l.id into v_location_id from public.locations l where l.company_id=p_company_id and l.status='active' order by l.created_at,l.location_code limit 1;
  if v_location_id is null then
    insert into public.locations(company_id,location_code,name,status) values(p_company_id,v_code,v_site_name,'active')
    on conflict(company_id,location_code) do update set name=excluded.name,status='active',updated_at=now() returning id into v_location_id;
  end if;
  update public.company_settings set primary_location_id=v_location_id,organization_mode=case when (select count(*) from public.locations l where l.company_id=p_company_id and l.status='active')>1 then 'multi_site' else 'single_site' end,updated_at=now() where company_id=p_company_id;
  return v_location_id;
end;$$;
revoke all on function public.admin_initialize_primary_site(uuid,text,text) from public,anon;
grant execute on function public.admin_initialize_primary_site(uuid,text,text) to authenticated;

create or replace function private.sync_company_organization_mode()
returns trigger language plpgsql security definer set search_path='' as $$
declare
  v_company_id uuid:=coalesce(new.company_id,old.company_id);
  v_count integer;
  v_primary uuid;
begin
  select count(*) into v_count from public.locations where company_id=v_company_id and status='active';
  select id into v_primary from public.locations where company_id=v_company_id and status='active' order by created_at,location_code,id limit 1;
  insert into public.company_settings(company_id,organization_mode,primary_location_id)
  values(v_company_id,case when v_count>1 then 'multi_site' else 'single_site' end,v_primary)
  on conflict(company_id) do update set organization_mode=case when v_count>1 then 'multi_site' else 'single_site' end,primary_location_id=case when company_settings.primary_location_id is not null and exists(select 1 from public.locations l where l.id=company_settings.primary_location_id and l.status='active') then company_settings.primary_location_id else v_primary end,updated_at=now();
  return coalesce(new,old);
end;$$;
revoke all on function private.sync_company_organization_mode() from public,anon,authenticated;
drop trigger if exists trg_sync_company_organization_mode on public.locations;
create trigger trg_sync_company_organization_mode after insert or update of status or delete on public.locations for each row execute function private.sync_company_organization_mode();

create or replace view public.v_company_operating_model with (security_invoker=true) as
select c.id company_id,c.name company_name,coalesce(s.organization_mode,'single_site') organization_mode,s.primary_location_id,pl.name primary_site_name,pl.location_code primary_site_code,count(l.id) filter(where l.status='active') active_site_count,(count(l.id) filter(where l.status='active')>1) has_multiple_sites
from public.companies c left join public.company_settings s on s.company_id=c.id left join public.locations pl on pl.id=s.primary_location_id left join public.locations l on l.company_id=c.id
group by c.id,c.name,s.organization_mode,s.primary_location_id,pl.name,pl.location_code;
grant select on public.v_company_operating_model to authenticated;

commit;