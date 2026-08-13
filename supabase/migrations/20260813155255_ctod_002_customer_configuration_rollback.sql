create or replace function public.operator_service_discard_configuration_draft(
  p_actor_user_id uuid,
  p_company_id uuid,
  p_reason text,
  p_request_id uuid
) returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_draft uuid;
begin
  if not exists(
    select 1 from private.platform_operators
    where user_id=p_actor_user_id and active=true and operator_role='platform_admin'
  ) then raise exception 'Platform Owner access required'; end if;
  if p_request_id is null then raise exception 'Request ID is required'; end if;
  if nullif(btrim(p_reason),'') is null then raise exception 'Discard reason is required'; end if;
  select id into v_draft from public.configuration_versions where company_id=p_company_id and status='draft' order by created_at desc limit 1;
  if v_draft is null then raise exception 'Customer sandbox draft not found'; end if;
  update public.configuration_versions set status='retired' where id=v_draft and company_id=p_company_id and status='draft';
  insert into private.operator_audit_events(request_id,actor_user_id,company_id,action,target_type,target_id,reason,after_json)
  values(p_request_id,p_actor_user_id,p_company_id,'configuration.sandbox_discarded','configuration',v_draft,btrim(p_reason),jsonb_build_object('configuration_id',v_draft,'status','retired'))
  on conflict(request_id) do nothing;
  return public.operator_service_customer_configuration(p_actor_user_id,p_company_id);
end;
$$;
revoke all on function public.operator_service_discard_configuration_draft(uuid,uuid,text,uuid) from public,anon,authenticated;
grant execute on function public.operator_service_discard_configuration_draft(uuid,uuid,text,uuid) to service_role,postgres;

create or replace function public.operator_service_rollback_configuration(
  p_actor_user_id uuid,
  p_company_id uuid,
  p_target_config_version_id uuid,
  p_reason text,
  p_request_id uuid
) returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_current uuid;
  v_target public.configuration_versions%rowtype;
begin
  if not exists(
    select 1 from private.platform_operators
    where user_id=p_actor_user_id and active=true and operator_role='platform_admin'
  ) then raise exception 'Platform Owner access required'; end if;
  if p_request_id is null then raise exception 'Request ID is required'; end if;
  if nullif(btrim(p_reason),'') is null then raise exception 'Rollback reason is required'; end if;
  if exists(select 1 from public.configuration_versions where company_id=p_company_id and status='draft') then raise exception 'Discard the customer sandbox draft before rollback'; end if;
  select id into v_current from public.configuration_versions where company_id=p_company_id and status='published' order by published_at desc nulls last,created_at desc limit 1;
  if v_current is null then raise exception 'Current published configuration not found'; end if;
  if v_current=p_target_config_version_id then raise exception 'Target configuration is already live'; end if;
  select * into v_target from public.configuration_versions where id=p_target_config_version_id and company_id=p_company_id and status='retired';
  if not found then raise exception 'Rollback target is not an eligible retired customer configuration'; end if;
  if not exists(select 1 from private.customer_configuration_release_history h where h.company_id=p_company_id and (h.to_config_version_id=p_target_config_version_id or h.from_config_version_id=p_target_config_version_id)) then raise exception 'Rollback target has no customer release history'; end if;
  update public.configuration_versions set status='retired' where id=v_current and company_id=p_company_id and status='published';
  update public.configuration_versions set status='published',published_at=now() where id=p_target_config_version_id and company_id=p_company_id and status='retired';
  insert into private.customer_configuration_release_history(company_id,actor_user_id,validation_id,from_config_version_id,to_config_version_id,action,reason)
  values(p_company_id,p_actor_user_id,null,v_current,p_target_config_version_id,'rollback',btrim(p_reason));
  insert into private.operator_audit_events(request_id,actor_user_id,company_id,action,target_type,target_id,reason,before_json,after_json)
  values(p_request_id,p_actor_user_id,p_company_id,'configuration.rolled_back','configuration',p_target_config_version_id,btrim(p_reason),jsonb_build_object('configuration_id',v_current),jsonb_build_object('configuration_id',p_target_config_version_id))
  on conflict(request_id) do nothing;
  return public.operator_service_customer_configuration(p_actor_user_id,p_company_id) || jsonb_build_object('rollback',jsonb_build_object('from_config_version_id',v_current,'to_config_version_id',p_target_config_version_id));
end;
$$;
revoke all on function public.operator_service_rollback_configuration(uuid,uuid,uuid,text,uuid) from public,anon,authenticated;
grant execute on function public.operator_service_rollback_configuration(uuid,uuid,uuid,text,uuid) to service_role,postgres;
