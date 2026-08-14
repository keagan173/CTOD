create or replace function public.operator_service_customer_configuration(p_actor_user_id uuid,p_company_id uuid)
returns jsonb
language plpgsql
stable security definer
set search_path to ''
as $$
declare v_config uuid;v_result jsonb;
begin
  if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true) then raise exception 'Platform operator access required'; end if;
  if not exists(select 1 from public.companies where id=p_company_id) then raise exception 'Customer not found'; end if;
  select id into v_config from public.configuration_versions where company_id=p_company_id and status in('draft','published') order by case when status='draft' then 0 else 1 end,created_at desc limit 1;
  select jsonb_build_object(
    'company',(select jsonb_build_object('company_id',c.id,'name',c.name,'slug',c.slug,'timezone',c.timezone,'industry_code',c.industry_code,'status',c.status) from public.companies c where c.id=p_company_id),
    'active_configuration',(select jsonb_build_object('id',cv.id,'version_label',cv.version_label,'schema_version',cv.schema_version,'status',cv.status,'created_at',cv.created_at,'published_at',cv.published_at) from public.configuration_versions cv where cv.id=v_config),
    'published_configuration',(select jsonb_build_object('id',cv.id,'version_label',cv.version_label,'schema_version',cv.schema_version,'status',cv.status,'created_at',cv.created_at,'published_at',cv.published_at) from public.configuration_versions cv where cv.company_id=p_company_id and cv.status='published' order by cv.published_at desc nulls last,cv.created_at desc limit 1),
    'draft_configuration',(select jsonb_build_object('id',cv.id,'version_label',cv.version_label,'schema_version',cv.schema_version,'status',cv.status,'created_at',cv.created_at) from public.configuration_versions cv where cv.company_id=p_company_id and cv.status='draft' order by cv.created_at desc limit 1),
    'locations',coalesce((select jsonb_agg(jsonb_build_object('id',l.id,'location_code',l.location_code,'name',l.name,'status',l.status,'city',l.city,'state_code',l.state_code,'market_name',l.market_name,'area_name',l.area_name) order by l.location_code) from public.locations l where l.company_id=p_company_id),'[]'::jsonb),
    'roles',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'title',r.title,'active',r.active,'sort_order',r.sort_order) order by r.sort_order,r.title) from public.roles r where r.company_id=p_company_id),'[]'::jsonb),
    'questions',coalesce((select jsonb_agg(jsonb_build_object('id',q.id,'role_id',q.role_id,'question_code',q.question_code,'section_name',q.section_name,'question_text',q.question_text,'category',q.category,'active',q.active,'sort_order',q.sort_order) order by q.section_name,q.sort_order,q.question_code) from public.question_definitions q where q.company_id=p_company_id and q.config_version_id=v_config),'[]'::jsonb),
    'ratings',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'code',r.code,'label',r.label,'score_value',r.score_value,'sort_order',r.sort_order) order by r.sort_order) from public.rating_scale_items r where r.company_id=p_company_id and r.config_version_id=v_config),'[]'::jsonb),
    'validations',coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'config_version_id',v.config_version_id,'checksum',v.checksum,'passed',v.passed,'checks',v.checks,'created_at',v.created_at) order by v.created_at desc) from private.customer_configuration_validations v where v.company_id=p_company_id),'[]'::jsonb),
    'release_history',coalesce((select jsonb_agg(jsonb_build_object('id',h.id,'validation_id',h.validation_id,'from_config_version_id',h.from_config_version_id,'to_config_version_id',h.to_config_version_id,'action',h.action,'reason',h.reason,'created_at',h.created_at) order by h.created_at desc) from private.customer_configuration_release_history h where h.company_id=p_company_id),'[]'::jsonb)
  ) into v_result;
  return v_result;
end $$;
