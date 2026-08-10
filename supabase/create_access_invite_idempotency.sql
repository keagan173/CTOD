-- Reuse an equivalent pending invite instead of creating duplicate access rows.
-- A deliberate resend uses the same token/record and a new delivery request ID.

create index if not exists idx_access_invites_pending_scope
  on public.access_invites(company_id,lower(email),intended_role,created_at desc)
  where accepted_at is null and revoked_at is null;

create or replace function public.create_access_invite(
  p_email text,
  p_role public.membership_role,
  p_location_ids uuid[] default '{}'::uuid[]
)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_catalog
as $$
declare
  v_company uuid;
  v_invite uuid;
  v_token uuid;
  v_location_ids uuid[];
  v_loc uuid;
  v_reused boolean := false;
  v_normalized_email text := lower(trim(p_email));
begin
  if v_normalized_email is null
     or v_normalized_email = ''
     or position('@' in v_normalized_email) <= 1 then
    raise exception 'A valid email address is required';
  end if;

  select cm.company_id
    into v_company
  from public.company_memberships cm
  where cm.user_id = (select auth.uid())
    and cm.active = true
    and cm.role in ('owner','admin')
  order by case cm.role when 'owner' then 1 else 2 end
  limit 1;

  if v_company is null then
    raise exception 'Owner/Admin access required';
  end if;

  if p_role not in ('manager','market_leader','area_leader','executive','viewer') then
    raise exception 'Unsupported invited role %', p_role;
  end if;

  select coalesce(array_agg(distinct location_id order by location_id), '{}'::uuid[])
    into v_location_ids
  from unnest(coalesce(p_location_ids, '{}'::uuid[])) as requested(location_id)
  where location_id is not null;

  if p_role in ('manager','market_leader','area_leader')
     and coalesce(array_length(v_location_ids,1),0) = 0 then
    raise exception 'At least one location is required for this role';
  end if;

  foreach v_loc in array v_location_ids loop
    if not exists (
      select 1
      from public.locations l
      where l.id = v_loc
        and l.company_id = v_company
        and l.status = 'active'
    ) then
      raise exception 'Location % is not active in this company', v_loc;
    end if;
  end loop;

  -- Serialize create/resend decisions for the same company, recipient and role.
  perform pg_advisory_xact_lock(
    hashtextextended(v_company::text || '|' || v_normalized_email || '|' || p_role::text, 0)
  );

  update public.access_invites i
     set revoked_at = now()
   where i.company_id = v_company
     and lower(i.email) = v_normalized_email
     and i.intended_role = p_role
     and i.accepted_at is null
     and i.revoked_at is null
     and i.expires_at <= now();

  select i.id, i.token
    into v_invite, v_token
  from public.access_invites i
  where i.company_id = v_company
    and lower(i.email) = v_normalized_email
    and i.intended_role = p_role
    and i.accepted_at is null
    and i.revoked_at is null
    and i.expires_at > now()
    and coalesce((
      select array_agg(ail.location_id order by ail.location_id)
      from public.access_invite_locations ail
      where ail.invite_id = i.id
    ), '{}'::uuid[]) = v_location_ids
  order by i.created_at desc
  limit 1;

  if v_invite is not null then
    v_reused := true;

    update public.access_invites
       set expires_at = now() + interval '14 days',
           invited_by_user_id = (select auth.uid())
     where id = v_invite;

    -- Repair any historical duplicate with the exact same pending scope.
    update public.access_invites i
       set revoked_at = now()
     where i.id <> v_invite
       and i.company_id = v_company
       and lower(i.email) = v_normalized_email
       and i.intended_role = p_role
       and i.accepted_at is null
       and i.revoked_at is null
       and i.expires_at > now()
       and coalesce((
         select array_agg(ail.location_id order by ail.location_id)
         from public.access_invite_locations ail
         where ail.invite_id = i.id
       ), '{}'::uuid[]) = v_location_ids;

    insert into public.audit_events(
      company_id,
      actor_user_id,
      event_type,
      entity_type,
      entity_id,
      after_json
    )
    values(
      v_company,
      (select auth.uid()),
      'access.invite_reused',
      'access_invite',
      v_invite,
      jsonb_build_object(
        'email',v_normalized_email,
        'role',p_role,
        'locations',v_location_ids
      )
    );
  else
    insert into public.access_invites(
      company_id,
      email,
      intended_role,
      invited_by_user_id
    )
    values(
      v_company,
      v_normalized_email,
      p_role,
      (select auth.uid())
    )
    returning id, token into v_invite, v_token;

    insert into public.access_invite_locations(invite_id,location_id)
    select v_invite, unnest(v_location_ids);

    insert into public.audit_events(
      company_id,
      actor_user_id,
      event_type,
      entity_type,
      entity_id,
      after_json
    )
    values(
      v_company,
      (select auth.uid()),
      'access.invite_created',
      'access_invite',
      v_invite,
      jsonb_build_object(
        'email',v_normalized_email,
        'role',p_role,
        'locations',v_location_ids
      )
    );
  end if;

  return jsonb_build_object(
    'invite_id',v_invite,
    'token',v_token,
    'role',p_role,
    'location_count',coalesce(array_length(v_location_ids,1),0),
    'reused',v_reused
  );
end;
$$;

revoke all on function public.create_access_invite(text,public.membership_role,uuid[]) from public, anon;
grant execute on function public.create_access_invite(text,public.membership_role,uuid[]) to authenticated;

comment on function public.create_access_invite(text,public.membership_role,uuid[]) is
  'Creates one pending access invite per exact recipient/role/location scope, or reuses it for a deliberate resend.';
