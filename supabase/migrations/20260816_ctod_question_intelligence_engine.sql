-- CTOD Question & Intelligence Engine v1.0
-- Additive, backward-compatible migration.

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
create unique index if not exists metric_definitions_platform_key_uq on public.metric_definitions(metric_key) where company_id is null;
create unique index if not exists metric_definitions_company_key_uq on public.metric_definitions(company_id,metric_key) where company_id is not null;

create table if not exists public.question_metric_bindings (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  question_id uuid not null references public.question_definitions(id) on delete cascade,
  metric_id uuid not null references public.metric_definitions(id) on delete cascade,
  source_field text,
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

insert into public.metric_definitions(metric_key,label,description,domain,response_type,visualization,aggregation,positive_values,feeds_master,feeds_summary,feeds_talent_search,feeds_depth_chart,benchmarkable,sort_order)
values
 ('workplace_safety_sentiment','Safety is a priority','Employee perception that safety is a priority in the current position.','employee_voice','single_select','gauge','percent_positive','["Yes"]',true,true,false,false,true,10),
 ('career_belonging','Feels they have a career','Employee perception that the organization offers a real career path.','employee_voice','single_select','gauge','percent_positive','["Yes"]',true,true,false,false,true,20),
 ('work_preference','Work preference','Employee preference between compensation/hours and scheduling flexibility.','employee_voice','single_select','distribution','distribution','[]',true,true,false,false,true,30),
 ('mobility_openness','Relocation openness','Employee willingness to relocate for the right opportunity.','employee_voice','single_select','gauge','percent_positive','["Yes","Maybe, depending on the opportunity"]',true,true,true,true,true,40)
on conflict do nothing;

-- Performance form remains explicitly performance-only so future configurable questions cannot leak into scored competencies.
create or replace function public.get_review_form(p_review_id uuid)
returns jsonb language plpgsql stable set search_path to 'public' as $function$
declare r public.reviews; outj jsonb;
begin
 select * into r from reviews where id=p_review_id; if not found then raise exception 'Review not found'; end if; if not private.can_access_location(r.company_id,r.location_id) then raise exception 'Access denied'; end if;
 select jsonb_build_object(
 'review',jsonb_build_object('id',r.id,'status',r.status,'review_date',r.review_date,'scheduled_review_date',r.scheduled_review_date,'next_review_date',r.next_review_date,'overall_rating_label',r.overall_rating_label,'overall_score',r.overall_score,'overall_percent',r.overall_percent),
 'employee',(select jsonb_build_object('id',e.id,'employee_code',e.employee_code,'name',e.first_name||' '||e.last_name,'role',ro.title,'location',l.name,'location_code',l.location_code) from employees e join roles ro on ro.id=r.role_id join locations l on l.id=r.location_id where e.id=r.employee_id),
 'ratings',(select coalesce(jsonb_agg(jsonb_build_object('id',x.id,'code',x.code,'label',x.label,'score',x.score_value) order by x.sort_order),'[]'::jsonb) from rating_scale_items x where x.config_version_id=r.config_version_id and x.employee_visible),
 'reasons',(select coalesce(jsonb_agg(jsonb_build_object('id',rd.id,'label',rd.label,'rating_code',rd.rating_code,'category',rd.category,'role_id',rd.role_id,'question_id',rd.question_id) order by rd.sort_order),'[]'::jsonb) from reason_definitions rd where rd.config_version_id=r.config_version_id and rd.active and rd.question_id in (select q.id from question_definitions q where q.config_version_id=r.config_version_id and q.active and q.question_purpose='performance' and (q.role_id is null or q.role_id=r.role_id)) and rd.reason_type in ('review_org','review_role')),
 'questions',(select coalesce(jsonb_agg(jsonb_build_object('id',q.id,'code',q.question_code,'section',q.section_name,'section_code',q.section_code,'text',q.question_text,'category',q.question_code,'display_category',q.category,'sort_order',q.sort_order,'requires_rating',q.requires_rating,'requires_reason',q.requires_reason,'answer',case when a.id is null then null else jsonb_build_object('id',a.id,'rating_id',a.rating_id,'primary_reason_id',a.primary_reason_id,'additional_reason_id',a.additional_reason_id,'manager_note',a.manager_note,'confirmed',a.confirmed_current_cycle) end) order by q.section_code,q.sort_order),'[]'::jsonb) from question_definitions q left join review_answers a on a.review_id=r.id and a.question_id=q.id where q.config_version_id=r.config_version_id and q.active and q.question_purpose='performance' and (q.role_id is null or q.role_id=r.role_id)),
 'goals',(select coalesce(jsonb_agg(jsonb_build_object('id',g.id,'goal_text',g.goal_text,'goal_type',g.goal_type,'status',g.status,'target_date',g.target_date,'raise_linked',g.raise_linked,'promotion_linked',g.promotion_linked) order by g.created_at),'[]'::jsonb) from goals g where g.employee_id=r.employee_id and g.status in ('not_started','in_progress') and private.can_access_employee(g.company_id,g.employee_id)),
 'career',(select jsonb_build_object('promotion_interest',cd.promotion_interest,'desired_role_id',cd.desired_role_id,'desired_role',dr.title,'final_desired_role_id',cd.final_desired_role_id,'final_desired_role',fr.title,'career_direction',cd.career_direction,'career_direction_reason',cd.career_direction_reason,'promotion_readiness',cd.promotion_readiness,'next_year_goal',cd.next_year_goal,'specialist_growth_path',cd.specialist_growth_path,'safety_priority_response',cd.safety_priority_response,'career_feeling_response',cd.career_feeling_response,'work_preference_response',cd.work_preference_response,'relocation_openness_response',cd.relocation_openness_response) from career_decisions cd left join roles dr on dr.id=cd.desired_role_id left join roles fr on fr.id=cd.final_desired_role_id where cd.review_id=r.id limit 1),
 'compensation',(select to_jsonb(cc) from compensation_decisions cc where cc.review_id=r.id limit 1),
 'summary',(select jsonb_build_object('employee_comments',s.employee_comments,'manager_summary',s.manager_summary) from review_summaries s where s.review_id=r.id)
 ) into outj; return outj;
end $function$;

-- Effective metric-response view. Generic responses win; legacy Employee Voice remains available during migration.
create or replace view public.v_effective_metric_responses as
with generic as (
 select rmr.company_id,rmr.review_id,rmr.employee_id,rmr.location_id,rmr.role_id,rmr.question_id,rmr.metric_id,md.metric_key,
        coalesce(rmr.response_text,rmr.response_number::text,rmr.response_boolean::text,rmr.response_json::text) response_value,
        rmr.recorded_at
 from public.review_metric_responses rmr join public.metric_definitions md on md.id=rmr.metric_id
), legacy as (
 select rv.company_id,rv.id review_id,rv.employee_id,rv.location_id,rv.role_id,null::uuid question_id,md.id metric_id,md.metric_key,v.response_value,coalesce(rv.finalized_at,rv.updated_at) recorded_at
 from public.reviews rv join public.career_decisions cd on cd.review_id=rv.id
 cross join lateral (values
   ('workplace_safety_sentiment',cd.safety_priority_response),
   ('career_belonging',cd.career_feeling_response),
   ('work_preference',cd.work_preference_response),
   ('mobility_openness',cd.relocation_openness_response)
 ) v(metric_key,response_value)
 join public.metric_definitions md on md.company_id is null and md.metric_key=v.metric_key
 where v.response_value is not null and not exists(select 1 from generic g where g.review_id=rv.id and g.metric_key=v.metric_key)
)
select * from generic union all select * from legacy;

create or replace function public.metric_intelligence(p_metric_keys text[] default null)
returns jsonb language plpgsql stable security definer set search_path to 'public','private','pg_catalog' as $function$
declare j jsonb;
begin
 with scoped as (
   select e.*,ro.title role_title,l.location_code,l.name location_name,md.label,md.visualization,md.aggregation,md.positive_values,md.feeds_master,md.feeds_summary,md.feeds_talent_search,md.feeds_depth_chart,md.benchmarkable,md.sort_order
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

grant execute on function public.metric_intelligence(text[]) to authenticated;
