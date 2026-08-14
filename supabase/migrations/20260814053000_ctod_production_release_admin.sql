begin;

create or replace function public.operator_service_create_platform_release(
 p_actor_user_id uuid,p_version_code text,p_minimum_schema_version text,p_release_notes text,p_request_id uuid
) returns jsonb
language plpgsql
set search_path=''
as $$
declare v_id uuid;v_version text:=btrim(p_version_code);
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required';end if;
 if p_request_id is null then raise exception 'Request ID is required';end if;
 if v_version !~ '^[0-9]+\.[0-9]+\.[0-9]+(?:[-+][A-Za-z0-9.-]+)?$' then raise exception 'Version code must use semantic version format';end if;
 if exists(select 1 from private.platform_releases where version_code=v_version) then raise exception 'Platform release version already exists';end if;
 insert into private.platform_releases(version_code,status,minimum_schema_version,release_notes)
 values(v_version,'candidate',nullif(btrim(p_minimum_schema_version),''),nullif(btrim(p_release_notes),'')) returning id into v_id;
 insert into private.operator_audit_events(request_id,actor_user_id,action,target_type,target_id,after_json)
 values(p_request_id,p_actor_user_id,'platform_release.created','platform_release',v_id,jsonb_build_object('version_code',v_version,'status','candidate','minimum_schema_version',nullif(btrim(p_minimum_schema_version),''))) on conflict(request_id) do nothing;
 return jsonb_build_object('release_id',v_id,'version_code',v_version,'status','candidate');
end $$;

revoke all on function public.operator_service_create_platform_release(uuid,text,text,text,uuid) from public,anon,authenticated;
grant execute on function public.operator_service_create_platform_release(uuid,text,text,text,uuid) to service_role;

commit;
