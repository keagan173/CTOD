-- CTOD 002: customer-specific sandbox validation and promotion gate
-- Purpose: require a validated customer configuration snapshot before any sandbox draft can be promoted live.
-- Scope: development branch / CTOD Sandbox only until explicitly promoted to production.

create table if not exists private.customer_configuration_validations (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique,
  company_id uuid not null references public.companies(id) on delete cascade,
  config_version_id uuid not null references public.configuration_versions(id) on delete cascade,
  actor_user_id uuid not null,
  checksum text not null,
  passed boolean not null,
  checks jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists customer_configuration_validations_company_idx
  on private.customer_configuration_validations(company_id, created_at desc);
create index if not exists customer_configuration_validations_config_idx
  on private.customer_configuration_validations(config_version_id, created_at desc);

create table if not exists private.customer_configuration_release_history (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  actor_user_id uuid not null,
  validation_id uuid references private.customer_configuration_validations(id),
  from_config_version_id uuid references public.configuration_versions(id),
  to_config_version_id uuid not null references public.configuration_versions(id),
  action text not null default 'published',
  reason text,
  created_at timestamptz not null default now()
);

create index if not exists customer_configuration_release_history_company_idx
  on private.customer_configuration_release_history(company_id, created_at desc);

create or replace function private.configuration_snapshot(
  p_company_id uuid,
  p_config_version_id uuid
)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'company_id',p_company_id,
    'config_version_id',p_config_version_id,
    'options',coalesce((
      select jsonb_agg(jsonb_build_object(
        'library_type',o.library_type,'option_code',o.option_code,'label',o.label,
        'sort_order',o.sort_order,'active',o.active,'metadata',o.metadata
      ) order by o.library_type,o.sort_order,o.option_code)
      from public.configuration_options o
      where o.company_id=p_company_id and o.config_version_id=p_config_version_id
    ),'[]'::jsonb),
    'ratings',coalesce((
      select jsonb_agg(jsonb_build_object(
        'code',r.code,'label',r.label,'score_value',r.score_value,
        'sort_order',r.sort_order,'employee_visible',r.employee_visible
      ) order by r.sort_order,r.code)
      from public.rating_scale_items r
      where r.company_id=p_company_id and r.config_version_id=p_config_version_id
    ),'[]'::jsonb),
    'questions',coalesce((
      select jsonb_agg(jsonb_build_object(
        'role_id',q.role_id,'question_code',q.question_code,'section_code',q.section_code,
        'section_name',q.section_name,'question_text',q.question_text,'category',q.category,
        'active',q.active,'sort_order',q.sort_order,'question_weight',q.question_weight,
        'section_weight',q.section_weight,'requires_rating',q.requires_rating,
        'requires_reason',q.requires_reason,
        'notes_required_for_exceptional',q.notes_required_for_exceptional,
        'notes_required_for_unsatisfactory',q.notes_required_for_unsatisfactory
      ) order by q.section_code,q.sort_order,q.question_code)
      from public.question_definitions q
      where q.company_id=p_company_id and q.config_version_id=p_config_version_id
    ),'[]'::jsonb),
    'reasons',coalesce((
      select jsonb_agg(jsonb_build_object(
        'question_id',r.question_id,'role_id',r.role_id,'label',r.label,
        'reason_type',r.reason_type,'rating_code',r.rating_code,'category',r.category,
        'active',r.active,'sort_order',r.sort_order,'external_code',r.external_code
      ) order by r.sort_order,r.label)
      from public.reason_definitions r
      where r.company_id=p_company_id and r.config_version_id=p_config_version_id
    ),'[]'::jsonb),
    'goals',coalesce((
      select jsonb_agg(jsonb_build_object(
        'role_id',g.role_id,'label',g.label,'goal_type',g.goal_type,
        'default_text',g.default_text,'active',g.active
      ) order by g.label)
      from public.goal_templates g
      where g.company_id=p_company_id and g.config_version_id=p_config_version_id
    ),'[]'::jsonb)
  );
$$;

create or replace function public.operator_service_validate_configuration(
  p_actor_user_id uuid,
  p_company_id uuid,
  p_config_version_id uuid,
  p_request_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_snapshot jsonb;
  v_checksum text;
  v_checks jsonb;
  v_passed boolean;
  v_validation_id uuid;
begin
  if not exists(
    select 1 from private.platform_operators
    where user_id=p_actor_user_id and active=true and operator_role='platform_admin'
  ) then
    raise exception 'Platform Owner access required';
  end if;

  if p_request_id is null then
    raise exception 'Request ID is required';
  end if;

  select id into v_validation_id
  from private.customer_configuration_validations
  where request_id=p_request_id;

  if v_validation_id is not null then
    return (
      select jsonb_build_object(
        'validation_id',id,'company_id',company_id,'config_version_id',config_version_id,
        'checksum',checksum,'passed',passed,'checks',checks,'validated_at',created_at
      )
      from private.customer_configuration_validations
      where id=v_validation_id
    );
  end if;

  if not exists(
    select 1 from public.configuration_versions
    where id=p_config_version_id and company_id=p_company_id and status='draft'
  ) then
    raise exception 'Customer sandbox draft not found';
  end if;

  v_snapshot:=private.configuration_snapshot(p_company_id,p_config_version_id);
  v_checksum:=md5(v_snapshot::text);

  v_checks:=jsonb_build_array(
    jsonb_build_object(
      'code','active_location',
      'passed',exists(select 1 from public.locations where company_id=p_company_id and status='active'),
      'message','At least one active location is required'
    ),
    jsonb_build_object(
      'code','active_role',
      'passed',exists(select 1 from public.roles where company_id=p_company_id and active=true),
      'message','At least one active role is required'
    ),
    jsonb_build_object(
      'code','active_question',
      'passed',exists(
        select 1 from public.question_definitions
        where company_id=p_company_id and config_version_id=p_config_version_id and active=true
      ),
      'message','At least one active review question is required'
    ),
    jsonb_build_object(
      'code','rating_scale',
      'passed',exists(
        select 1 from public.rating_scale_items
        where company_id=p_company_id and config_version_id=p_config_version_id
      ),
      'message','A rating scale is required'
    )
  );

  select coalesce(bool_and((item->>'passed')::boolean),false)
  into v_passed
  from jsonb_array_elements(v_checks) item;

  insert into private.customer_configuration_validations(
    request_id,company_id,config_version_id,actor_user_id,checksum,passed,checks
  ) values(
    p_request_id,p_company_id,p_config_version_id,p_actor_user_id,v_checksum,v_passed,v_checks
  ) returning id into v_validation_id;

  update public.configuration_versions
  set checksum=case when v_passed then v_checksum else null end
  where id=p_config_version_id and company_id=p_company_id;

  insert into private.operator_audit_events(
    request_id,actor_user_id,company_id,action,target_type,target_id,after_json
  ) values(
    p_request_id,p_actor_user_id,p_company_id,'configuration.validated','configuration',p_config_version_id,
    jsonb_build_object(
      'validation_id',v_validation_id,'checksum',v_checksum,'passed',v_passed,'checks',v_checks
    )
  ) on conflict(request_id) do nothing;

  return jsonb_build_object(
    'validation_id',v_validation_id,
    'company_id',p_company_id,
    'config_version_id',p_config_version_id,
    'checksum',v_checksum,
    'passed',v_passed,
    'checks',v_checks,
    'validated_at',now()
  );
end;
$$;

create or replace function public.operator_service_promote_configuration(
  p_actor_user_id uuid,
  p_company_id uuid,
  p_config_version_id uuid,
  p_reason text,
  p_request_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_checksum text;
  v_validation_id uuid;
  v_before uuid;
  v_result jsonb;
begin
  if not exists(
    select 1 from private.platform_operators
    where user_id=p_actor_user_id and active=true and operator_role='platform_admin'
  ) then
    raise exception 'Platform Owner access required';
  end if;

  if p_request_id is null then
    raise exception 'Request ID is required';
  end if;

  if nullif(btrim(p_reason),'') is null then
    raise exception 'Promotion reason is required';
  end if;

  if not exists(
    select 1 from public.configuration_versions
    where id=p_config_version_id and company_id=p_company_id and status='draft'
  ) then
    raise exception 'Customer sandbox draft not found';
  end if;

  v_checksum:=md5(private.configuration_snapshot(p_company_id,p_config_version_id)::text);

  select id into v_validation_id
  from private.customer_configuration_validations
  where company_id=p_company_id
    and config_version_id=p_config_version_id
    and passed=true
    and checksum=v_checksum
  order by created_at desc
  limit 1;

  if v_validation_id is null then
    raise exception 'Sandbox must pass validation after its most recent change before promotion';
  end if;

  select id into v_before
  from public.configuration_versions
  where company_id=p_company_id and status='published'
  order by published_at desc nulls last,created_at desc
  limit 1;

  v_result:=public.operator_service_publish_configuration(
    p_actor_user_id,p_company_id,p_config_version_id,p_reason,p_request_id
  );

  insert into private.customer_configuration_release_history(
    company_id,actor_user_id,validation_id,from_config_version_id,
    to_config_version_id,action,reason
  ) values(
    p_company_id,p_actor_user_id,v_validation_id,v_before,
    p_config_version_id,'published',btrim(p_reason)
  );

  return v_result || jsonb_build_object(
    'promotion',jsonb_build_object(
      'validation_id',v_validation_id,
      'checksum',v_checksum,
      'from_config_version_id',v_before,
      'to_config_version_id',p_config_version_id
    )
  );
end;
$$;

-- Owner-control-plane only. Do not expose these RPCs to customer sessions.
revoke execute on function public.operator_service_validate_configuration(uuid,uuid,uuid,uuid) from public, anon, authenticated;
revoke execute on function public.operator_service_promote_configuration(uuid,uuid,uuid,text,uuid) from public, anon, authenticated;
grant execute on function public.operator_service_validate_configuration(uuid,uuid,uuid,uuid) to service_role;
grant execute on function public.operator_service_promote_configuration(uuid,uuid,uuid,text,uuid) to service_role;

-- Direct publish is now an internal primitive. Service callers must use the gated promotion function.
revoke execute on function public.operator_service_publish_configuration(uuid,uuid,uuid,text,uuid) from service_role;
