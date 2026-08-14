begin;

alter table public.company_settings enable row level security;
revoke all on public.company_settings from anon;
grant select,insert,update,delete on public.company_settings to authenticated;
drop policy if exists company_settings_member_select on public.company_settings;
create policy company_settings_member_select on public.company_settings for select to authenticated using(company_id in(select private.current_company_ids()));
drop policy if exists company_settings_admin_write on public.company_settings;
create policy company_settings_admin_write on public.company_settings for all to authenticated using(private.has_company_role(company_id,array['owner'::public.membership_role,'admin'::public.membership_role])) with check(private.has_company_role(company_id,array['owner'::public.membership_role,'admin'::public.membership_role]));

create table if not exists private.customer_configuration_validations (
 id uuid primary key default gen_random_uuid(),request_id uuid not null unique,company_id uuid not null references public.companies(id) on delete cascade,
 config_version_id uuid not null references public.configuration_versions(id) on delete cascade,actor_user_id uuid not null,checksum text not null,
 passed boolean not null,checks jsonb not null default '[]'::jsonb,created_at timestamptz not null default now()
);
create index if not exists customer_configuration_validations_company_idx on private.customer_configuration_validations(company_id,created_at desc);
create index if not exists customer_configuration_validations_config_idx on private.customer_configuration_validations(config_version_id,created_at desc);

create table if not exists private.customer_configuration_release_history (
 id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id) on delete cascade,actor_user_id uuid not null,
 validation_id uuid references private.customer_configuration_validations(id),from_config_version_id uuid references public.configuration_versions(id),
 to_config_version_id uuid not null references public.configuration_versions(id),action text not null default 'published',reason text,created_at timestamptz not null default now()
);
create index if not exists customer_configuration_release_history_company_idx on private.customer_configuration_release_history(company_id,created_at desc);
revoke all on private.customer_configuration_validations from public,anon,authenticated;
revoke all on private.customer_configuration_release_history from public,anon,authenticated;
grant select,insert,update on private.customer_configuration_validations to service_role;
grant select,insert on private.customer_configuration_release_history to service_role;

create or replace function private.configuration_snapshot(p_company_id uuid,p_config_version_id uuid) returns jsonb
language sql stable security invoker set search_path='' as $$
 select jsonb_build_object(
  'company_id',p_company_id,'config_version_id',p_config_version_id,
  'options',coalesce((select jsonb_agg(jsonb_build_object('library_type',o.library_type,'option_code',o.option_code,'label',o.label,'sort_order',o.sort_order,'active',o.active,'metadata',o.metadata) order by o.library_type,o.sort_order,o.option_code) from public.configuration_options o where o.company_id=p_company_id and o.config_version_id=p_config_version_id),'[]'::jsonb),
  'ratings',coalesce((select jsonb_agg(jsonb_build_object('code',r.code,'label',r.label,'score_value',r.score_value,'sort_order',r.sort_order,'employee_visible',r.employee_visible) order by r.sort_order,r.code) from public.rating_scale_items r where r.company_id=p_company_id and r.config_version_id=p_config_version_id),'[]'::jsonb),
  'questions',coalesce((select jsonb_agg(jsonb_build_object('role_id',q.role_id,'question_code',q.question_code,'section_code',q.section_code,'section_name',q.section_name,'question_text',q.question_text,'category',q.category,'active',q.active,'sort_order',q.sort_order,'question_weight',q.question_weight,'section_weight',q.section_weight,'requires_rating',q.requires_rating,'requires_reason',q.requires_reason,'notes_required_for_exceptional',q.notes_required_for_exceptional,'notes_required_for_unsatisfactory',q.notes_required_for_unsatisfactory) order by q.section_code,q.sort_order,q.question_code) from public.question_definitions q where q.company_id=p_company_id and q.config_version_id=p_config_version_id),'[]'::jsonb),
  'reasons',coalesce((select jsonb_agg(jsonb_build_object('question_id',r.question_id,'role_id',r.role_id,'label',r.label,'reason_type',r.reason_type,'rating_code',r.rating_code,'category',r.category,'active',r.active,'sort_order',r.sort_order,'external_code',r.external_code) order by r.sort_order,r.label) from public.reason_definitions r where r.company_id=p_company_id and r.config_version_id=p_config_version_id),'[]'::jsonb),
  'goals',coalesce((select jsonb_agg(jsonb_build_object('role_id',g.role_id,'label',g.label,'goal_type',g.goal_type,'default_text',g.default_text,'active',g.active) order by g.label) from public.goal_templates g where g.company_id=p_company_id and g.config_version_id=p_config_version_id),'[]'::jsonb)
 );
$$;

create or replace function public.operator_service_customer_configuration(p_actor_user_id uuid,p_company_id uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
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
  'ratings',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'code',r.code,'label',r.label,'score_value',r.score_value,'sort_order',r.sort_order) order by r.sort_order) from public.rating_scale_items r where r.company_id=p_company_id and r.config_version_id=v_config),'[]'::jsonb)
 ) into v_result;
 return v_result;
end $$;

create or replace function public.operator_service_begin_configuration_draft(p_actor_user_id uuid,p_company_id uuid,p_version_label text,p_request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare v_existing uuid;v_source uuid;v_new uuid;v_question record;v_new_question uuid;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform Owner access required'; end if;
 if p_request_id is null then raise exception 'Request ID is required'; end if;
 if not exists(select 1 from public.companies where id=p_company_id) then raise exception 'Customer not found'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_company_id::text||'|configuration-draft',0));
 select id into v_existing from public.configuration_versions where company_id=p_company_id and status='draft' order by created_at desc limit 1;
 if v_existing is not null then return public.operator_service_customer_configuration(p_actor_user_id,p_company_id); end if;
 select id into v_source from public.configuration_versions where company_id=p_company_id and status='published' order by published_at desc nulls last,created_at desc limit 1;
 insert into public.configuration_versions(company_id,schema_version,version_label,status,minimum_client_version)
 values(p_company_id,coalesce((select schema_version from public.configuration_versions where id=v_source),'1.0.1'),coalesce(nullif(btrim(p_version_label),''),'Customer Sandbox '||to_char(now(),'YYYY-MM-DD HH24:MI')),'draft',(select minimum_client_version from public.configuration_versions where id=v_source)) returning id into v_new;
 if v_source is not null then
  insert into public.configuration_options(company_id,config_version_id,library_type,option_code,label,sort_order,active,metadata) select company_id,v_new,library_type,option_code,label,sort_order,active,metadata from public.configuration_options where config_version_id=v_source;
  insert into public.rating_scale_items(company_id,config_version_id,code,label,score_value,sort_order,employee_visible) select company_id,v_new,code,label,score_value,sort_order,employee_visible from public.rating_scale_items where config_version_id=v_source;
  insert into public.goal_templates(company_id,config_version_id,role_id,label,goal_type,default_text,active) select company_id,v_new,role_id,label,goal_type,default_text,active from public.goal_templates where config_version_id=v_source;
  for v_question in select * from public.question_definitions where config_version_id=v_source order by sort_order,id loop
   insert into public.question_definitions(company_id,config_version_id,role_id,question_code,section_code,section_name,question_text,category,active,sort_order,question_weight,section_weight,requires_rating,requires_reason,notes_required_for_exceptional,notes_required_for_unsatisfactory)
   values(v_question.company_id,v_new,v_question.role_id,v_question.question_code,v_question.section_code,v_question.section_name,v_question.question_text,v_question.category,v_question.active,v_question.sort_order,v_question.question_weight,v_question.section_weight,v_question.requires_rating,v_question.requires_reason,v_question.notes_required_for_exceptional,v_question.notes_required_for_unsatisfactory) returning id into v_new_question;
   insert into public.reason_definitions(company_id,config_version_id,label,reason_type,rating_code,category,role_id,active,sort_order,external_code,question_id) select company_id,v_new,label,reason_type,rating_code,category,role_id,active,sort_order,external_code,v_new_question from public.reason_definitions where config_version_id=v_source and question_id=v_question.id;
  end loop;
  insert into public.reason_definitions(company_id,config_version_id,label,reason_type,rating_code,category,role_id,active,sort_order,external_code,question_id) select company_id,v_new,label,reason_type,rating_code,category,role_id,active,sort_order,external_code,null from public.reason_definitions where config_version_id=v_source and question_id is null;
 end if;
 insert into private.operator_audit_events(request_id,actor_user_id,company_id,action,target_type,target_id,after_json) values(p_request_id,p_actor_user_id,p_company_id,'configuration.sandbox_started','configuration',v_new,jsonb_build_object('source_configuration_id',v_source)) on conflict(request_id) do nothing;
 return public.operator_service_customer_configuration(p_actor_user_id,p_company_id);
end $$;

create or replace function public.operator_service_mutate_configuration(p_actor_user_id uuid,p_company_id uuid,p_operation text,p_payload jsonb,p_request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare v_draft uuid;v_target uuid;v_text text;v_second text;v_role uuid;v_active boolean;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform Owner access required'; end if;
 if p_request_id is null then raise exception 'Request ID is required'; end if;
 if not exists(select 1 from public.companies where id=p_company_id) then raise exception 'Customer not found'; end if;
 p_payload:=coalesce(p_payload,'{}'::jsonb);
 select id into v_draft from public.configuration_versions where company_id=p_company_id and status='draft' order by created_at desc limit 1;
 if p_operation='add_question' then
  if v_draft is null then raise exception 'Start the customer sandbox draft first'; end if;
  v_text:=nullif(btrim(p_payload->>'question_text'),'');v_second:=coalesce(nullif(btrim(p_payload->>'section_name'),''),'Performance');
  if v_text is null or length(v_text)>1000 then raise exception 'Question text is required and must be 1000 characters or less'; end if;
  if nullif(p_payload->>'role_id','') is not null then v_role:=(p_payload->>'role_id')::uuid;if not exists(select 1 from public.roles where id=v_role and company_id=p_company_id) then raise exception 'Role is not in this customer'; end if;end if;
  insert into public.question_definitions(company_id,config_version_id,role_id,question_code,section_code,section_name,question_text,category,active,sort_order,question_weight,section_weight,requires_rating,requires_reason,notes_required_for_exceptional,notes_required_for_unsatisfactory)
  values(p_company_id,v_draft,v_role,'CUSTOM_'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,12)),upper(substr(regexp_replace(v_second,'[^A-Za-z0-9]+','_','g'),1,40)),v_second,v_text,nullif(btrim(p_payload->>'category'),''),true,coalesce((select max(sort_order)+1 from public.question_definitions where config_version_id=v_draft),1),1,1,true,true,true,true) returning id into v_target;
 elsif p_operation='set_question_active' then
  if v_draft is null then raise exception 'Start the customer sandbox draft first'; end if;v_target:=(p_payload->>'id')::uuid;v_active:=coalesce((p_payload->>'active')::boolean,false);update public.question_definitions set active=v_active where id=v_target and company_id=p_company_id and config_version_id=v_draft;if not found then raise exception 'Question not found in this customer sandbox';end if;
 elsif p_operation='upsert_role' then
  v_text:=nullif(btrim(p_payload->>'title'),'');if v_text is null or length(v_text)>160 then raise exception 'Role title is required and must be 160 characters or less';end if;insert into public.roles(company_id,title,active,sort_order) values(p_company_id,v_text,true,coalesce((select max(sort_order)+1 from public.roles where company_id=p_company_id),1)) on conflict(company_id,title) do update set active=true returning id into v_target;
 elsif p_operation='set_role_active' then
  v_target:=(p_payload->>'id')::uuid;v_active:=coalesce((p_payload->>'active')::boolean,false);update public.roles set active=v_active where id=v_target and company_id=p_company_id;if not found then raise exception 'Role not found for this customer';end if;
 elsif p_operation='upsert_location' then
  v_text:=nullif(btrim(p_payload->>'location_code'),'');v_second:=nullif(btrim(p_payload->>'name'),'');if v_text is null or v_second is null then raise exception 'Location code and name are required';end if;
  insert into public.locations(company_id,location_code,name,status,city,state_code,market_name,area_name) values(p_company_id,v_text,v_second,'active',nullif(btrim(p_payload->>'city'),''),nullif(btrim(p_payload->>'state_code'),''),nullif(btrim(p_payload->>'market_name'),''),nullif(btrim(p_payload->>'area_name'),'')) on conflict(company_id,location_code) do update set name=excluded.name,status='active',city=excluded.city,state_code=excluded.state_code,market_name=excluded.market_name,area_name=excluded.area_name,updated_at=now() returning id into v_target;
 elsif p_operation='set_location_active' then
  v_target:=(p_payload->>'id')::uuid;v_active:=coalesce((p_payload->>'active')::boolean,false);update public.locations set status=case when v_active then 'active' else 'inactive' end,updated_at=now() where id=v_target and company_id=p_company_id;if not found then raise exception 'Location not found for this customer';end if;
 else raise exception 'Unsupported configuration operation %',p_operation;end if;
 insert into private.operator_audit_events(request_id,actor_user_id,company_id,action,target_type,target_id,after_json) values(p_request_id,p_actor_user_id,p_company_id,'configuration.'||p_operation,'customer_configuration',v_target,p_payload) on conflict(request_id) do nothing;
 return public.operator_service_customer_configuration(p_actor_user_id,p_company_id);
end $$;

create or replace function public.operator_service_publish_configuration(p_actor_user_id uuid,p_company_id uuid,p_config_version_id uuid,p_reason text,p_request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare v_before uuid;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform Owner access required'; end if;
 if p_request_id is null then raise exception 'Request ID is required'; end if;if nullif(btrim(p_reason),'') is null then raise exception 'Publish reason is required';end if;
 if not exists(select 1 from public.configuration_versions where id=p_config_version_id and company_id=p_company_id and status='draft') then raise exception 'Customer sandbox draft not found';end if;
 select id into v_before from public.configuration_versions where company_id=p_company_id and status='published' order by published_at desc nulls last,created_at desc limit 1;
 update public.configuration_versions set status='retired' where company_id=p_company_id and status='published' and id<>p_config_version_id;
 update public.configuration_versions set status='published',published_at=now() where id=p_config_version_id and company_id=p_company_id;
 insert into private.operator_audit_events(request_id,actor_user_id,company_id,action,target_type,target_id,reason,before_json,after_json) values(p_request_id,p_actor_user_id,p_company_id,'configuration.published','configuration',p_config_version_id,btrim(p_reason),jsonb_build_object('configuration_id',v_before),jsonb_build_object('configuration_id',p_config_version_id)) on conflict(request_id) do nothing;
 return public.operator_service_customer_configuration(p_actor_user_id,p_company_id);
end $$;

create or replace function public.operator_service_validate_configuration(p_actor_user_id uuid,p_company_id uuid,p_config_version_id uuid,p_request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare v_snapshot jsonb;v_checksum text;v_checks jsonb;v_passed boolean;v_validation_id uuid;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform Owner access required';end if;
 if p_request_id is null then raise exception 'Request ID is required';end if;
 if not exists(select 1 from public.configuration_versions where id=p_config_version_id and company_id=p_company_id and status='draft') then raise exception 'Customer sandbox draft not found';end if;
 v_snapshot:=private.configuration_snapshot(p_company_id,p_config_version_id);v_checksum:=md5(v_snapshot::text);
 v_checks:=jsonb_build_array(
  jsonb_build_object('code','active_location','passed',exists(select 1 from public.locations where company_id=p_company_id and status='active'),'message','At least one active location is required'),
  jsonb_build_object('code','active_role','passed',exists(select 1 from public.roles where company_id=p_company_id and active=true),'message','At least one active role is required'),
  jsonb_build_object('code','active_question','passed',exists(select 1 from public.question_definitions where company_id=p_company_id and config_version_id=p_config_version_id and active=true),'message','At least one active review question is required'),
  jsonb_build_object('code','rating_scale','passed',exists(select 1 from public.rating_scale_items where company_id=p_company_id and config_version_id=p_config_version_id),'message','A rating scale is required'));
 select coalesce(bool_and((item->>'passed')::boolean),false) into v_passed from jsonb_array_elements(v_checks) item;
 insert into private.customer_configuration_validations(request_id,company_id,config_version_id,actor_user_id,checksum,passed,checks) values(p_request_id,p_company_id,p_config_version_id,p_actor_user_id,v_checksum,v_passed,v_checks) returning id into v_validation_id;
 update public.configuration_versions set checksum=case when v_passed then v_checksum else null end where id=p_config_version_id and company_id=p_company_id;
 return jsonb_build_object('validation_id',v_validation_id,'company_id',p_company_id,'config_version_id',p_config_version_id,'checksum',v_checksum,'passed',v_passed,'checks',v_checks,'validated_at',now());
end $$;

create or replace function public.operator_service_promote_configuration(p_actor_user_id uuid,p_company_id uuid,p_config_version_id uuid,p_reason text,p_request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare v_checksum text;v_validation_id uuid;v_before uuid;v_result jsonb;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform Owner access required';end if;
 if p_request_id is null then raise exception 'Request ID is required';end if;if nullif(btrim(p_reason),'') is null then raise exception 'Promotion reason is required';end if;
 if not exists(select 1 from public.configuration_versions where id=p_config_version_id and company_id=p_company_id and status='draft') then raise exception 'Customer sandbox draft not found';end if;
 v_checksum:=md5(private.configuration_snapshot(p_company_id,p_config_version_id)::text);
 select id into v_validation_id from private.customer_configuration_validations where company_id=p_company_id and config_version_id=p_config_version_id and passed=true and checksum=v_checksum order by created_at desc limit 1;
 if v_validation_id is null then raise exception 'Sandbox must pass validation after its most recent change before promotion';end if;
 select id into v_before from public.configuration_versions where company_id=p_company_id and status='published' order by published_at desc nulls last,created_at desc limit 1;
 v_result:=public.operator_service_publish_configuration(p_actor_user_id,p_company_id,p_config_version_id,p_reason,p_request_id);
 insert into private.customer_configuration_release_history(company_id,actor_user_id,validation_id,from_config_version_id,to_config_version_id,action,reason) values(p_company_id,p_actor_user_id,v_validation_id,v_before,p_config_version_id,'published',btrim(p_reason));
 return v_result||jsonb_build_object('promotion',jsonb_build_object('validation_id',v_validation_id,'checksum',v_checksum,'from_config_version_id',v_before,'to_config_version_id',p_config_version_id));
end $$;

create or replace function public.operator_service_discard_configuration_draft(p_actor_user_id uuid,p_company_id uuid,p_reason text,p_request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare v_draft uuid;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform Owner access required';end if;if p_request_id is null then raise exception 'Request ID is required';end if;if nullif(btrim(p_reason),'') is null then raise exception 'Discard reason is required';end if;
 select id into v_draft from public.configuration_versions where company_id=p_company_id and status='draft' order by created_at desc limit 1;if v_draft is null then raise exception 'Customer sandbox draft not found';end if;
 update public.configuration_versions set status='retired' where id=v_draft and company_id=p_company_id and status='draft';
 insert into private.operator_audit_events(request_id,actor_user_id,company_id,action,target_type,target_id,reason,after_json) values(p_request_id,p_actor_user_id,p_company_id,'configuration.sandbox_discarded','configuration',v_draft,btrim(p_reason),jsonb_build_object('configuration_id',v_draft,'status','retired')) on conflict(request_id) do nothing;
 return public.operator_service_customer_configuration(p_actor_user_id,p_company_id);
end $$;

create or replace function public.operator_service_rollback_configuration(p_actor_user_id uuid,p_company_id uuid,p_target_config_version_id uuid,p_reason text,p_request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare v_current uuid;v_target public.configuration_versions%rowtype;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform Owner access required';end if;if p_request_id is null then raise exception 'Request ID is required';end if;if nullif(btrim(p_reason),'') is null then raise exception 'Rollback reason is required';end if;
 if exists(select 1 from public.configuration_versions where company_id=p_company_id and status='draft') then raise exception 'Discard the customer sandbox draft before rollback';end if;
 select id into v_current from public.configuration_versions where company_id=p_company_id and status='published' order by published_at desc nulls last,created_at desc limit 1;if v_current is null then raise exception 'Current published configuration not found';end if;if v_current=p_target_config_version_id then raise exception 'Target configuration is already live';end if;
 select * into v_target from public.configuration_versions where id=p_target_config_version_id and company_id=p_company_id and status='retired';if not found then raise exception 'Rollback target is not an eligible retired customer configuration';end if;
 if not exists(select 1 from private.customer_configuration_release_history h where h.company_id=p_company_id and(h.to_config_version_id=p_target_config_version_id or h.from_config_version_id=p_target_config_version_id)) then raise exception 'Rollback target has no customer release history';end if;
 update public.configuration_versions set status='retired' where id=v_current and company_id=p_company_id and status='published';update public.configuration_versions set status='published',published_at=now() where id=p_target_config_version_id and company_id=p_company_id and status='retired';
 insert into private.customer_configuration_release_history(company_id,actor_user_id,validation_id,from_config_version_id,to_config_version_id,action,reason) values(p_company_id,p_actor_user_id,null,v_current,p_target_config_version_id,'rollback',btrim(p_reason));
 insert into private.operator_audit_events(request_id,actor_user_id,company_id,action,target_type,target_id,reason,before_json,after_json) values(p_request_id,p_actor_user_id,p_company_id,'configuration.rolled_back','configuration',p_target_config_version_id,btrim(p_reason),jsonb_build_object('configuration_id',v_current),jsonb_build_object('configuration_id',p_target_config_version_id)) on conflict(request_id) do nothing;
 return public.operator_service_customer_configuration(p_actor_user_id,p_company_id)||jsonb_build_object('rollback',jsonb_build_object('from_config_version_id',v_current,'to_config_version_id',p_target_config_version_id));
end $$;

revoke all on function public.operator_service_customer_configuration(uuid,uuid) from public,anon,authenticated;
revoke all on function public.operator_service_begin_configuration_draft(uuid,uuid,text,uuid) from public,anon,authenticated;
revoke all on function public.operator_service_mutate_configuration(uuid,uuid,text,jsonb,uuid) from public,anon,authenticated;
revoke all on function public.operator_service_publish_configuration(uuid,uuid,uuid,text,uuid) from public,anon,authenticated;
revoke all on function public.operator_service_validate_configuration(uuid,uuid,uuid,uuid) from public,anon,authenticated;
revoke all on function public.operator_service_promote_configuration(uuid,uuid,uuid,text,uuid) from public,anon,authenticated;
revoke all on function public.operator_service_discard_configuration_draft(uuid,uuid,text,uuid) from public,anon,authenticated;
revoke all on function public.operator_service_rollback_configuration(uuid,uuid,uuid,text,uuid) from public,anon,authenticated;
grant execute on function public.operator_service_customer_configuration(uuid,uuid) to service_role;
grant execute on function public.operator_service_begin_configuration_draft(uuid,uuid,text,uuid) to service_role;
grant execute on function public.operator_service_mutate_configuration(uuid,uuid,text,jsonb,uuid) to service_role;
grant execute on function public.operator_service_validate_configuration(uuid,uuid,uuid,uuid) to service_role;
grant execute on function public.operator_service_promote_configuration(uuid,uuid,uuid,text,uuid) to service_role;
grant execute on function public.operator_service_discard_configuration_draft(uuid,uuid,text,uuid) to service_role;
grant execute on function public.operator_service_rollback_configuration(uuid,uuid,uuid,text,uuid) to service_role;

commit;
