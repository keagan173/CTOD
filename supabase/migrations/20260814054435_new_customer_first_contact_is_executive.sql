create or replace function public.operator_service_provision_customer_v2(p_actor_user_id uuid, p_name text, p_slug text, p_timezone text, p_owner_email text, p_plan_code text, p_provisioning_key text, p_trial_days integer, p_template_code text, p_template_version_code text, p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare v_company_id uuid;v_prior_company_id uuid;v_invite_id uuid;v_token uuid;v_email text:=lower(nullif(btrim(p_owner_email),''));v_template_code text;v_template_version text;v_core_version text;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required';end if;
 if p_request_id is null then raise exception 'Request ID is required';end if;
 if coalesce(p_trial_days,0) not between 0 and 365 then raise exception 'Trial days must be between 0 and 365';end if;
 if coalesce(p_plan_code,'') !~ '^[a-z0-9][a-z0-9_-]{1,39}$' then raise exception 'Plan code is invalid';end if;
 if v_email is not null and(position('@' in v_email)<=1 or length(v_email)>320) then raise exception 'Executive email is invalid';end if;
 select company_id into v_prior_company_id from public.company_provisioning_runs where provisioning_key=p_provisioning_key;
 v_company_id:=private.provision_company_from_template(p_name,p_slug,p_timezone,p_provisioning_key,p_template_code,p_template_version_code);
 select version_code into v_core_version from private.platform_releases where status='available' order by released_at desc nulls last,created_at desc limit 1;
 insert into private.customer_accounts(company_id,account_status,plan_code,trial_ends_at,core_version,release_status,updated_at) values(v_company_id,'trial',p_plan_code,case when p_trial_days>0 then now()+make_interval(days=>p_trial_days) else null end,coalesce(v_core_version,'1.0.1'),'current',now()) on conflict(company_id) do update set plan_code=excluded.plan_code,trial_ends_at=coalesce(private.customer_accounts.trial_ends_at,excluded.trial_ends_at),core_version=case when v_prior_company_id is null then excluded.core_version else private.customer_accounts.core_version end,updated_at=now();
 if v_email is not null then
  if exists(select 1 from private.platform_operators po join auth.users u on u.id=po.user_id where lower(u.email)=v_email) then raise exception 'A platform operator cannot be assigned as a customer executive';end if;
  update public.access_invites set revoked_at=now() where company_id=v_company_id and lower(email)=v_email and intended_role='executive' and accepted_at is null and revoked_at is null and expires_at<=now();
  select id,token into v_invite_id,v_token from public.access_invites where company_id=v_company_id and lower(email)=v_email and intended_role='executive' and accepted_at is null and revoked_at is null and expires_at>now() order by created_at desc limit 1;
  if v_invite_id is null then insert into public.access_invites(company_id,email,intended_role,invited_by_user_id,expires_at) values(v_company_id,v_email,'executive',p_actor_user_id,now()+interval '14 days') returning id,token into v_invite_id,v_token;end if;
 end if;
 select t.template_code,v.version_code into v_template_code,v_template_version from public.companies c join public.industry_templates t on t.id=c.industry_template_id join public.industry_template_versions v on v.id=c.industry_template_version_id where c.id=v_company_id;
 insert into private.operator_audit_events(request_id,actor_user_id,company_id,action,target_type,target_id,after_json) values(p_request_id,p_actor_user_id,v_company_id,case when v_prior_company_id is null then 'customer.provisioned_from_template' else 'customer.provision_retried' end,'company',v_company_id,jsonb_build_object('name',btrim(p_name),'slug',p_slug,'plan_code',p_plan_code,'executive_email',v_email,'template_code',v_template_code,'template_version',v_template_version,'core_version',(select core_version from private.customer_accounts where company_id=v_company_id))) on conflict(request_id) do nothing;
 return jsonb_build_object('company_id',v_company_id,'account_status',(select account_status from private.customer_accounts where company_id=v_company_id),'core_version',(select core_version from private.customer_accounts where company_id=v_company_id),'template_code',v_template_code,'template_version',v_template_version,'invite_id',v_invite_id,'invite_token',v_token,'executive_email',v_email,'reused',v_prior_company_id is not null);
end $function$;