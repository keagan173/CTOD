begin;

-- Sandbox migration history version: 20260812045037.

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

commit;
