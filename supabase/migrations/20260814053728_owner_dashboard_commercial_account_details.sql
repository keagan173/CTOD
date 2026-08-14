create or replace function public.operator_service_dashboard(p_actor_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare v_customers jsonb; v_summary jsonb; v_templates jsonb;
begin
  if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required'; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'company_id',c.id,'company_name',c.name,'slug',c.slug,'industry_code',c.industry_code,
    'account_status',ca.account_status,'plan_code',ca.plan_code,'customer_since',ca.customer_since,
    'trial_ends_at',ca.trial_ends_at,
    'billing_configured',(ca.external_billing_customer_id is not null and length(trim(ca.external_billing_customer_id))>0),
    'support_notes',ca.support_notes,'core_version',ca.core_version,'target_core_version',ca.target_core_version,
    'previous_core_version',ca.previous_core_version,'release_status',ca.release_status,
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
    'trial_customers',(select count(*) from private.customer_accounts where trial_ends_at is not null and trial_ends_at>now() and account_status<>'closed'),
    'billing_configured_customers',(select count(*) from private.customer_accounts where external_billing_customer_id is not null and length(trim(external_billing_customer_id))>0 and account_status<>'closed'),
    'locations',(select count(*) from public.locations where status='active'),
    'employees',(select count(*) from public.employees where employment_status='active'),
    'platform_candidate',(select version_code from private.platform_releases where status in ('candidate','validated') order by created_at desc limit 1)
  ) into v_summary;

  select coalesce(jsonb_agg(jsonb_build_object(
    'template_id',t.id,'template_code',t.template_code,'name',t.name,'description',t.description,
    'version_id',v.id,'version_code',v.version_code,'schema_version',v.schema_version
  ) order by t.template_code,v.created_at desc),'[]'::jsonb) into v_templates
  from public.industry_templates t
  join public.industry_template_versions v on v.industry_template_id=t.id
  where t.status='published' and v.status='published';

  return jsonb_build_object('summary',v_summary,'customers',v_customers,'templates',v_templates);
end $$;
