-- Master Locations access directory and safe, per-location access management.
-- These functions never modify employee, assignment, coaching, review, or goal records.

create or replace function public.admin_list_location_access()
returns table(
  location_id uuid,
  user_id uuid,
  email text,
  access_role public.membership_role,
  membership_role public.membership_role,
  granted_at timestamptz,
  access_source text
)
language plpgsql
security definer
set search_path = public, auth, pg_catalog
as $$
declare
  v_company_id uuid;
begin
  select cm.company_id
    into v_company_id
  from public.company_memberships cm
  where cm.user_id = auth.uid()
    and cm.active = true
    and cm.role in ('owner','admin','executive')
  order by case cm.role when 'owner' then 1 when 'admin' then 2 else 3 end
  limit 1;

  if v_company_id is null then
    raise exception 'Master access required';
  end if;

  return query
  with effective_access as (
    -- Owners, administrators, and executives can see every location through
    -- their company-wide role, even when they do not have a ULA row.
    select
      l.id as location_id,
      cm.user_id,
      u.email::text as email,
      cm.role as access_role,
      cm.role as membership_role,
      cm.created_at as granted_at,
      'company_wide'::text as access_source
    from public.locations l
    join public.company_memberships cm
      on cm.company_id = l.company_id
     and cm.active = true
     and cm.role in ('owner','admin','executive')
    join auth.users u on u.id = cm.user_id
    where l.company_id = v_company_id

    union all

    -- All other access is effective only when both the membership and the
    -- specific location grant are active.
    select
      ula.location_id,
      ula.user_id,
      u.email::text as email,
      ula.access_role,
      cm.role as membership_role,
      ula.granted_at,
      'location'::text as access_source
    from public.user_location_access ula
    join public.company_memberships cm
      on cm.company_id = ula.company_id
     and cm.user_id = ula.user_id
     and cm.active = true
     and cm.role not in ('owner','admin','executive')
    join auth.users u on u.id = ula.user_id
    where ula.company_id = v_company_id
      and ula.active = true
  )
  select
    ea.location_id,
    ea.user_id,
    ea.email,
    ea.access_role,
    ea.membership_role,
    ea.granted_at,
    ea.access_source
  from effective_access ea
  order by ea.location_id,
           case ea.access_source when 'company_wide' then 1 else 2 end,
           lower(ea.email);
end;
$$;

create or replace function public.admin_grant_location_access_by_email(
  p_location_id uuid,
  p_email text,
  p_access_role public.membership_role default 'manager'
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, pg_catalog
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_company_id uuid;
  v_user_id uuid;
  v_membership_role public.membership_role;
  v_membership_active boolean;
  v_derived_role public.membership_role;
begin
  select cm.company_id
    into v_company_id
  from public.company_memberships cm
  where cm.user_id = v_actor_user_id
    and cm.active = true
    and cm.role in ('owner','admin')
  order by case cm.role when 'owner' then 1 else 2 end
  limit 1;

  if v_company_id is null then
    raise exception 'Owner/Admin access required';
  end if;

  if p_access_role not in ('manager','market_leader','area_leader','viewer') then
    raise exception 'Unsupported location access role %', p_access_role;
  end if;

  if not exists (
    select 1
    from public.locations l
    where l.id = p_location_id
      and l.company_id = v_company_id
      and l.status = 'active'
  ) then
    raise exception 'Location is not active in this company';
  end if;

  select u.id
    into v_user_id
  from auth.users u
  where lower(u.email) = lower(trim(p_email))
  limit 1;

  if v_user_id is null then
    return jsonb_build_object('status','invite_required','email',lower(trim(p_email)));
  end if;

  select cm.role, cm.active
    into v_membership_role, v_membership_active
  from public.company_memberships cm
  where cm.company_id = v_company_id
    and cm.user_id = v_user_id;

  if not found or not coalesce(v_membership_active,false) then
    return jsonb_build_object(
      'status','invite_required',
      'email',lower(trim(p_email)),
      'existing_auth_user',true
    );
  end if;

  if v_membership_role in ('owner','admin','executive') then
    return jsonb_build_object(
      'status','already_company_wide',
      'email',lower(trim(p_email)),
      'user_id',v_user_id,
      'role',v_membership_role
    );
  end if;

  insert into public.user_location_access(
    company_id,
    user_id,
    location_id,
    access_role,
    active,
    granted_by_user_id,
    granted_at,
    revoked_at
  )
  values(
    v_company_id,
    v_user_id,
    p_location_id,
    p_access_role,
    true,
    v_actor_user_id,
    now(),
    null
  )
  on conflict (user_id,location_id) do update
    set access_role = excluded.access_role,
        active = true,
        granted_by_user_id = excluded.granted_by_user_id,
        granted_at = now(),
        revoked_at = null;

  select case
           when bool_or(ula.access_role = 'area_leader') then 'area_leader'::public.membership_role
           when bool_or(ula.access_role = 'market_leader') then 'market_leader'::public.membership_role
           when bool_or(ula.access_role = 'manager') then 'manager'::public.membership_role
           else 'viewer'::public.membership_role
         end
    into v_derived_role
  from public.user_location_access ula
  where ula.company_id = v_company_id
    and ula.user_id = v_user_id
    and ula.active = true;

  update public.company_memberships cm
     set active = true,
         role = coalesce(v_derived_role,p_access_role),
         location_id = null
   where cm.company_id = v_company_id
     and cm.user_id = v_user_id;

  insert into public.audit_events(
    company_id,
    actor_user_id,
    event_type,
    entity_type,
    entity_id,
    after_json
  )
  values(
    v_company_id,
    v_actor_user_id,
    'access.location_granted',
    'user',
    v_user_id,
    jsonb_build_object(
      'email',lower(trim(p_email)),
      'location_id',p_location_id,
      'access_role',p_access_role
    )
  );

  return jsonb_build_object(
    'status','granted',
    'email',lower(trim(p_email)),
    'user_id',v_user_id,
    'location_id',p_location_id,
    'access_role',p_access_role
  );
end;
$$;

create or replace function public.admin_set_location_access(
  p_location_id uuid,
  p_user_id uuid,
  p_active boolean,
  p_access_role public.membership_role default 'manager'
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, pg_catalog
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_company_id uuid;
  v_target_role public.membership_role;
  v_derived_role public.membership_role;
  v_remaining_count integer := 0;
  v_before jsonb;
begin
  select cm.company_id
    into v_company_id
  from public.company_memberships cm
  where cm.user_id = v_actor_user_id
    and cm.active = true
    and cm.role in ('owner','admin')
  order by case cm.role when 'owner' then 1 else 2 end
  limit 1;

  if v_company_id is null then
    raise exception 'Owner/Admin access required';
  end if;

  if p_access_role not in ('manager','market_leader','area_leader','viewer') then
    raise exception 'Unsupported location access role %', p_access_role;
  end if;

  if not exists (
    select 1
    from public.locations l
    where l.id = p_location_id
      and l.company_id = v_company_id
  ) then
    raise exception 'Location is not in this company';
  end if;

  select cm.role
    into v_target_role
  from public.company_memberships cm
  where cm.company_id = v_company_id
    and cm.user_id = p_user_id;

  if not found then
    raise exception 'User is not a company member';
  end if;

  if v_target_role in ('owner','admin','executive') then
    raise exception 'Company-wide access cannot be changed from a single location';
  end if;

  select to_jsonb(ula)
    into v_before
  from public.user_location_access ula
  where ula.company_id = v_company_id
    and ula.user_id = p_user_id
    and ula.location_id = p_location_id;

  if p_active then
    insert into public.user_location_access(
      company_id,
      user_id,
      location_id,
      access_role,
      active,
      granted_by_user_id,
      granted_at,
      revoked_at
    )
    values(
      v_company_id,
      p_user_id,
      p_location_id,
      p_access_role,
      true,
      v_actor_user_id,
      now(),
      null
    )
    on conflict (user_id,location_id) do update
      set access_role = excluded.access_role,
          active = true,
          granted_by_user_id = excluded.granted_by_user_id,
          granted_at = now(),
          revoked_at = null;
  else
    update public.user_location_access ula
       set active = false,
           revoked_at = now()
     where ula.company_id = v_company_id
       and ula.user_id = p_user_id
       and ula.location_id = p_location_id
       and ula.active = true;
  end if;

  select
    count(*)::integer,
    case
      when bool_or(ula.access_role = 'area_leader') then 'area_leader'::public.membership_role
      when bool_or(ula.access_role = 'market_leader') then 'market_leader'::public.membership_role
      when bool_or(ula.access_role = 'manager') then 'manager'::public.membership_role
      when count(*) > 0 then 'viewer'::public.membership_role
      else null::public.membership_role
    end
    into v_remaining_count, v_derived_role
  from public.user_location_access ula
  where ula.company_id = v_company_id
    and ula.user_id = p_user_id
    and ula.active = true;

  update public.company_memberships cm
     set active = (v_remaining_count > 0),
         role = coalesce(v_derived_role,cm.role),
         location_id = null
   where cm.company_id = v_company_id
     and cm.user_id = p_user_id;

  insert into public.audit_events(
    company_id,
    actor_user_id,
    event_type,
    entity_type,
    entity_id,
    before_json,
    after_json
  )
  values(
    v_company_id,
    v_actor_user_id,
    case when p_active then 'access.location_granted' else 'access.location_revoked' end,
    'user',
    p_user_id,
    v_before,
    jsonb_build_object(
      'location_id',p_location_id,
      'active',p_active,
      'access_role',p_access_role,
      'remaining_location_count',v_remaining_count,
      'membership_active',(v_remaining_count > 0)
    )
  );

  return jsonb_build_object(
    'status',case when p_active then 'granted' else 'revoked' end,
    'user_id',p_user_id,
    'location_id',p_location_id,
    'active',p_active,
    'remaining_location_count',v_remaining_count,
    'membership_active',(v_remaining_count > 0)
  );
end;
$$;

revoke all on function public.admin_list_location_access() from public, anon;
revoke all on function public.admin_grant_location_access_by_email(uuid,text,public.membership_role) from public, anon;
revoke all on function public.admin_set_location_access(uuid,uuid,boolean,public.membership_role) from public, anon;

grant execute on function public.admin_list_location_access() to authenticated;
grant execute on function public.admin_grant_location_access_by_email(uuid,text,public.membership_role) to authenticated;
grant execute on function public.admin_set_location_access(uuid,uuid,boolean,public.membership_role) to authenticated;

comment on function public.admin_list_location_access() is
  'Lists effective company-wide and location-scoped access for the signed-in Master user.';
comment on function public.admin_grant_location_access_by_email(uuid,text,public.membership_role) is
  'Adds one active location to an existing member, or reports that an activation invite is required.';
comment on function public.admin_set_location_access(uuid,uuid,boolean,public.membership_role) is
  'Grants or revokes one location without modifying employee or talent history.';
