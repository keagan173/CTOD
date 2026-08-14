-- Customer Executive access is allowed to manage invitations for their own company.
-- This does not grant platform configuration editing or CTOD owner privileges.

create or replace function public.create_access_invite(p_email text,p_role public.membership_role,p_location_ids uuid[] default '{}'::uuid[])
returns jsonb
language plpgsql
set search_path to 'public','pg_catalog'
as $$
declare
  v_company uuid; v_invite uuid; v_token uuid; v_location_ids uuid[]; v_loc uuid; v_reused boolean:=false; v_normalized_email text:=lower(trim(p_email));
begin
  if v_normalized_email is null or v_normalized_email='' or position('@' in v_normalized_email)<=1 then raise exception 'A valid email address is required'; end if;
  select cm.company_id into v_company from public.company_memberships cm
  where cm.user_id=(select auth.uid()) and cm.active=true and cm.role in ('owner','admin','executive')
  order by case cm.role when 'owner' then 1 when 'admin' then 2 else 3 end limit 1;
  if v_company is null then raise exception 'Owner/Admin/Executive access required'; end if;
  if p_role not in ('manager','market_leader','area_leader','executive','viewer') then raise exception 'Unsupported invited role %',p_role; end if;
  select coalesce(array_agg(distinct location_id order by location_id),'{}'::uuid[]) into v_location_ids from unnest(coalesce(p_location_ids,'{}'::uuid[])) as requested(location_id) where location_id is not null;
  if p_role in ('manager','market_leader','area_leader') and coalesce(array_length(v_location_ids,1),0)=0 then raise exception 'At least one location is required for this role'; end if;
  foreach v_loc in array v_location_ids loop
    if not exists(select 1 from public.locations l where l.id=v_loc and l.company_id=v_company and l.status='active') then raise exception 'Location % is not active in this company',v_loc; end if;
  end loop;
  perform pg_advisory_xact_lock(hashtextextended(v_company::text||'|'||v_normalized_email||'|'||p_role::text,0));
  update public.access_invites i set revoked_at=now() where i.company_id=v_company and lower(i.email)=v_normalized_email and i.intended_role=p_role and i.accepted_at is null and i.revoked_at is null and i.expires_at<=now();
  select i.id,i.token into v_invite,v_token from public.access_invites i
  where i.company_id=v_company and lower(i.email)=v_normalized_email and i.intended_role=p_role and i.accepted_at is null and i.revoked_at is null and i.expires_at>now()
    and coalesce((select array_agg(ail.location_id order by ail.location_id) from public.access_invite_locations ail where ail.invite_id=i.id),'{}'::uuid[])=v_location_ids
  order by i.created_at desc limit 1;
  if v_invite is not null then
    v_reused:=true;
    update public.access_invites set expires_at=now()+interval '14 days',invited_by_user_id=(select auth.uid()) where id=v_invite;
    update public.access_invites i set revoked_at=now() where i.id<>v_invite and i.company_id=v_company and lower(i.email)=v_normalized_email and i.intended_role=p_role and i.accepted_at is null and i.revoked_at is null and i.expires_at>now()
      and coalesce((select array_agg(ail.location_id order by ail.location_id) from public.access_invite_locations ail where ail.invite_id=i.id),'{}'::uuid[])=v_location_ids;
    insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,after_json)
    values(v_company,(select auth.uid()),'access.invite_reused','access_invite',v_invite,jsonb_build_object('email',v_normalized_email,'role',p_role,'locations',v_location_ids));
  else
    insert into public.access_invites(company_id,email,intended_role,invited_by_user_id) values(v_company,v_normalized_email,p_role,(select auth.uid())) returning id,token into v_invite,v_token;
    insert into public.access_invite_locations(invite_id,location_id) select v_invite,unnest(v_location_ids);
    insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,after_json)
    values(v_company,(select auth.uid()),'access.invite_created','access_invite',v_invite,jsonb_build_object('email',v_normalized_email,'role',p_role,'locations',v_location_ids));
  end if;
  return jsonb_build_object('invite_id',v_invite,'token',v_token,'role',p_role,'location_count',coalesce(array_length(v_location_ids,1),0),'reused',v_reused);
end $$;

create or replace function public.list_access_invites()
returns table(invite_id uuid,email text,intended_role public.membership_role,token uuid,expires_at timestamptz,accepted_at timestamptz,revoked_at timestamptz,created_at timestamptz,location_ids uuid[],location_labels text[])
language sql security definer set search_path to 'public','private'
as $$
  select i.id,i.email,i.intended_role,i.token,i.expires_at,i.accepted_at,i.revoked_at,i.created_at,
    coalesce(array_agg(l.id order by l.location_code) filter(where l.id is not null),'{}'::uuid[]),
    coalesce(array_agg(('Location '||l.location_code||' - '||l.name) order by l.location_code) filter(where l.id is not null),'{}'::text[])
  from public.access_invites i left join public.access_invite_locations ail on ail.invite_id=i.id left join public.locations l on l.id=ail.location_id
  where private.has_company_role(i.company_id,array['owner','admin','executive']::public.membership_role[])
  group by i.id order by i.created_at desc;
$$;

create or replace function public.revoke_access_invite(p_invite_id uuid)
returns void language plpgsql security definer set search_path to 'public','private'
as $$
declare v_company uuid;
begin
  select company_id into v_company from public.access_invites where id=p_invite_id;
  if v_company is null then raise exception 'Invite not found'; end if;
  if not private.has_company_role(v_company,array['owner','admin','executive']::public.membership_role[]) then raise exception 'Owner/Admin/Executive access required'; end if;
  update public.access_invites set revoked_at=now() where id=p_invite_id and accepted_at is null;
end $$;
