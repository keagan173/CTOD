create or replace function public.operator_service_create_industry_bundle(
  p_actor_user_id uuid,
  p_template_code text,
  p_name text,
  p_description text,
  p_version_code text,
  p_schema_version text,
  p_configuration jsonb,
  p_minimum_client_version text,
  p_publish boolean,
  p_request_id uuid
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_template jsonb;
  v_version jsonb;
  v_template_id uuid;
begin
  if p_request_id is null then
    raise exception 'Request ID is required';
  end if;

  v_template := public.operator_service_create_industry_template(
    p_actor_user_id,
    p_template_code,
    p_name,
    p_description,
    p_request_id
  );

  v_template_id := nullif(v_template->>'template_id','')::uuid;
  if v_template_id is null then
    raise exception 'Industry template ID was not returned';
  end if;

  v_version := public.operator_service_create_template_version(
    p_actor_user_id,
    v_template_id,
    p_version_code,
    p_schema_version,
    p_configuration,
    p_minimum_client_version,
    p_publish,
    gen_random_uuid()
  );

  return jsonb_build_object(
    'template', v_template,
    'template_version', v_version
  );
end;
$$;

revoke all on function public.operator_service_create_industry_bundle(uuid,text,text,text,text,text,jsonb,text,boolean,uuid) from public, anon, authenticated;
grant execute on function public.operator_service_create_industry_bundle(uuid,text,text,text,text,text,jsonb,text,boolean,uuid) to service_role;
