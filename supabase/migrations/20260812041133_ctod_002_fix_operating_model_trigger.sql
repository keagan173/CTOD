create or replace function private.sync_company_organization_mode()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_company_id uuid:=coalesce(new.company_id,old.company_id);
  v_count integer;
  v_primary uuid;
begin
  select count(*) into v_count
  from public.locations
  where company_id=v_company_id and status='active';

  select id into v_primary
  from public.locations
  where company_id=v_company_id and status='active'
  order by created_at,location_code,id
  limit 1;

  insert into public.company_settings(company_id,organization_mode,primary_location_id)
  values(v_company_id,case when v_count>1 then 'multi_site' else 'single_site' end,v_primary)
  on conflict(company_id) do update
  set organization_mode=case when v_count>1 then 'multi_site' else 'single_site' end,
      primary_location_id=case
        when company_settings.primary_location_id is not null
             and exists(select 1 from public.locations l where l.id=company_settings.primary_location_id and l.status='active')
          then company_settings.primary_location_id
        else v_primary
      end,
      updated_at=now();

  return coalesce(new,old);
end;
$$;

revoke all on function private.sync_company_organization_mode() from public,anon,authenticated;