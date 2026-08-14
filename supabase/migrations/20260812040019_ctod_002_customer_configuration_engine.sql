begin;

create table if not exists public.company_settings (
  company_id uuid primary key references public.companies(id) on delete cascade,
  review_cadence_months integer not null default 6 check (review_cadence_months between 1 and 24),
  terminology jsonb not null default '{}'::jsonb,
  coaching_categories jsonb not null default '["Recognition","Development","Corrective"]'::jsonb,
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.organization_units (
  id uuid primary key default extensions.gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  parent_unit_id uuid null references public.organization_units(id) on delete restrict,
  unit_type text not null check (unit_type in ('region','area','market','division','department','group')),
  unit_code text null,
  name text not null,
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, unit_type, unit_code)
);

alter table public.locations add column if not exists organization_unit_id uuid null references public.organization_units(id) on delete set null;

alter table public.company_settings enable row level security;
alter table public.organization_units enable row level security;

revoke all on public.company_settings from anon;
revoke all on public.organization_units from anon;
grant select, insert, update, delete on public.company_settings to authenticated;
grant select, insert, update, delete on public.organization_units to authenticated;

create policy company_settings_member_select on public.company_settings
for select to authenticated
using (company_id in (select private.current_company_ids()));

create policy company_settings_admin_write on public.company_settings
for all to authenticated
using (private.has_company_role(company_id, array['owner'::public.membership_role,'admin'::public.membership_role]))
with check (private.has_company_role(company_id, array['owner'::public.membership_role,'admin'::public.membership_role]));

create policy organization_units_member_select on public.organization_units
for select to authenticated
using (company_id in (select private.current_company_ids()));

create policy organization_units_admin_write on public.organization_units
for all to authenticated
using (private.has_company_role(company_id, array['owner'::public.membership_role,'admin'::public.membership_role]))
with check (private.has_company_role(company_id, array['owner'::public.membership_role,'admin'::public.membership_role]));

create policy companies_admin_update on public.companies
for update to authenticated
using (private.has_company_role(id, array['owner'::public.membership_role,'admin'::public.membership_role]))
with check (private.has_company_role(id, array['owner'::public.membership_role,'admin'::public.membership_role]));

grant update(name, timezone, branding) on public.companies to authenticated;

create or replace function public.admin_begin_configuration_draft(
  p_company_id uuid,
  p_version_label text default null
) returns uuid
language plpgsql
security invoker
set search_path = public, private, extensions
as $$
declare
  v_existing uuid;
  v_source uuid;
  v_new uuid;
  v_q record;
  v_new_question uuid;
begin
  if not private.has_company_role(p_company_id, array['owner'::public.membership_role,'admin'::public.membership_role]) then
    raise exception 'Not authorized to configure this company';
  end if;

  select id into v_existing
  from public.configuration_versions
  where company_id=p_company_id and status='draft'
  order by created_at desc
  limit 1;

  if v_existing is not null then
    return v_existing;
  end if;

  select id into v_source
  from public.configuration_versions
  where company_id=p_company_id and status='published'
  order by published_at desc nulls last, created_at desc
  limit 1;

  insert into public.configuration_versions(company_id,schema_version,version_label,status,minimum_client_version)
  values (
    p_company_id,
    coalesce((select schema_version from public.configuration_versions where id=v_source),'1.0.1'),
    coalesce(nullif(trim(p_version_label),''),'Configuration Draft '||to_char(now(),'YYYY-MM-DD HH24:MI')),
    'draft',
    (select minimum_client_version from public.configuration_versions where id=v_source)
  ) returning id into v_new;

  if v_source is not null then
    insert into public.configuration_options(company_id,config_version_id,library_type,option_code,label,sort_order,active,metadata)
    select company_id,v_new,library_type,option_code,label,sort_order,active,metadata
    from public.configuration_options where config_version_id=v_source;

    insert into public.rating_scale_items(company_id,config_version_id,code,label,score_value,sort_order,employee_visible)
    select company_id,v_new,code,label,score_value,sort_order,employee_visible
    from public.rating_scale_items where config_version_id=v_source;

    insert into public.goal_templates(company_id,config_version_id,role_id,label,goal_type,default_text,active)
    select company_id,v_new,role_id,label,goal_type,default_text,active
    from public.goal_templates where config_version_id=v_source;

    for v_q in
      select * from public.question_definitions where config_version_id=v_source order by sort_order,id
    loop
      insert into public.question_definitions(
        company_id,config_version_id,role_id,question_code,section_code,section_name,question_text,category,active,sort_order,
        question_weight,section_weight,requires_rating,requires_reason,notes_required_for_exceptional,notes_required_for_unsatisfactory
      ) values (
        v_q.company_id,v_new,v_q.role_id,v_q.question_code,v_q.section_code,v_q.section_name,v_q.question_text,v_q.category,v_q.active,v_q.sort_order,
        v_q.question_weight,v_q.section_weight,v_q.requires_rating,v_q.requires_reason,v_q.notes_required_for_exceptional,v_q.notes_required_for_unsatisfactory
      ) returning id into v_new_question;

      insert into public.reason_definitions(company_id,config_version_id,label,reason_type,rating_code,category,role_id,active,sort_order,external_code,question_id)
      select company_id,v_new,label,reason_type,rating_code,category,role_id,active,sort_order,external_code,v_new_question
      from public.reason_definitions where config_version_id=v_source and question_id=v_q.id;
    end loop;

    insert into public.reason_definitions(company_id,config_version_id,label,reason_type,rating_code,category,role_id,active,sort_order,external_code,question_id)
    select company_id,v_new,label,reason_type,rating_code,category,role_id,active,sort_order,external_code,null
    from public.reason_definitions where config_version_id=v_source and question_id is null;
  end if;

  return v_new;
end;
$$;

revoke all on function public.admin_begin_configuration_draft(uuid,text) from public, anon;
grant execute on function public.admin_begin_configuration_draft(uuid,text) to authenticated;

create or replace function public.admin_publish_configuration(
  p_company_id uuid,
  p_config_version_id uuid
) returns uuid
language plpgsql
security invoker
set search_path = public, private
as $$
begin
  if not private.has_company_role(p_company_id, array['owner'::public.membership_role,'admin'::public.membership_role]) then
    raise exception 'Not authorized to publish configuration for this company';
  end if;

  if not exists (
    select 1 from public.configuration_versions
    where id=p_config_version_id and company_id=p_company_id and status='draft'
  ) then
    raise exception 'Configuration draft not found';
  end if;

  update public.configuration_versions
  set status='retired'
  where company_id=p_company_id and status='published' and id<>p_config_version_id;

  update public.configuration_versions
  set status='published', published_at=now()
  where id=p_config_version_id and company_id=p_company_id;

  return p_config_version_id;
end;
$$;

revoke all on function public.admin_publish_configuration(uuid,uuid) from public, anon;
grant execute on function public.admin_publish_configuration(uuid,uuid) to authenticated;

create or replace view public.v_company_configuration_context
with (security_invoker=true)
as
select
  c.id as company_id,
  c.name as company_name,
  c.slug,
  c.timezone,
  c.branding,
  s.review_cadence_months,
  s.terminology,
  s.coaching_categories,
  cv.id as config_version_id,
  cv.version_label,
  cv.status as config_status,
  cv.published_at
from public.companies c
left join public.company_settings s on s.company_id=c.id
left join lateral (
  select x.* from public.configuration_versions x
  where x.company_id=c.id
  order by case when x.status='draft' then 0 when x.status='published' then 1 else 2 end, x.created_at desc
  limit 1
) cv on true;

grant select on public.v_company_configuration_context to authenticated;
revoke all on public.v_company_configuration_context from anon;

insert into public.company_settings(company_id)
select id from public.companies
on conflict (company_id) do nothing;

commit;