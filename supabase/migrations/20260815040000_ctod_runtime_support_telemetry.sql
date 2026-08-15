create table if not exists public.client_runtime_events (
  id uuid primary key default gen_random_uuid(), occurred_at timestamptz not null default now(), company_id uuid null references public.companies(id) on delete set null, location_id uuid null references public.locations(id) on delete set null, user_id uuid null, event_type text not null, severity text not null default 'error', message text not null, module text null, release_version text null, page_path text null, user_agent text null, metadata jsonb not null default '{}'::jsonb, constraint client_runtime_events_severity_chk check (severity in ('info','warning','error','fatal'))
);
create index if not exists client_runtime_events_company_time_idx on public.client_runtime_events(company_id,occurred_at desc);
create index if not exists client_runtime_events_type_time_idx on public.client_runtime_events(event_type,occurred_at desc);
alter table public.client_runtime_events enable row level security;
revoke all on public.client_runtime_events from anon, authenticated;
create or replace function public.report_client_runtime_event(p_event_type text,p_severity text,p_message text,p_module text default null,p_release_version text default null,p_page_path text default null,p_user_agent text default null,p_location_id uuid default null,p_metadata jsonb default '{}'::jsonb) returns uuid language plpgsql security definer set search_path='public','private','pg_catalog' as $function$
declare v_user uuid:=auth.uid();v_company uuid;v_id uuid;
begin
 if v_user is null then raise exception 'Authentication required'; end if;
 select cm.company_id into v_company from public.company_memberships cm where cm.user_id=v_user and cm.active order by cm.created_at desc limit 1;
 if v_company is null then raise exception 'No active company membership'; end if;
 if p_location_id is not null and not private.can_access_location(v_company,p_location_id) then raise exception 'Location access denied'; end if;
 insert into public.client_runtime_events(company_id,location_id,user_id,event_type,severity,message,module,release_version,page_path,user_agent,metadata)
 values(v_company,p_location_id,v_user,left(coalesce(nullif(trim(p_event_type),''),'client_error'),80),case when p_severity in ('info','warning','error','fatal') then p_severity else 'error' end,left(coalesce(p_message,'Unknown client error'),1000),left(p_module,160),left(p_release_version,120),left(p_page_path,300),left(p_user_agent,500),coalesce(p_metadata,'{}'::jsonb)) returning id into v_id;return v_id;
end $function$;
revoke all on function public.report_client_runtime_event(text,text,text,text,text,text,text,uuid,jsonb) from public;
grant execute on function public.report_client_runtime_event(text,text,text,text,text,text,text,uuid,jsonb) to authenticated;
create or replace view public.v_client_runtime_health as select c.id company_id,c.name company_name,count(e.id) filter(where e.occurred_at>=now()-interval '24 hours') events_24h,count(e.id) filter(where e.severity in ('error','fatal') and e.occurred_at>=now()-interval '24 hours') errors_24h,count(e.id) filter(where e.severity='fatal' and e.occurred_at>=now()-interval '24 hours') fatals_24h,max(e.occurred_at) last_event_at,max(e.occurred_at) filter(where e.severity in ('error','fatal')) last_error_at from public.companies c left join public.client_runtime_events e on e.company_id=c.id group by c.id,c.name;
revoke all on public.v_client_runtime_health from anon,authenticated;