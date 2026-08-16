-- CTOD Question & Intelligence Engine v1.1
-- Configurable question APIs + summary/talent consumer payloads.

-- Seed Commercial Tire's current Employee Voice wording as configurable questions.
insert into public.question_definitions(
  company_id,config_version_id,role_id,question_code,section_code,section_name,question_text,category,active,sort_order,
  question_weight,section_weight,requires_rating,requires_reason,notes_required_for_exceptional,notes_required_for_unsatisfactory,
  question_purpose,response_type,response_options,help_text,required
)
select cv.company_id,cv.id,null,'VOICE-SAFETY','SEC-VOICE','Employee Voice',
       'Do you feel like safety is a priority in your current position?','Safety',true,1,
       0,0,false,false,false,false,'employee_voice','single_select','["Yes","No"]'::jsonb,
       'Employee response feeds CTOD People Pulse and Master analytics.',true
from public.configuration_versions cv
where cv.status='published'
  and not exists(select 1 from public.question_definitions q where q.config_version_id=cv.id and q.question_code='VOICE-SAFETY');

insert into public.question_definitions(company_id,config_version_id,role_id,question_code,section_code,section_name,question_text,category,active,sort_order,question_weight,section_weight,requires_rating,requires_reason,notes_required_for_exceptional,notes_required_for_unsatisfactory,question_purpose,response_type,response_options,help_text,required)
select cv.company_id,cv.id,null,'VOICE-CAREER','SEC-VOICE','Employee Voice',
       'Do you feel like you have a career?','Career',true,2,0,0,false,false,false,false,'employee_voice','single_select','["Yes","No"]'::jsonb,
       'Employee response feeds CTOD People Pulse and Master analytics.',true
from public.configuration_versions cv
where cv.status='published'
  and not exists(select 1 from public.question_definitions q where q.config_version_id=cv.id and q.question_code='VOICE-CAREER');

insert into public.question_definitions(company_id,config_version_id,role_id,question_code,section_code,section_name,question_text,category,active,sort_order,question_weight,section_weight,requires_rating,requires_reason,notes_required_for_exceptional,notes_required_for_unsatisfactory,question_purpose,response_type,response_options,help_text,required)
select cv.company_id,cv.id,null,'VOICE-WORK-PREFERENCE','SEC-VOICE','Employee Voice',
       'Which is more important to you in your current position?','Work Preference',true,3,0,0,false,false,false,false,'employee_voice','single_select','["More money / more hours","More flexibility / flexible hours"]'::jsonb,
       'Employee response feeds CTOD workforce preference analytics.',true
from public.configuration_versions cv
where cv.status='published'
  and not exists(select 1 from public.question_definitions q where q.config_version_id=cv.id and q.question_code='VOICE-WORK-PREFERENCE');

insert into public.question_definitions(company_id,config_version_id,role_id,question_code,section_code,section_name,question_text,category,active,sort_order,question_weight,section_weight,requires_rating,requires_reason,notes_required_for_exceptional,notes_required_for_unsatisfactory,question_purpose,response_type,response_options,help_text,required)
select cv.company_id,cv.id,null,'VOICE-RELOCATION','SEC-VOICE','Employee Voice',
       'Would you relocate for the right career opportunity?','Mobility',true,4,0,0,false,false,false,false,'employee_voice','single_select','["Yes","Maybe, depending on the opportunity","No"]'::jsonb,
       'Employee response feeds CTOD workforce mobility and succession analytics.',true
from public.configuration_versions cv
where cv.status='published'
  and not exists(select 1 from public.question_definitions q where q.config_version_id=cv.id and q.question_code='VOICE-RELOCATION');

insert into public.question_metric_bindings(company_id,question_id,metric_id,source_field)
select q.company_id,q.id,m.id,
 case q.question_code
  when 'VOICE-SAFETY' then 'safety_priority_response'
  when 'VOICE-CAREER' then 'career_feeling_response'
  when 'VOICE-WORK-PREFERENCE' then 'work_preference_response'
  when 'VOICE-RELOCATION' then 'relocation_openness_response'
 end
from public.question_definitions q
join public.metric_definitions m on m.company_id is null and m.metric_key=case q.question_code
  when 'VOICE-SAFETY' then 'workplace_safety_sentiment'
  when 'VOICE-CAREER' then 'career_belonging'
  when 'VOICE-WORK-PREFERENCE' then 'work_preference'
  when 'VOICE-RELOCATION' then 'mobility_openness'
 end
where q.question_code in ('VOICE-SAFETY','VOICE-CAREER','VOICE-WORK-PREFERENCE','VOICE-RELOCATION')
on conflict(question_id,metric_id) do update set active=true,source_field=excluded.source_field;

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
   'help_text',q.help_text,'required',q.required,'sort_order',q.sort_order,'metric',jsonb_build_object(
     'id',md.id,'key',md.metric_key,'label',md.label,'domain',md.domain,'visualization',md.visualization,'aggregation',md.aggregation,
     'feeds_master',md.feeds_master,'feeds_summary',md.feeds_summary,'feeds_talent_search',md.feeds_talent_search,'feeds_depth_chart',md.feeds_depth_chart
   ),'response',emr.response_value
 ) order by q.sort_order,q.question_code),'[]'::jsonb) into j
 from public.question_definitions q
 left join public.question_metric_bindings b on b.question_id=q.id and b.active
 left join public.metric_definitions md on md.id=b.metric_id and md.active
 left join public.v_effective_metric_responses emr on emr.review_id=r.id and emr.metric_id=md.id
 where q.company_id=r.company_id and q.config_version_id=r.config_version_id and q.active
   and q.question_purpose=p_purpose and (q.role_id is null or q.role_id=r.role_id);
 return j;
end $function$;

create or replace function public.save_review_metric_response(p_review_id uuid,p_question_id uuid,p_response jsonb)
returns jsonb language plpgsql security definer set search_path to 'public','private','pg_catalog' as $function$
declare r public.reviews; q public.question_definitions; b public.question_metric_bindings; result public.review_metric_responses; txt text; num numeric; boolv boolean;
begin
 select * into r from public.reviews where id=p_review_id;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(r.company_id,r.location_id) then raise exception 'Access denied'; end if;
 if r.status='finalized' then raise exception 'Finalized reviews are immutable'; end if;
 select * into q from public.question_definitions where id=p_question_id and company_id=r.company_id and config_version_id=r.config_version_id and active;
 if not found then raise exception 'Question not available for this review version'; end if;
 select * into b from public.question_metric_bindings where question_id=q.id and active limit 1;
 if not found then raise exception 'Question is not bound to an intelligence metric'; end if;
 if q.response_type in ('single_select','text') then txt:=trim(both '"' from p_response::text);
 elsif q.response_type='number' then num:=(p_response #>> '{}')::numeric;
 elsif q.response_type='boolean' then boolv:=(p_response #>> '{}')::boolean;
 end if;
 insert into public.review_metric_responses(company_id,review_id,employee_id,location_id,role_id,question_id,metric_id,response_text,response_number,response_boolean,response_json,updated_at)
 values(r.company_id,r.id,r.employee_id,r.location_id,r.role_id,q.id,b.metric_id,txt,num,boolv,case when q.response_type in ('multi_select','json') then p_response else null end,now())
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
 from public.metric_definitions md
 join public.v_effective_metric_responses emr on emr.metric_id=md.id and emr.review_id=r.id
 where md.active;
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
select coalesce(jsonb_agg(jsonb_build_object('employee_id',employee_id,'metric_key',metric_key,'label',label,'response',response_value,'feeds_talent_search',feeds_talent_search,'feeds_depth_chart',feeds_depth_chart,'finalized_at',finalized_at) order by employee_id,metric_key),'[]'::jsonb)
from ranked where rn=1;
$function$;

create or replace function public.get_review_summary_payload(p_review_id uuid)
returns jsonb language plpgsql stable set search_path to 'public' as $function$
declare r public.reviews; base jsonb; company_json jsonb; metrics_json jsonb;
begin
 select * into r from public.reviews where id=p_review_id;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(r.company_id,r.location_id) then raise exception 'Access denied'; end if;
 base:=public.get_review_form(p_review_id);
 select jsonb_build_object('id',c.id,'name',c.name,'branding',c.branding) into company_json from public.companies c where c.id=r.company_id;
 metrics_json:=public.get_review_metric_payload(p_review_id);
 return base || jsonb_build_object('company',company_json,'metrics',metrics_json,'summary_contract_version','CTOD-ADAPTIVE-1.0');
end $function$;

grant execute on function public.get_configurable_review_questions(uuid,text) to authenticated;
grant execute on function public.save_review_metric_response(uuid,uuid,jsonb) to authenticated;
grant execute on function public.get_review_metric_payload(uuid) to authenticated;
grant execute on function public.latest_employee_metric_signals() to authenticated;
