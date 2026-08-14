create or replace function private.seed_blank_standard_rating_scale()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'published'::public.config_status
     and new.version_label like 'Blank Standard Master %'
     and exists (select 1 from public.companies c where c.id=new.company_id and c.industry_code='BLANK') then
    insert into public.rating_scale_items(company_id,config_version_id,code,label,score_value,sort_order,employee_visible)
    values
      (new.company_id,new.id,'EXCEPTIONAL','Exceptional',5,1,true),
      (new.company_id,new.id,'EXCEEDS','Exceeds Expectations',4,2,true),
      (new.company_id,new.id,'MEETS','Meets Expectations',3,3,true),
      (new.company_id,new.id,'NEEDS_IMPROVEMENT','Needs Improvement',2,4,true),
      (new.company_id,new.id,'UNSATISFACTORY','Unsatisfactory',1,5,true)
    on conflict (config_version_id,code) do nothing;
  end if;
  return new;
end;
$$;

revoke all on function private.seed_blank_standard_rating_scale() from public, anon, authenticated;

drop trigger if exists trg_seed_blank_standard_rating_scale on public.configuration_versions;
create trigger trg_seed_blank_standard_rating_scale
after insert on public.configuration_versions
for each row execute function private.seed_blank_standard_rating_scale();

insert into public.rating_scale_items(company_id,config_version_id,code,label,score_value,sort_order,employee_visible)
select cv.company_id,cv.id,x.code,x.label,x.score_value,x.sort_order,true
from public.configuration_versions cv
join public.companies c on c.id=cv.company_id and c.industry_code='BLANK'
cross join (values
  ('EXCEPTIONAL'::text,'Exceptional'::text,5::numeric,1),
  ('EXCEEDS','Exceeds Expectations',4,2),
  ('MEETS','Meets Expectations',3,3),
  ('NEEDS_IMPROVEMENT','Needs Improvement',2,4),
  ('UNSATISFACTORY','Unsatisfactory',1,5)
) as x(code,label,score_value,sort_order)
where cv.status='published'::public.config_status and cv.version_label like 'Blank Standard Master %'
on conflict (config_version_id,code) do nothing;