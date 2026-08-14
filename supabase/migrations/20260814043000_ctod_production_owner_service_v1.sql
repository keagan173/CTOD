begin;

create or replace function public.operator_service_dashboard(p_actor_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_customers jsonb; v_summary jsonb; v_templates jsonb;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then
  raise exception 'Platform administrator access required';
 end if;
 select coalesce(jsonb_agg(jsonb_build_object(
  'company_id',c.id,'company_name',c.name,'slug',c.slug,'industry_code',c.industry_code,
  'account_status',ca.account_status,'plan_code',ca.plan_code,'core_version',ca.core_version,
  'target_core_version',ca.target_core_version,'release_status',ca.release_status,
  'organization_mode',coalesce(cs.organization_mode,'single_site'),
  'active_locations',(select count(*) from public.locations l where l.company_id=c.id and l.status='active'),
  'active_employees',(select count(*) from public.employees e where e.company_id=c.id and e.employment_status='active'),
  'active_roles',(select count(*) from public.roles r where r.company_id=c.id and r.active=true),
  'template_code',t.template_code,'template_name',t.name,'template_version',tv.version_code
 ) order by c.name),'[]'::jsonb) into v_customers
 from public.companies c
 join private.customer_accounts ca on ca.company_id=c.id
 left join public.company_settings cs on cs.company_id=c.id
 left join public.industry_templates t on t.id=c.industry_template_id
 left join public.industry_template_versions tv on tv.id=c.industry_template_version_id;

 select jsonb_build_object(
  'customers',(select count(*) from private.customer_accounts where account_status<>'closed'),
  'active_customers',(select count(*) from private.customer_accounts where account_status='active'),
  'locations',(select count(*) from public.locations where status='active'),
  'employees',(select count(*) from public.employees where employment_status='active'),
  'platform_candidate',(select version_code from private.platform_releases where status in ('candidate','validated') order by created_at desc limit 1)
 ) into v_summary;

 select coalesce(jsonb_agg(jsonb_build_object(
  'template_id',t.id,'template_code',t.template_code,'name',t.name,'description',t.description,
  'version_id',v.id,'version_code',v.version_code,'schema_version',v.schema_version
 ) order by t.template_code,v.created_at desc),'[]'::jsonb) into v_templates
 from public.industry_templates t join public.industry_template_versions v on v.industry_template_id=t.id
 where t.status='published' and v.status='published';

 return jsonb_build_object('summary',v_summary,'customers',v_customers,'templates',v_templates);
end $$;

create or replace function public.operator_service_platform_releases(p_actor_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_result jsonb;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required'; end if;
 select coalesce(jsonb_agg(jsonb_build_object(
  'id',r.id,'version_code',r.version_code,'status',r.status,'minimum_schema_version',r.minimum_schema_version,
  'release_notes',r.release_notes,'released_at',r.released_at,'created_at',r.created_at,
  'targets',(select coalesce(jsonb_agg(jsonb_build_object('company_id',t.company_id,'company_name',c.name,'rollout_stage',t.rollout_stage,'status',t.status)), '[]'::jsonb) from private.platform_release_targets t join public.companies c on c.id=t.company_id where t.release_id=r.id)
 ) order by r.created_at desc),'[]'::jsonb) into v_result from private.platform_releases r;
 return v_result;
end $$;

create or replace function public.operator_service_provision_blank_customer(
 p_actor_user_id uuid,p_name text,p_slug text,p_timezone text,p_plan_code text,p_trial_days integer,p_provisioning_key text
) returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_company_id uuid;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required'; end if;
 v_company_id:=private.provision_blank_company(p_name,p_slug,p_timezone,p_provisioning_key);
 update private.customer_accounts set plan_code=coalesce(nullif(btrim(p_plan_code),''),'standard'),trial_ends_at=case when coalesce(p_trial_days,0)>0 then now()+make_interval(days=>p_trial_days) else null end,updated_at=now() where company_id=v_company_id;
 return (select jsonb_build_object('company_id',c.id,'name',c.name,'slug',c.slug,'template_code',t.template_code,'template_version',v.version_code,'account_status',ca.account_status,'plan_code',ca.plan_code) from public.companies c join private.customer_accounts ca on ca.company_id=c.id left join public.industry_templates t on t.id=c.industry_template_id left join public.industry_template_versions v on v.id=c.industry_template_version_id where c.id=v_company_id);
end $$;

revoke all on function public.operator_service_dashboard(uuid) from public,anon,authenticated;
revoke all on function public.operator_service_platform_releases(uuid) from public,anon,authenticated;
revoke all on function public.operator_service_provision_blank_customer(uuid,text,text,text,text,integer,text) from public,anon,authenticated;
grant execute on function public.operator_service_dashboard(uuid) to service_role;
grant execute on function public.operator_service_platform_releases(uuid) to service_role;
grant execute on function public.operator_service_provision_blank_customer(uuid,text,text,text,text,integer,text) to service_role;

commit;
