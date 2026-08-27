create or replace function public.operator_service_list_customer_access(
  p_actor_user_id uuid,
  p_company_id uuid
) returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
begin
  if not exists(
    select 1 from private.platform_operators
    where user_id=p_actor_user_id and active=true and operator_role='platform_admin'
  ) then raise exception 'Platform administrator access required'; end if;
  if not exists(select 1 from public.companies where id=p_company_id) then raise exception 'Customer not found'; end if;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'user_id',cm.user_id,
      'email',u.email,
      'role',cm.role,
      'active',cm.active,
      'locations',case when cm.role in ('manager','market_leader','area_leader') then
        coalesce((
          select jsonb_agg(jsonb_build_object('id',l.id,'location_code',l.location_code,'name',l.name) order by l.location_code)
          from public.user_location_access ula
          join public.locations l on l.id=ula.location_id
          where ula.company_id=cm.company_id and ula.user_id=cm.user_id and ula.active=true
        ),'[]'::jsonb)
      else '[]'::jsonb end
    ) order by lower(u.email::text))
    from public.company_memberships cm
    join auth.users u on u.id=cm.user_id
    where cm.company_id=p_company_id
      and cm.active=true
      and cm.role in ('manager','market_leader','area_leader','executive','viewer')
      and not exists(
        select 1 from private.platform_operators po
        where po.user_id=cm.user_id and po.active=true
      )
  ),'[]'::jsonb);
end $$;

create or replace function public.operator_service_update_customer_user_access(
  p_actor_user_id uuid,
  p_company_id uuid,
  p_user_id uuid,
  p_role public.membership_role,
  p_location_ids uuid[] default '{}'::uuid[],
  p_request_id uuid default gen_random_uuid()
) returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_location_ids uuid[];
  v_loc uuid;
  v_before jsonb;
  v_email text;
begin
  if not exists(
    select 1 from private.platform_operators
    where user_id=p_actor_user_id and active=true and operator_role='platform_admin'
  ) then raise exception 'Platform administrator access required'; end if;
  if p_role not in ('manager','market_leader','area_leader','executive','viewer') then raise exception 'Unsupported access role %',p_role; end if;
  if exists(select 1 from private.platform_operators where user_id=p_user_id and active=true) then raise exception 'Platform Owner access cannot be changed from customer access management'; end if;
  if not exists(select 1 from public.company_memberships where company_id=p_company_id and user_id=p_user_id and active=true) then raise exception 'Active customer user not found'; end if;

  select lower(u.email::text) into v_email from auth.users u where u.id=p_user_id;
  select coalesce(array_agg(distinct x order by x),'{}'::uuid[])
    into v_location_ids
  from unnest(coalesce(p_location_ids,'{}'::uuid[])) x
  where x is not null;

  if p_role in ('manager','market_leader','area_leader') and coalesce(array_length(v_location_ids,1),0)=0 then
    raise exception 'At least one location is required for this role';
  end if;
  if p_role in ('executive','viewer') then v_location_ids='{}'::uuid[]; end if;

  foreach v_loc in array v_location_ids loop
    if not exists(select 1 from public.locations where id=v_loc and company_id=p_company_id and status='active') then
      raise exception 'Location % is not active in this customer',v_loc;
    end if;
  end loop;

  select jsonb_build_object(
    'role',cm.role,
    'locations',coalesce((select jsonb_agg(ula.location_id order by ula.location_id) from public.user_location_access ula where ula.company_id=p_company_id and ula.user_id=p_user_id and ula.active=true),'[]'::jsonb)
  ) into v_before
  from public.company_memberships cm
  where cm.company_id=p_company_id and cm.user_id=p_user_id;

  update public.company_memberships set role=p_role, location_id=null, active=true
  where company_id=p_company_id and user_id=p_user_id;

  update public.user_location_access set active=false, revoked_at=now()
  where company_id=p_company_id and user_id=p_user_id and active=true;

  if p_role in ('manager','market_leader','area_leader') then
    insert into public.user_location_access(company_id,user_id,location_id,access_role,granted_by_user_id,granted_at,active,revoked_at)
    select p_company_id,p_user_id,x,p_role,p_actor_user_id,now(),true,null from unnest(v_location_ids) x
    on conflict (user_id,location_id) do update set company_id=excluded.company_id,access_role=excluded.access_role,granted_by_user_id=excluded.granted_by_user_id,granted_at=excluded.granted_at,active=true,revoked_at=null;
  end if;

  insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,before_json,after_json)
  values(p_company_id,p_actor_user_id,'platform_owner.customer_user_access_updated','company_membership',p_user_id,v_before,jsonb_build_object('email',v_email,'role',p_role,'locations',v_location_ids,'request_id',p_request_id));

  return jsonb_build_object('user_id',p_user_id,'email',v_email,'role',p_role,'location_ids',v_location_ids,'location_count',coalesce(array_length(v_location_ids,1),0));
end $$;

revoke all on function public.operator_service_list_customer_access(uuid,uuid) from public,anon,authenticated;
revoke all on function public.operator_service_update_customer_user_access(uuid,uuid,uuid,public.membership_role,uuid[],uuid) from public,anon,authenticated;
grant execute on function public.operator_service_list_customer_access(uuid,uuid) to service_role;
grant execute on function public.operator_service_update_customer_user_access(uuid,uuid,uuid,public.membership_role,uuid[],uuid) to service_role;
