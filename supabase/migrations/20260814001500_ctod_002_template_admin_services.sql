-- CTOD 002 owner-only industry template administration
create or replace function public.operator_service_create_industry_template(
  p_actor_user_id uuid,p_template_code text,p_name text,p_description text,p_request_id uuid
)
returns jsonb language plpgsql set search_path='' as $$
declare v_id uuid; v_code text:=upper(btrim(p_template_code));
begin
  if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required'; end if;
  if p_request_id is null then raise exception 'Request ID is required'; end if;
  if v_code !~ '^[A-Z0-9][A-Z0-9_-]{1,29}$' then raise exception 'Template code is invalid'; end if;
  if nullif(btrim(p_name),'') is null then raise exception 'Template name is required'; end if;
  insert into public.industry_templates(template_code,name,description,status,is_blank_standard,metadata)
  values(v_code,btrim(p_name),nullif(btrim(p_description),''),'draft',false,jsonb_build_object('created_by','ctod_owner_console')) returning id into v_id;
  insert into private.operator_audit_events(request_id,actor_user_id,action,target_type,target_id,after_json)
  values(p_request_id,p_actor_user_id,'industry_template.created','industry_template',v_id,jsonb_build_object('template_code',v_code,'name',btrim(p_name))) on conflict(request_id) do nothing;
  return jsonb_build_object('template_id',v_id,'template_code',v_code,'name',btrim(p_name),'status','draft');
end $$;

create or replace function public.operator_service_create_template_version(
  p_actor_user_id uuid,p_template_id uuid,p_version_code text,p_schema_version text,p_configuration jsonb,p_minimum_client_version text,p_publish boolean,p_request_id uuid
)
returns jsonb language plpgsql set search_path='' as $$
declare v_id uuid; v_status text; v_code text;
begin
  if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required'; end if;
  if p_request_id is null then raise exception 'Request ID is required'; end if;
  if nullif(btrim(p_version_code),'') is null or nullif(btrim(p_schema_version),'') is null then raise exception 'Version and schema version are required'; end if;
  if p_configuration is null or jsonb_typeof(p_configuration)<>'object' then raise exception 'Template configuration must be a JSON object'; end if;
  select template_code into v_code from public.industry_templates where id=p_template_id;
  if not found then raise exception 'Industry template not found'; end if;
  v_status:=case when coalesce(p_publish,false) then 'published' else 'draft' end;
  insert into public.industry_template_versions(industry_template_id,version_code,schema_version,status,configuration,minimum_client_version,published_at)
  values(p_template_id,btrim(p_version_code),btrim(p_schema_version),v_status,p_configuration,nullif(btrim(p_minimum_client_version),''),case when p_publish then now() else null end) returning id into v_id;
  if p_publish then update public.industry_templates set status='published',updated_at=now() where id=p_template_id; end if;
  insert into private.operator_audit_events(request_id,actor_user_id,action,target_type,target_id,after_json)
  values(p_request_id,p_actor_user_id,'industry_template.version_created','industry_template_version',v_id,jsonb_build_object('template_code',v_code,'version_code',btrim(p_version_code),'status',v_status)) on conflict(request_id) do nothing;
  return jsonb_build_object('template_id',p_template_id,'version_id',v_id,'template_code',v_code,'version_code',btrim(p_version_code),'status',v_status);
end $$;

revoke all on function public.operator_service_create_industry_template(uuid,text,text,text,uuid) from public,anon,authenticated;
revoke all on function public.operator_service_create_template_version(uuid,uuid,text,text,jsonb,text,boolean,uuid) from public,anon,authenticated;
grant execute on function public.operator_service_create_industry_template(uuid,text,text,text,uuid) to service_role;
grant execute on function public.operator_service_create_template_version(uuid,uuid,text,text,jsonb,text,boolean,uuid) to service_role;
