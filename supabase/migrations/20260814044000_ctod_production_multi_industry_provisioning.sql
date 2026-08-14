begin;

create table if not exists private.operator_audit_events (
 id uuid primary key default gen_random_uuid(), request_id uuid not null unique, actor_user_id uuid not null,
 company_id uuid, action text not null, target_type text not null, target_id uuid, reason text,
 before_json jsonb, after_json jsonb, occurred_at timestamptz not null default now()
);
revoke all on private.operator_audit_events from public,anon,authenticated;
grant select,insert on private.operator_audit_events to service_role;

create or replace function private.provision_company_from_template(
 p_name text,p_slug text,p_timezone text,p_provisioning_key text,p_template_code text,p_template_version_code text default null
) returns uuid language plpgsql security definer set search_path='' as $$
declare v_company_id uuid; v_template_id uuid; v_template_version_id uuid; v_template_version text; v_schema_version text; v_configuration jsonb; v_existing_status text; v_config_version_id uuid; v_role jsonb; v_question jsonb; v_location jsonb; v_rating jsonb; v_role_id uuid;
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
 where t.template_code=upper(btrim(p_template_code)) and t.status='published' and v.status='published' and (p_template_version_code is null or v.version_code=p_template_version_code)
 order by case when p_template_version_code is not null and v.version_code=p_template_version_code then 0 else 1 end,v.published_at desc nulls last,v.created_at desc limit 1;
 if v_template_id is null then raise exception 'Published industry template/version is unavailable'; end if;
 insert into public.company_provisioning_runs(provisioning_key,template_code,requested_name,requested_slug,status)
 values(p_provisioning_key,upper(btrim(p_template_code)),btrim(p_name),p_slug,'pending')
 on conflict(provisioning_key) do update set requested_name=excluded.requested_name,requested_slug=excluded.requested_slug,template_code=excluded.template_code returning company_id into v_company_id;
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
   insert into public.roles(company_id,title,active,sort_order) values(v_company_id,btrim(v_role->>'title'),coalesce((v_role->>'active')::boolean,true),coalesce((v_role->>'sort_order')::integer,0))
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
 if jsonb_typeof(v_configuration->'ratings')='array' and jsonb_array_length(v_configuration->'ratings')>0 then
  for v_rating in select value from jsonb_array_elements(v_configuration->'ratings') loop
   if nullif(btrim(v_rating->>'code'),'') is not null and nullif(btrim(v_rating->>'label'),'') is not null then
    insert into public.rating_scale_items(company_id,config_version_id,code,label,score_value,sort_order,employee_visible)
    values(v_company_id,v_config_version_id,btrim(v_rating->>'code'),btrim(v_rating->>'label'),coalesce((v_rating->>'score_value')::numeric,0),coalesce((v_rating->>'sort_order')::integer,0),coalesce((v_rating->>'employee_visible')::boolean,true))
    on conflict(config_version_id,code) do update set label=excluded.label,score_value=excluded.score_value,sort_order=excluded.sort_order,employee_visible=excluded.employee_visible;
   end if;
  end loop;
 else
  insert into public.rating_scale_items(company_id,config_version_id,code,label,score_value,sort_order,employee_visible) values
  (v_company_id,v_config_version_id,'5','Exceptional',5,10,true),(v_company_id,v_config_version_id,'4','Exceeds Expectations',4,20,true),(v_company_id,v_config_version_id,'3','Meets Expectations',3,30,true),(v_company_id,v_config_version_id,'2','Needs Improvement',2,40,true),(v_company_id,v_config_version_id,'1','Unsatisfactory',1,50,true)
  on conflict(config_version_id,code) do nothing;
 end if;
 insert into public.company_template_lineage(company_id,industry_template_id,industry_template_version_id,provisioning_key,active,provisioned_at,metadata)
 values(v_company_id,v_template_id,v_template_version_id,p_provisioning_key,true,now(),jsonb_build_object('source','industry_template','template_code',upper(btrim(p_template_code)),'template_version',v_template_version));
 insert into public.company_settings(company_id,organization_mode) values(v_company_id,'single_site') on conflict(company_id) do nothing;
 update public.company_provisioning_runs set company_id=v_company_id,status='completed',completed_at=now() where provisioning_key=p_provisioning_key;
 return v_company_id;
end $$;
revoke all on function private.provision_company_from_template(text,text,text,text,text,text) from public,anon,authenticated;
grant execute on function private.provision_company_from_template(text,text,text,text,text,text) to service_role;

insert into public.industry_templates(template_code,name,description,status,is_blank_standard,metadata) values
('LANDSCAPE','Landscaping','Starter template for landscaping and grounds-service companies.','published',false,'{"purpose":"commercial_template"}'::jsonb),
('RESTAURANT','Restaurant','Starter template for restaurant groups and multi-location food-service businesses.','published',false,'{"purpose":"commercial_template"}'::jsonb)
on conflict(template_code) do update set name=excluded.name,description=excluded.description,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.industry_template_versions(industry_template_id,version_code,schema_version,status,configuration,minimum_client_version,published_at)
select t.id,'1.0.0','1.0.1','published','{"default_location":{"location_code":"001","name":"Main Location"},"roles":[{"title":"Crew Member","sort_order":10},{"title":"Crew Lead","sort_order":20},{"title":"Operations Manager","sort_order":30}],"questions":[{"question_code":"LAND-001","section_code":"PERFORMANCE","section_name":"Performance","question_text":"Completes assigned landscape work to company quality standards.","category":"Performance","sort_order":10,"requires_rating":true,"requires_reason":true},{"question_code":"LAND-002","section_code":"SAFETY","section_name":"Safety and Equipment","question_text":"Uses assigned tools and equipment safely and responsibly.","category":"Safety","sort_order":20,"requires_rating":true,"requires_reason":true},{"question_code":"LAND-003","section_code":"GROWTH","section_name":"Growth","question_text":"Demonstrates readiness to learn additional responsibilities or lead others.","category":"Growth","sort_order":30,"requires_rating":true,"requires_reason":true}]}'::jsonb,'1.0.1',now()
from public.industry_templates t where t.template_code='LANDSCAPE' on conflict(industry_template_id,version_code) do nothing;

insert into public.industry_template_versions(industry_template_id,version_code,schema_version,status,configuration,minimum_client_version,published_at)
select t.id,'1.0.0','1.0.1','published','{"default_location":{"location_code":"R01","name":"Restaurant 1"},"roles":[{"title":"Team Member","sort_order":10},{"title":"Shift Lead","sort_order":20},{"title":"Restaurant Manager","sort_order":30},{"title":"Area Manager","sort_order":40}],"questions":[{"question_code":"REST-001","section_code":"GUEST","section_name":"Guest Experience","question_text":"Consistently delivers the company standard for guest service.","category":"Guest Experience","sort_order":10,"requires_rating":true,"requires_reason":true},{"question_code":"REST-002","section_code":"FOOD","section_name":"Food Safety","question_text":"Follows food-safety, sanitation and cleanliness standards.","category":"Food Safety","sort_order":20,"requires_rating":true,"requires_reason":true},{"question_code":"REST-003","section_code":"OPS","section_name":"Operations","question_text":"Executes assigned operational responsibilities accurately and on time.","category":"Operations","sort_order":30,"requires_rating":true,"requires_reason":true},{"question_code":"REST-004","section_code":"GROWTH","section_name":"Growth","question_text":"Demonstrates readiness for additional responsibility or leadership development.","category":"Growth","sort_order":40,"requires_rating":true,"requires_reason":true}]}'::jsonb,'1.0.1',now()
from public.industry_templates t where t.template_code='RESTAURANT' on conflict(industry_template_id,version_code) do nothing;

create or replace function public.operator_service_provision_customer_v2(
 p_actor_user_id uuid,p_name text,p_slug text,p_timezone text,p_owner_email text,p_plan_code text,p_provisioning_key text,p_trial_days integer,p_template_code text,p_template_version_code text,p_request_id uuid
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_company_id uuid; v_prior_company_id uuid; v_invite_id uuid; v_token uuid; v_email text:=lower(nullif(btrim(p_owner_email),'')); v_template_code text; v_template_version text;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required'; end if;
 if p_request_id is null then raise exception 'Request ID is required'; end if;
 if coalesce(p_trial_days,0) not between 0 and 365 then raise exception 'Trial days must be between 0 and 365'; end if;
 if coalesce(p_plan_code,'') !~ '^[a-z0-9][a-z0-9_-]{1,39}$' then raise exception 'Plan code is invalid'; end if;
 if v_email is not null and (position('@' in v_email)<=1 or length(v_email)>320) then raise exception 'Owner email is invalid'; end if;
 select company_id into v_prior_company_id from public.company_provisioning_runs where provisioning_key=p_provisioning_key;
 v_company_id:=private.provision_company_from_template(p_name,p_slug,p_timezone,p_provisioning_key,p_template_code,p_template_version_code);
 insert into private.customer_accounts(company_id,account_status,plan_code,trial_ends_at,core_version,release_status,updated_at)
 values(v_company_id,'trial',p_plan_code,case when p_trial_days>0 then now()+make_interval(days=>p_trial_days) else null end,'1.0.1','current',now())
 on conflict(company_id) do update set plan_code=excluded.plan_code,trial_ends_at=coalesce(private.customer_accounts.trial_ends_at,excluded.trial_ends_at),updated_at=now();
 if v_email is not null then
  if exists(select 1 from private.platform_operators po join auth.users u on u.id=po.user_id where lower(u.email)=v_email) then raise exception 'A platform operator cannot be assigned as a customer owner'; end if;
  update public.access_invites set revoked_at=now() where company_id=v_company_id and lower(email)=v_email and intended_role='owner' and accepted_at is null and revoked_at is null and expires_at<=now();
  select id,token into v_invite_id,v_token from public.access_invites where company_id=v_company_id and lower(email)=v_email and intended_role='owner' and accepted_at is null and revoked_at is null and expires_at>now() order by created_at desc limit 1;
  if v_invite_id is null then insert into public.access_invites(company_id,email,intended_role,invited_by_user_id,expires_at) values(v_company_id,v_email,'owner',p_actor_user_id,now()+interval '14 days') returning id,token into v_invite_id,v_token; end if;
 end if;
 select t.template_code,v.version_code into v_template_code,v_template_version from public.companies c join public.industry_templates t on t.id=c.industry_template_id join public.industry_template_versions v on v.id=c.industry_template_version_id where c.id=v_company_id;
 insert into private.operator_audit_events(request_id,actor_user_id,company_id,action,target_type,target_id,after_json)
 values(p_request_id,p_actor_user_id,v_company_id,case when v_prior_company_id is null then 'customer.provisioned_from_template' else 'customer.provision_retried' end,'company',v_company_id,jsonb_build_object('name',btrim(p_name),'slug',p_slug,'plan_code',p_plan_code,'owner_email',v_email,'template_code',v_template_code,'template_version',v_template_version)) on conflict(request_id) do nothing;
 return jsonb_build_object('company_id',v_company_id,'account_status',(select account_status from private.customer_accounts where company_id=v_company_id),'template_code',v_template_code,'template_version',v_template_version,'invite_id',v_invite_id,'invite_token',v_token,'owner_email',v_email,'reused',v_prior_company_id is not null);
end $$;
revoke all on function public.operator_service_provision_customer_v2(uuid,text,text,text,text,text,text,integer,text,text,uuid) from public,anon,authenticated;
grant execute on function public.operator_service_provision_customer_v2(uuid,text,text,text,text,text,text,integer,text,text,uuid) to service_role;

commit;
