-- CTOD 002 generic template materializer
create or replace function private.provision_company_from_template(
  p_name text,p_slug text,p_timezone text,p_provisioning_key text,p_template_code text,p_template_version_code text default null
)
returns uuid language plpgsql security definer set search_path='' as $$
declare
  v_company_id uuid; v_template_id uuid; v_template_version_id uuid; v_template_version text; v_schema_version text;
  v_configuration jsonb; v_existing_status text; v_config_version_id uuid; v_role jsonb; v_question jsonb; v_location jsonb; v_role_id uuid;
begin
  if nullif(btrim(p_name),'') is null then raise exception 'Company name is required'; end if;
  if p_slug is null or p_slug !~ '^[a-z0-9]+(?:-[a-z0-9]+)*$' then raise exception 'Company slug is invalid'; end if;
  if nullif(btrim(p_timezone),'') is null then raise exception 'Company timezone is required'; end if;
  if nullif(btrim(p_provisioning_key),'') is null then raise exception 'Provisioning key is required'; end if;
  if nullif(btrim(p_template_code),'') is null then raise exception 'Template code is required'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_provisioning_key,0));
  select r.company_id,r.status into v_company_id,v_existing_status from public.company_provisioning_runs r where r.provisioning_key=p_provisioning_key;
  if v_existing_status='completed' and v_company_id is not null then return v_company_id; end if;
  select t.id,v.id,v.version_code,v.schema_version,v.configuration into v_template_id,v_template_version_id,v_template_version,v_schema_version,v_configuration
  from public.industry_templates t join public.industry_template_versions v on v.industry_template_id=t.id
  where t.template_code=upper(btrim(p_template_code)) and t.status='published' and v.status='published'
    and (p_template_version_code is null or v.version_code=p_template_version_code)
  order by case when p_template_version_code is not null and v.version_code=p_template_version_code then 0 else 1 end,v.published_at desc nulls last,v.created_at desc limit 1;
  if v_template_id is null then raise exception 'Published industry template/version is unavailable'; end if;
  insert into public.company_provisioning_runs(provisioning_key,template_code,requested_name,requested_slug,status)
  values(p_provisioning_key,upper(btrim(p_template_code)),btrim(p_name),p_slug,'pending')
  on conflict(provisioning_key) do update set requested_name=excluded.requested_name,requested_slug=excluded.requested_slug,template_code=excluded.template_code
  returning company_id into v_company_id;
  if v_company_id is not null then return v_company_id; end if;
  insert into public.companies(industry_code,name,slug,timezone,status,branding,industry_template_id,industry_template_version_id,provisioned_at)
  values(upper(btrim(p_template_code)),btrim(p_name),p_slug,p_timezone,'active','{}'::jsonb,v_template_id,v_template_version_id,now()) returning id into v_company_id;
  insert into public.configuration_versions(company_id,schema_version,version_label,status,minimum_client_version,published_at)
  values(v_company_id,v_schema_version,upper(btrim(p_template_code))||' Template '||v_template_version,'published'::public.config_status,v_schema_version,now()) returning id into v_config_version_id;
  if jsonb_typeof(v_configuration->'default_location')='object' then
    v_location:=v_configuration->'default_location';
    insert into public.locations(company_id,location_code,name,status,address_line1,city,state_code,postal_code,market_name,area_name)
    values(v_company_id,coalesce(nullif(v_location->>'location_code',''),'001'),coalesce(nullif(v_location->>'name',''),'Main Location'),'active',nullif(v_location->>'address_line1',''),nullif(v_location->>'city',''),nullif(v_location->>'state_code',''),nullif(v_location->>'postal_code',''),nullif(v_location->>'market_name',''),nullif(v_location->>'area_name',''))
    on conflict(company_id,location_code) do nothing;
  end if;
  for v_role in select value from jsonb_array_elements(coalesce(v_configuration->'roles','[]'::jsonb)) loop
    if nullif(btrim(v_role->>'title'),'') is not null then
      insert into public.roles(company_id,title,active,sort_order)
      values(v_company_id,btrim(v_role->>'title'),coalesce((v_role->>'active')::boolean,true),coalesce((v_role->>'sort_order')::integer,0))
      on conflict(company_id,title) do update set active=excluded.active,sort_order=excluded.sort_order;
    end if;
  end loop;
  for v_question in select value from jsonb_array_elements(coalesce(v_configuration->'questions','[]'::jsonb)) loop
    v_role_id:=null;
    if nullif(btrim(v_question->>'role_title'),'') is not null then select id into v_role_id from public.roles where company_id=v_company_id and title=btrim(v_question->>'role_title') limit 1; end if;
    if nullif(btrim(v_question->>'question_code'),'') is not null and nullif(btrim(v_question->>'question_text'),'') is not null then
      insert into public.question_definitions(company_id,config_version_id,role_id,question_code,section_code,section_name,question_text,category,active,sort_order,question_weight,section_weight,requires_rating,requires_reason,notes_required_for_exceptional,notes_required_for_unsatisfactory)
      values(v_company_id,v_config_version_id,v_role_id,btrim(v_question->>'question_code'),coalesce(nullif(btrim(v_question->>'section_code'),''),'GENERAL'),coalesce(nullif(btrim(v_question->>'section_name'),''),'General'),btrim(v_question->>'question_text'),nullif(btrim(v_question->>'category'),''),coalesce((v_question->>'active')::boolean,true),coalesce((v_question->>'sort_order')::integer,0),coalesce((v_question->>'question_weight')::numeric,0),coalesce((v_question->>'section_weight')::numeric,0),coalesce((v_question->>'requires_rating')::boolean,true),coalesce((v_question->>'requires_reason')::boolean,true),coalesce((v_question->>'notes_required_for_exceptional')::boolean,true),coalesce((v_question->>'notes_required_for_unsatisfactory')::boolean,true))
      on conflict(config_version_id,question_code) do nothing;
    end if;
  end loop;
  insert into public.company_template_lineage(company_id,industry_template_id,industry_template_version_id,provisioning_key,active,provisioned_at,metadata)
  values(v_company_id,v_template_id,v_template_version_id,p_provisioning_key,true,now(),jsonb_build_object('source','industry_template','template_code',upper(btrim(p_template_code)),'template_version',v_template_version));
  update public.company_provisioning_runs set company_id=v_company_id,status='completed',completed_at=now() where provisioning_key=p_provisioning_key;
  return v_company_id;
end $$;
