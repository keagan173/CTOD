begin;

create or replace function public.operator_service_platform_releases(p_actor_user_id uuid)
returns jsonb language plpgsql stable set search_path='' as $$
begin
  if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object(
    'id',pr.id,'version_code',pr.version_code,'status',pr.status,'minimum_schema_version',pr.minimum_schema_version,
    'release_notes',pr.release_notes,'released_at',pr.released_at,'created_at',pr.created_at,
    'latest_validation',(select to_jsonb(v) from (select id,source_commit_sha,automated_tests_passed,security_review_passed,acceptance_test_passed,notes,passed,validated_at from private.platform_release_validations x where x.release_id=pr.id order by validated_at desc limit 1) v),
    'targets',coalesce((select jsonb_agg(jsonb_build_object('company_id',t.company_id,'company_name',c.name,'rollout_stage',t.rollout_stage,'status',t.status,'reason',t.reason,'scheduled_at',t.scheduled_at,'activated_at',t.activated_at,'rolled_back_at',t.rolled_back_at) order by c.name) from private.platform_release_targets t join public.companies c on c.id=t.company_id where t.release_id=pr.id),'[]'::jsonb)
  ) order by pr.created_at desc) from private.platform_releases pr),'[]'::jsonb);
end $$;

create or replace function public.operator_service_validate_platform_release(
 p_actor_user_id uuid,p_release_id uuid,p_source_commit_sha text,p_automated_tests_passed boolean,
 p_security_review_passed boolean,p_acceptance_test_passed boolean,p_notes text,p_request_id uuid)
returns jsonb language plpgsql set search_path='' as $$
declare v private.platform_release_validations%rowtype;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required'; end if;
 if p_request_id is null then raise exception 'Request ID is required'; end if;
 if not exists(select 1 from private.platform_releases where id=p_release_id) then raise exception 'Platform release not found'; end if;
 insert into private.platform_release_validations(release_id,actor_user_id,source_commit_sha,automated_tests_passed,security_review_passed,acceptance_test_passed,notes)
 values(p_release_id,p_actor_user_id,nullif(btrim(p_source_commit_sha),''),coalesce(p_automated_tests_passed,false),coalesce(p_security_review_passed,false),coalesce(p_acceptance_test_passed,false),nullif(btrim(p_notes),'')) returning * into v;
 update private.platform_releases set status=case when v.passed then 'validated' else 'candidate' end where id=p_release_id and status<>'available';
 insert into private.operator_audit_events(request_id,actor_user_id,action,target_type,target_id,reason,after_json)
 values(p_request_id,p_actor_user_id,'platform_release.validated','platform_release',p_release_id,nullif(btrim(p_notes),''),to_jsonb(v)) on conflict(request_id) do nothing;
 return to_jsonb(v);
end $$;

create or replace function public.operator_service_approve_platform_release(p_actor_user_id uuid,p_release_id uuid,p_reason text,p_request_id uuid)
returns jsonb language plpgsql set search_path='' as $$
declare v_version text;v_validation private.platform_release_validations%rowtype;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required'; end if;
 if p_request_id is null then raise exception 'Request ID is required'; end if;
 select * into v_validation from private.platform_release_validations where release_id=p_release_id order by validated_at desc limit 1;
 if not found or not v_validation.passed then raise exception 'Latest platform release validation must pass before approval'; end if;
 update private.platform_releases set status='available',released_at=coalesce(released_at,now()) where id=p_release_id returning version_code into v_version;
 if not found then raise exception 'Platform release not found'; end if;
 insert into private.operator_audit_events(request_id,actor_user_id,action,target_type,target_id,reason,after_json)
 values(p_request_id,p_actor_user_id,'platform_release.approved','platform_release',p_release_id,nullif(btrim(p_reason),''),jsonb_build_object('version_code',v_version,'status','available')) on conflict(request_id) do nothing;
 return jsonb_build_object('release_id',p_release_id,'version_code',v_version,'status','available');
end $$;

create or replace function public.operator_service_schedule_platform_release(p_actor_user_id uuid,p_release_id uuid,p_company_ids uuid[],p_rollout_stage text,p_reason text,p_request_id uuid)
returns jsonb language plpgsql set search_path='' as $$
declare v_version text;v_count int;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required'; end if;
 if p_request_id is null then raise exception 'Request ID is required'; end if;
 if p_rollout_stage not in ('pilot','selected','all') then raise exception 'Rollout stage is invalid'; end if;
 select version_code into v_version from private.platform_releases where id=p_release_id and status='available';
 if not found then raise exception 'Platform release must be available before rollout scheduling'; end if;
 with chosen as (select ca.company_id from private.customer_accounts ca where ca.account_status not in('closed') and(p_rollout_stage='all' or ca.company_id=any(coalesce(p_company_ids,'{}'::uuid[])))),upserted as (
  insert into private.platform_release_targets(release_id,company_id,rollout_stage,status,reason,scheduled_by_user_id,scheduled_at,updated_at)
  select p_release_id,c.company_id,p_rollout_stage,'scheduled',nullif(btrim(p_reason),''),p_actor_user_id,now(),now() from chosen c
  on conflict(release_id,company_id) do update set rollout_stage=excluded.rollout_stage,status='scheduled',reason=excluded.reason,scheduled_by_user_id=excluded.scheduled_by_user_id,scheduled_at=now(),activated_at=null,rolled_back_at=null,updated_at=now() returning company_id)
 update private.customer_accounts ca set target_core_version=v_version,release_status='scheduled',updated_at=now() where ca.company_id in(select company_id from upserted);
 get diagnostics v_count=row_count;if v_count=0 then raise exception 'No eligible customers selected for rollout'; end if;
 insert into private.customer_release_history(company_id,actor_user_id,action,from_version,to_version,reason)
 select t.company_id,p_actor_user_id,'scheduled',ca.core_version,v_version,nullif(btrim(p_reason),'') from private.platform_release_targets t join private.customer_accounts ca on ca.company_id=t.company_id where t.release_id=p_release_id and t.status='scheduled' and ca.target_core_version=v_version;
 insert into private.operator_audit_events(request_id,actor_user_id,action,target_type,target_id,reason,after_json)
 values(p_request_id,p_actor_user_id,'platform_release.rollout_scheduled','platform_release',p_release_id,nullif(btrim(p_reason),''),jsonb_build_object('version_code',v_version,'rollout_stage',p_rollout_stage,'customer_count',v_count)) on conflict(request_id) do nothing;
 return jsonb_build_object('release_id',p_release_id,'version_code',v_version,'rollout_stage',p_rollout_stage,'scheduled_customers',v_count);
end $$;

create or replace function public.operator_service_activate_platform_release(p_actor_user_id uuid,p_release_id uuid,p_company_ids uuid[],p_reason text,p_request_id uuid)
returns jsonb language plpgsql set search_path='' as $$
declare v_version text;v_count int;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required'; end if;
 if p_request_id is null then raise exception 'Request ID is required'; end if;
 select version_code into v_version from private.platform_releases where id=p_release_id and status='available';if not found then raise exception 'Platform release is not available'; end if;
 with chosen as(select t.company_id from private.platform_release_targets t where t.release_id=p_release_id and t.status='scheduled' and(coalesce(array_length(p_company_ids,1),0)=0 or t.company_id=any(p_company_ids))),changed as(
  update private.customer_accounts ca set previous_core_version=core_version,core_version=v_version,target_core_version=null,release_status='rollback_available',updated_at=now() where ca.company_id in(select company_id from chosen) and ca.target_core_version=v_version returning ca.company_id,ca.previous_core_version)
 update private.platform_release_targets t set status='active',activated_at=now(),updated_at=now() where t.release_id=p_release_id and t.company_id in(select company_id from changed);
 get diagnostics v_count=row_count;if v_count=0 then raise exception 'No scheduled customers were eligible for activation'; end if;
 insert into private.customer_release_history(company_id,actor_user_id,action,from_version,to_version,reason)
 select t.company_id,p_actor_user_id,'activated',ca.previous_core_version,ca.core_version,nullif(btrim(p_reason),'') from private.platform_release_targets t join private.customer_accounts ca on ca.company_id=t.company_id where t.release_id=p_release_id and t.status='active' and t.activated_at>now()-interval '1 minute';
 insert into private.operator_audit_events(request_id,actor_user_id,action,target_type,target_id,reason,after_json)
 values(p_request_id,p_actor_user_id,'platform_release.rollout_activated','platform_release',p_release_id,nullif(btrim(p_reason),''),jsonb_build_object('version_code',v_version,'customer_count',v_count)) on conflict(request_id) do nothing;
 return jsonb_build_object('release_id',p_release_id,'version_code',v_version,'activated_customers',v_count);
end $$;

create or replace function public.operator_service_rollback_platform_release(p_actor_user_id uuid,p_release_id uuid,p_company_ids uuid[],p_reason text,p_request_id uuid)
returns jsonb language plpgsql set search_path='' as $$
declare v_version text;v_count int;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required'; end if;
 if p_request_id is null then raise exception 'Request ID is required'; end if;
 select version_code into v_version from private.platform_releases where id=p_release_id;if not found then raise exception 'Platform release not found'; end if;
 with chosen as(select t.company_id from private.platform_release_targets t join private.customer_accounts ca on ca.company_id=t.company_id where t.release_id=p_release_id and t.status='active' and ca.core_version=v_version and ca.previous_core_version is not null and(coalesce(array_length(p_company_ids,1),0)=0 or t.company_id=any(p_company_ids))),changed as(
  update private.customer_accounts ca set core_version=previous_core_version,previous_core_version=v_version,target_core_version=null,release_status='rollback_completed',updated_at=now() where ca.company_id in(select company_id from chosen) returning ca.company_id,ca.core_version)
 update private.platform_release_targets t set status='rolled_back',rolled_back_at=now(),updated_at=now() where t.release_id=p_release_id and t.company_id in(select company_id from changed);
 get diagnostics v_count=row_count;if v_count=0 then raise exception 'No active customers were eligible for rollback'; end if;
 insert into private.customer_release_history(company_id,actor_user_id,action,from_version,to_version,reason)
 select t.company_id,p_actor_user_id,'rolled_back',v_version,ca.core_version,nullif(btrim(p_reason),'') from private.platform_release_targets t join private.customer_accounts ca on ca.company_id=t.company_id where t.release_id=p_release_id and t.status='rolled_back' and t.rolled_back_at>now()-interval '1 minute';
 insert into private.operator_audit_events(request_id,actor_user_id,action,target_type,target_id,reason,after_json)
 values(p_request_id,p_actor_user_id,'platform_release.rollout_rolled_back','platform_release',p_release_id,nullif(btrim(p_reason),''),jsonb_build_object('version_code',v_version,'customer_count',v_count)) on conflict(request_id) do nothing;
 return jsonb_build_object('release_id',p_release_id,'version_code',v_version,'rolled_back_customers',v_count);
end $$;

revoke all on function public.operator_service_platform_releases(uuid) from public,anon,authenticated;
revoke all on function public.operator_service_validate_platform_release(uuid,uuid,text,boolean,boolean,boolean,text,uuid) from public,anon,authenticated;
revoke all on function public.operator_service_approve_platform_release(uuid,uuid,text,uuid) from public,anon,authenticated;
revoke all on function public.operator_service_schedule_platform_release(uuid,uuid,uuid[],text,text,uuid) from public,anon,authenticated;
revoke all on function public.operator_service_activate_platform_release(uuid,uuid,uuid[],text,uuid) from public,anon,authenticated;
revoke all on function public.operator_service_rollback_platform_release(uuid,uuid,uuid[],text,uuid) from public,anon,authenticated;
grant execute on function public.operator_service_platform_releases(uuid) to service_role;
grant execute on function public.operator_service_validate_platform_release(uuid,uuid,text,boolean,boolean,boolean,text,uuid) to service_role;
grant execute on function public.operator_service_approve_platform_release(uuid,uuid,text,uuid) to service_role;
grant execute on function public.operator_service_schedule_platform_release(uuid,uuid,uuid[],text,text,uuid) to service_role;
grant execute on function public.operator_service_activate_platform_release(uuid,uuid,uuid[],text,uuid) to service_role;
grant execute on function public.operator_service_rollback_platform_release(uuid,uuid,uuid[],text,uuid) to service_role;

commit;
