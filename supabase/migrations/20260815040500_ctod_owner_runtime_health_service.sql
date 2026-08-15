create or replace function public.operator_service_runtime_health(p_actor_user_id uuid,p_company_id uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $function$
declare v_health jsonb;v_events jsonb;
begin
 if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('company_id',h.company_id,'company_name',h.company_name,'events_24h',h.events_24h,'errors_24h',h.errors_24h,'fatals_24h',h.fatals_24h,'last_event_at',h.last_event_at,'last_error_at',h.last_error_at) order by h.errors_24h desc,h.company_name),'[]'::jsonb) into v_health from public.v_client_runtime_health h where p_company_id is null or h.company_id=p_company_id;
 select coalesce(jsonb_agg(jsonb_build_object('id',e.id,'occurred_at',e.occurred_at,'company_id',e.company_id,'company_name',c.name,'location_code',l.location_code,'event_type',e.event_type,'severity',e.severity,'message',e.message,'module',e.module,'release_version',e.release_version,'page_path',e.page_path,'metadata',e.metadata) order by e.occurred_at desc),'[]'::jsonb) into v_events from (select * from public.client_runtime_events where (p_company_id is null or company_id=p_company_id) order by occurred_at desc limit 100) e left join public.companies c on c.id=e.company_id left join public.locations l on l.id=e.location_id;
 return jsonb_build_object('health',v_health,'events',v_events,'generated_at',now());
end $function$;
revoke all on function public.operator_service_runtime_health(uuid,uuid) from public;
grant execute on function public.operator_service_runtime_health(uuid,uuid) to authenticated;