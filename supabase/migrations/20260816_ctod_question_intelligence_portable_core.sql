-- CTOD Question & Intelligence Engine v2.0 Portable Core
-- Industry-neutral. No Commercial Tire-specific columns are referenced.

alter table public.question_definitions
  add column if not exists question_purpose text not null default 'performance',
  add column if not exists response_type text not null default 'rating',
  add column if not exists response_options jsonb not null default '[]'::jsonb,
  add column if not exists help_text text,
  add column if not exists required boolean not null default true;

create table if not exists public.metric_definitions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references public.companies(id) on delete cascade,
  metric_key text not null,
  label text not null,
  description text,
  domain text not null default 'employee_voice',
  response_type text not null,
  visualization text not null default 'distribution',
  aggregation text not null default 'distribution',
  positive_values jsonb not null default '[]'::jsonb,
  feeds_master boolean not null default false,
  feeds_summary boolean not null default false,
  feeds_talent_search boolean not null default false,
  feeds_depth_chart boolean not null default false,
  benchmarkable boolean not null default false,
  active boolean not null default true,
  sort_order integer not null default 100,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists metric_definitions_platform_key_uq
  on public.metric_definitions(metric_key) where company_id is null;
create unique index if not exists metric_definitions_company_key_uq
  on public.metric_definitions(company_id,metric_key) where company_id is not null;

create table if not exists public.question_metric_bindings (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  question_id uuid not null references public.question_definitions(id) on delete cascade,
  metric_id uuid not null references public.metric_definitions(id) on delete cascade,
  transform jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(question_id,metric_id)
);

create table if not exists public.review_metric_responses (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  review_id uuid not null references public.reviews(id) on delete cascade,
  employee_id uuid not null references public.employees(id) on delete cascade,
  location_id uuid not null references public.locations(id) on delete cascade,
  role_id uuid references public.roles(id) on delete set null,
  question_id uuid references public.question_definitions(id) on delete set null,
  metric_id uuid not null references public.metric_definitions(id) on delete cascade,
  response_text text,
  response_number numeric,
  response_boolean boolean,
  response_json jsonb,
  recorded_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(review_id,metric_id,question_id)
);

alter table public.metric_definitions enable row level security;
alter table public.question_metric_bindings enable row level security;
alter table public.review_metric_responses enable row level security;

drop policy if exists metric_definitions_select on public.metric_definitions;
create policy metric_definitions_select on public.metric_definitions for select using (
  company_id is null or company_id in (select private.current_company_ids())
);

drop policy if exists metric_definitions_company_admin on public.metric_definitions;
create policy metric_definitions_company_admin on public.metric_definitions for all using (
  company_id is not null and private.has_company_role(company_id,array['owner'::membership_role,'admin'::membership_role])
) with check (
  company_id is not null and private.has_company_role(company_id,array['owner'::membership_role,'admin'::membership_role])
);

drop policy if exists question_metric_bindings_select on public.question_metric_bindings;
create policy question_metric_bindings_select on public.question_metric_bindings for select using (
  company_id in (select private.current_company_ids())
);

drop policy if exists question_metric_bindings_admin on public.question_metric_bindings;
create policy question_metric_bindings_admin on public.question_metric_bindings for all using (
  private.has_company_role(company_id,array['owner'::membership_role,'admin'::membership_role])
) with check (
  private.has_company_role(company_id,array['owner'::membership_role,'admin'::membership_role])
);

drop policy if exists review_metric_responses_scope on public.review_metric_responses;
create policy review_metric_responses_scope on public.review_metric_responses for all using (
  private.can_access_location(company_id,location_id)
) with check (
  private.can_access_location(company_id,location_id)
);

insert into public.metric_definitions(
  metric_key,label,description,domain,response_type,visualization,aggregation,positive_values,
  feeds_master,feeds_summary,feeds_talent_search,feeds_depth_chart,benchmarkable,sort_order
)
values
 ('workplace_safety_sentiment','Safety is a priority','Employee perception that safety is treated as a real priority.','employee_voice','single_select','gauge','percent_positive','["Yes"]',true,true,false,false,true,10),
 ('career_belonging','Feels they have a career','Employee perception that the organization offers a real career path.','employee_voice','single_select','gauge','percent_positive','["Yes"]',true,true,false,false,true,20),
 ('work_preference','Work preference','Employee preference between compensation/hours and scheduling flexibility.','employee_voice','single_select','distribution','distribution','[]',true,true,false,false,true,30),
 ('mobility_openness','Relocation openness','Employee willingness to relocate for the right opportunity.','employee_voice','single_select','gauge','percent_positive','["Yes","Maybe"]',true,true,true,true,true,40)
on conflict do nothing;

create or replace view public.v_effective_metric_responses as
select rmr.company_id,rmr.review_id,rmr.employee_id,rmr.location_id,rmr.role_id,rmr.question_id,
       rmr.metric_id,md.metric_key,
       coalesce(rmr.response_text,rmr.response_number::text,rmr.response_boolean::text,rmr.response_json::text) response_value,
       rmr.recorded_at
from public.review_metric_responses rmr
join public.metric_definitions md on md.id=rmr.metric_id;

create or replace function public.get_configurable_review_questions(p_review_id uuid,p_purpose text default 'employee_voice')
returns jsonb language plpgsql stable security definer set search_path to 'public','private','pg_catalog' as $function$
declare r public.reviews; j jsonb;
begin
 select * into r from public.reviews where id=p_review_id;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(r.company_id,r.location_id) then raise exception 'Access denied'; end if;
 select coalesce(jsonb_agg(jsonb_build_object(
   'id',q.id,'code',q.question_code,'section_code',q.section_code,'section_name',q.section_name,'text',q.question_text,
   'category',q.category,'purpose',q.question_purpose,'response_type',q.response_type,'response_options',q.response_options,
   'help_text',q.help_text,'required',q.required,'sort_order',q.sort_order,
   'metric',jsonb_build_object('id',md.id,'key',md.metric_key,'label',md.label,'domain',md.domain,'visualization',md.visualization,
     'aggregation',md.aggregation,'feeds_master',md.feeds_master,'feeds_summary',md.feeds_summary,
     'feeds_talent_search',md.feeds_talent_search,'feeds_depth_chart',md.feeds_depth_chart),
   'response',emr.response_value
 ) order by q.sort_order,q.question_code),'[]'::jsonb) into j
 from public.question_definitions q
 left join public.question_metric_bindings b on b.question_id=q.id and b.active
 left join public.metric_definitions md on md.id=b.metric_id and md.active
 left join public.v_effective_metric_responses emr on emr.review_id=r.id and emr.question_id=q.id and emr.metric_id=md.id
 where q.company_id=r.company_id and q.config_version_id=r.config_version_id and q.active
   and q.question_purpose=p_purpose and (q.role_id is null or q.role_id=r.role_id);
 return j;
end $function$;

create or replace function public.save_review_metric_response(p_review_id uuid,p_question_id uuid,p_response jsonb)
returns jsonb language plpgsql security definer set search_path to 'public','private','pg_catalog' as $function$
declare r public.reviews; q public.question_definitions; metric public.metric_definitions; txt text; num numeric; boolv boolean; result public.review_metric_responses;
begin
 select * into r from public.reviews where id=p_review_id;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(r.company_id,r.location_id) then raise exception 'Access denied'; end if;
 if r.status='finalized' then raise exception 'Finalized reviews are immutable'; end if;
 select * into q from public.question_definitions where id=p_question_id and company_id=r.company_id and config_version_id=r.config_version_id and active;
 if not found then raise exception 'Question not available for this review version'; end if;
 select md.* into metric from public.question_metric_bindings b join public.metric_definitions md on md.id=b.metric_id where b.question_id=q.id and b.active and md.active limit 1;
 if not found then raise exception 'Question is not bound to an intelligence metric'; end if;
 if q.response_type in ('single_select','text') then txt:=p_response #>> '{}';
 elsif q.response_type='number' then num:=(p_response #>> '{}')::numeric;
 elsif q.response_type='boolean' then boolv:=(p_response #>> '{}')::boolean;
 end if;
 insert into public.review_metric_responses(company_id,review_id,employee_id,location_id,role_id,question_id,metric_id,response_text,response_number,response_boolean,response_json,updated_at)
 values(r.company_id,r.id,r.employee_id,r.location_id,r.role_id,q.id,metric.id,txt,num,boolv,case when q.response_type in ('multi_select','json') then p_response else null end,now())
 on conflict(review_id,metric_id,question_id) do update set response_text=excluded.response_text,response_number=excluded.response_number,response_boolean=excluded.response_boolean,response_json=excluded.response_json,updated_at=now()
 returning * into result;
 return to_jsonb(result);
end $function$;

create or replace function public.get_review_metric_payload(p_review_id uuid)
returns jsonb language plpgsql stable security definer set search_path to 'public','private','pg_catalog' as $function$
declare r public.reviews; j jsonb;
begin
 select * into r from public.reviews where id=p_review_id;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(r.company_id,r.location_id) then raise exception 'Access denied'; end if;
 select coalesce(jsonb_agg(jsonb_build_object(
   'metric_key',md.metric_key,'label',md.label,'domain',md.domain,'visualization',md.visualization,'aggregation',md.aggregation,
   'response_type',md.response_type,'response',emr.response_value,'feeds_master',md.feeds_master,'feeds_summary',md.feeds_summary,
   'feeds_talent_search',md.feeds_talent_search,'feeds_depth_chart',md.feeds_depth_chart,'sort_order',md.sort_order
 ) order by md.sort_order,md.metric_key),'[]'::jsonb) into j
 from public.v_effective_metric_responses emr
 join public.metric_definitions md on md.id=emr.metric_id
 where emr.review_id=r.id and md.active;
 return j;
end $function$;

create or replace function public.metric_intelligence(p_metric_keys text[] default null)
returns jsonb language plpgsql stable security definer set search_path to 'public','private','pg_catalog' as $function$
declare j jsonb;
begin
 with scoped as (
   select e.*,ro.title role_title,l.location_code,l.name location_name,md.label,md.visualization,md.aggregation,md.positive_values,
          md.feeds_master,md.feeds_summary,md.feeds_talent_search,md.feeds_depth_chart,md.benchmarkable,md.sort_order
   from public.v_effective_metric_responses e
   join public.reviews rv on rv.id=e.review_id and rv.status='finalized'
   join public.metric_definitions md on md.id=e.metric_id and md.active
   left join public.roles ro on ro.id=e.role_id
   join public.locations l on l.id=e.location_id
   where private.can_access_location(e.company_id,e.location_id)
     and (p_metric_keys is null or e.metric_key=any(p_metric_keys))
 ), defs as (
   select distinct metric_key,label,visualization,aggregation,positive_values,feeds_master,feeds_summary,feeds_talent_search,feeds_depth_chart,benchmarkable,sort_order from scoped
 ), overall as (
   select metric_key,response_value,count(*)::int n from scoped group by metric_key,response_value
 ), by_role as (
   select metric_key,role_title,response_value,count(*)::int n from scoped group by metric_key,role_title,response_value
 ), by_location as (
   select metric_key,location_code,location_name,response_value,count(*)::int n from scoped group by metric_key,location_code,location_name,response_value
 )
 select jsonb_build_object(
   'definitions',coalesce((select jsonb_agg(to_jsonb(defs) order by sort_order,metric_key) from defs),'[]'::jsonb),
   'overall',coalesce((select jsonb_agg(to_jsonb(overall) order by metric_key,response_value) from overall),'[]'::jsonb),
   'by_role',coalesce((select jsonb_agg(to_jsonb(by_role) order by metric_key,role_title,response_value) from by_role),'[]'::jsonb),
   'by_location',coalesce((select jsonb_agg(to_jsonb(by_location) order by metric_key,location_code,response_value) from by_location),'[]'::jsonb)
 ) into j;
 return j;
end $function$;

create or replace function public.latest_employee_metric_signals()
returns jsonb language sql stable security definer set search_path to 'public','private','pg_catalog' as $function$
with ranked as (
 select emr.*,md.label,md.feeds_talent_search,md.feeds_depth_chart,rv.finalized_at,
        row_number() over(partition by emr.employee_id,emr.metric_key order by rv.finalized_at desc nulls last,emr.recorded_at desc) rn
 from public.v_effective_metric_responses emr
 join public.reviews rv on rv.id=emr.review_id and rv.status='finalized'
 join public.metric_definitions md on md.id=emr.metric_id and md.active and (md.feeds_talent_search or md.feeds_depth_chart)
 where private.can_access_location(emr.company_id,emr.location_id)
)
select coalesce(jsonb_agg(jsonb_build_object('employee_id',employee_id,'metric_key',metric_key,'label',label,'response',response_value,
  'feeds_talent_search',feeds_talent_search,'feeds_depth_chart',feeds_depth_chart,'finalized_at',finalized_at) order by employee_id,metric_key),'[]'::jsonb)
from ranked where rn=1;
$function$;

grant execute on function public.get_configurable_review_questions(uuid,text) to authenticated;
grant execute on function public.save_review_metric_response(uuid,uuid,jsonb) to authenticated;
grant execute on function public.get_review_metric_payload(uuid) to authenticated;
grant execute on function public.metric_intelligence(text[]) to authenticated;
grant execute on function public.latest_employee_metric_signals() to authenticated;
