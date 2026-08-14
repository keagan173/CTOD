create or replace function public.operator_service_list_access_invites(
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
      'id',i.id,'email',i.email,'role',i.intended_role,'expires_at',i.expires_at,
      'accepted_at',i.accepted_at,'revoked_at',i.revoked_at,'created_at',i.created_at,
      'status',case when i.accepted_at is not null then 'accepted' when i.revoked_at is not null then 'revoked' when i.expires_at<=now() then 'expired' else 'pending' end,
      'locations',coalesce((select jsonb_agg(jsonb_build_object('id',l.id,'location_code',l.location_code,'name',l.name) order by l.location_code)
        from public.access_invite_locations ail join public.locations l on l.id=ail.location_id where ail.invite_id=i.id),'[]'::jsonb)
    ) order by i.created_at desc) from public.access_invites i where i.company_id=p_company_id
  ),'[]'::jsonb);
end $$;

create or replace function public.operator_service_create_access_invite(
  p_actor_user_id uuid,p_company_id uuid,p_email text,p_role public.membership_role,
  p_location_ids uuid[] default '{}'::uuid[],p_request_id uuid default gen_random_uuid()
) returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_email text:=lower(trim(p_email)); v_invite uuid; v_token uuid; v_location_ids uuid[]; v_loc uuid; v_reused boolean:=false;
begin
  if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required'; end if;
  if not exists(select 1 from public.companies where id=p_company_id and status='active') then raise exception 'Active customer not found'; end if;
  if v_email is null or v_email='' or position('@' in v_email)<=1 then raise exception 'A valid email address is required'; end if;
  if p_role not in ('manager','market_leader','area_leader','executive','viewer') then raise exception 'Unsupported invited role %',p_role; end if;
  select coalesce(array_agg(distinct x order by x),'{}'::uuid[]) into v_location_ids from unnest(coalesce(p_location_ids,'{}'::uuid[])) x where x is not null;
  if p_role in ('manager','market_leader','area_leader') and coalesce(array_length(v_location_ids,1),0)=0 then raise exception 'At least one location is required for this role'; end if;
  foreach v_loc in array v_location_ids loop
    if not exists(select 1 from public.locations where id=v_loc and company_id=p_company_id and status='active') then raise exception 'Location % is not active in this customer',v_loc; end if;
  end loop;
  perform pg_advisory_xact_lock(hashtextextended(p_company_id::text||'|'||v_email||'|'||p_role::text,0));
  update public.access_invites set revoked_at=now() where company_id=p_company_id and lower(email)=v_email and intended_role=p_role and accepted_at is null and revoked_at is null and expires_at<=now();
  select i.id,i.token into v_invite,v_token from public.access_invites i where i.company_id=p_company_id and lower(i.email)=v_email and i.intended_role=p_role and i.accepted_at is null and i.revoked_at is null and i.expires_at>now()
    and coalesce((select array_agg(ail.location_id order by ail.location_id) from public.access_invite_locations ail where ail.invite_id=i.id),'{}'::uuid[])=v_location_ids order by i.created_at desc limit 1;
  if v_invite is not null then
    v_reused:=true; update public.access_invites set expires_at=now()+interval '14 days',invited_by_user_id=p_actor_user_id where id=v_invite;
  else
    insert into public.access_invites(company_id,email,intended_role,invited_by_user_id) values(p_company_id,v_email,p_role,p_actor_user_id) returning id,token into v_invite,v_token;
    insert into public.access_invite_locations(invite_id,location_id) select v_invite,unnest(v_location_ids);
  end if;
  insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,after_json)
  values(p_company_id,p_actor_user_id,case when v_reused then 'platform_owner.access_invite_reused' else 'platform_owner.access_invite_created' end,'access_invite',v_invite,
    jsonb_build_object('email',v_email,'role',p_role,'locations',v_location_ids,'request_id',p_request_id));
  return jsonb_build_object('invite_id',v_invite,'token',v_token,'role',p_role,'location_count',coalesce(array_length(v_location_ids,1),0),'reused',v_reused);
end $$;

create or replace function public.operator_service_revoke_access_invite(
  p_actor_user_id uuid,p_company_id uuid,p_invite_id uuid,p_reason text default 'Revoked by CTOD Platform Owner',p_request_id uuid default gen_random_uuid()
) returns jsonb
language plpgsql
security definer
set search_path=''
as $$
begin
  if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required'; end if;
  if not exists(select 1 from public.access_invites where id=p_invite_id and company_id=p_company_id) then raise exception 'Invite not found for this customer'; end if;
  update public.access_invites set revoked_at=coalesce(revoked_at,now()) where id=p_invite_id and company_id=p_company_id and accepted_at is null;
  insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,after_json)
  values(p_company_id,p_actor_user_id,'platform_owner.access_invite_revoked','access_invite',p_invite_id,jsonb_build_object('reason',coalesce(nullif(trim(p_reason),''),'Revoked by CTOD Platform Owner'),'request_id',p_request_id));
  return jsonb_build_object('invite_id',p_invite_id,'revoked',true);
end $$;

revoke all on function public.operator_service_list_access_invites(uuid,uuid) from public,anon,authenticated;
revoke all on function public.operator_service_create_access_invite(uuid,uuid,text,public.membership_role,uuid[],uuid) from public,anon,authenticated;
revoke all on function public.operator_service_revoke_access_invite(uuid,uuid,uuid,text,uuid) from public,anon,authenticated;
grant execute on function public.operator_service_list_access_invites(uuid,uuid) to service_role;
grant execute on function public.operator_service_create_access_invite(uuid,uuid,text,public.membership_role,uuid[],uuid) to service_role;
grant execute on function public.operator_service_revoke_access_invite(uuid,uuid,uuid,text,uuid) to service_role;
