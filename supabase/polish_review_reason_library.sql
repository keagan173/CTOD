-- CTOD tailored review reason library polish
-- Date: 2026-08-10
--
-- Keeps every existing reason ID and external_code so saved review answers and
-- audit references remain intact. The update replaces mechanically generated
-- wording, backfills the intended question foreign key, and refuses to commit
-- unless the complete active library passes its integrity checks.

begin;

with question_actions as (
  select
    q.id,
    q.company_id,
    q.config_version_id,
    q.role_id,
    q.question_code,
    case q.question_code
      when 'A1-03' then 'perform inspections accurately and communicate findings clearly'
      when 'A2-04' then 'document inspections and recommendations accurately'
      when 'A3-01' then 'diagnose complex concerns accurately and efficiently'
      when 'A3-04' then 'document findings and recommended repairs accurately'
      when 'CS-01' then 'perform commercial tire service work safely and effectively'
      when 'CS-03' then 'inspect, document, and communicate tire conditions accurately'
      when 'IS-03' then 'prepare quotes, work orders, and customer information accurately'
      when 'LA-01' then 'diagnose and complete repairs accurately and efficiently'
      when 'LU-01' then 'complete oil and fluid services safely and accurately'
      when 'LU-05' then 'document services and communicate findings accurately'
      when 'ORG-008' then 'maintain dependable attendance, punctuality, preparation, and follow-through'
      when 'OS-04' then 'communicate pricing, services, timelines, and customer needs accurately'
      when 'SS-03' then 'handle tires, parts, equipment, and materials safely'
      when 'SS-05' then 'support teammates and maintain a productive work environment'
      when 'TT-01' then 'complete tire service work safely and effectively'
      else regexp_replace(
        regexp_replace(
          q.question_text,
          '^How (accurately and efficiently|safely and effectively|safely and accurately|consistently|effectively|accurately|well|safely) does this employee ',
          ''
        ),
        '\?$',
        ''
      )
    end as action
  from public.question_definitions q
  where q.active = true
), reason_updates as (
  select
    rd.id,
    qa.id as question_id,
    case rd.rating_code
      when 'EXCEPTIONAL' then case split_part(rd.external_code, ':', 3)
        when '1' then format('Consistently sets the standard for others when expected to %s.', qa.action)
        when '2' then format('Demonstrates exceptional consistency and follow-through when expected to %s.', qa.action)
        when '3' then format('Creates a clear positive impact when expected to %s.', qa.action)
      end
      when 'EXCEEDS' then case split_part(rd.external_code, ':', 3)
        when '1' then format('Regularly performs above role expectations when expected to %s.', qa.action)
        when '2' then format('Shows strong consistency and requires little follow-up when expected to %s.', qa.action)
        when '3' then format('Frequently adds value beyond normal role expectations when expected to %s.', qa.action)
      end
      when 'MEETS' then case split_part(rd.external_code, ':', 3)
        when '1' then format('Consistently meets the role standard when expected to %s.', qa.action)
        when '2' then format('Follows through at the expected level when required to %s.', qa.action)
        when '3' then format('Reliably handles the responsibility to %s.', qa.action)
      end
      when 'NEEDS_IMPROVEMENT' then case split_part(rd.external_code, ':', 3)
        when '1' then format('Performance is inconsistent when expected to %s.', qa.action)
        when '2' then format('Needs additional coaching or follow-through to consistently %s.', qa.action)
        when '3' then format('Does not yet meet the role standard consistently when expected to %s.', qa.action)
      end
      when 'UNSATISFACTORY' then case split_part(rd.external_code, ':', 3)
        when '1' then format('Frequently performs below the required standard when expected to %s.', qa.action)
        when '2' then format('Creates significant risk or disruption when expected to %s.', qa.action)
        when '3' then format('Has not met the minimum standard when required to %s, even after clear coaching.', qa.action)
      end
    end as polished_label
  from public.reason_definitions rd
  join question_actions qa
    on qa.company_id = rd.company_id
   and qa.config_version_id = rd.config_version_id
   and qa.question_code = split_part(rd.external_code, ':', 1)
  where rd.active = true
    and rd.reason_type in ('review_org', 'review_role')
    and split_part(rd.external_code, ':', 3) in ('1', '2', '3')
)
update public.reason_definitions rd
set
  question_id = ru.question_id,
  label = ru.polished_label
from reason_updates ru
where rd.id = ru.id
  and ru.polished_label is not null;

do $$
declare
  v_question_count integer;
  v_reason_count integer;
  v_bad_groups integer;
  v_bad_rows integer;
begin
  select count(*)
    into v_question_count
  from public.question_definitions
  where active = true;

  select count(*)
    into v_reason_count
  from public.reason_definitions
  where active = true
    and reason_type in ('review_org', 'review_role');

  if v_reason_count <> v_question_count * 15 then
    raise exception 'Review reason count mismatch: % active questions require % reasons, found %',
      v_question_count, v_question_count * 15, v_reason_count;
  end if;

  select count(*)
    into v_bad_groups
  from (
    select q.id, expected.rating_code
    from public.question_definitions q
    cross join (
      values
        ('EXCEPTIONAL'),
        ('EXCEEDS'),
        ('MEETS'),
        ('NEEDS_IMPROVEMENT'),
        ('UNSATISFACTORY')
    ) as expected(rating_code)
    left join public.reason_definitions rd
      on rd.question_id = q.id
     and rd.rating_code = expected.rating_code
     and rd.active = true
     and rd.reason_type in ('review_org', 'review_role')
    where q.active = true
    group by q.id, expected.rating_code
    having count(rd.id) <> 3
       or count(distinct rd.label) <> 3
  ) invalid_groups;

  if v_bad_groups <> 0 then
    raise exception 'Review reason group validation failed for % question/rating groups', v_bad_groups;
  end if;

  select count(*)
    into v_bad_rows
  from public.reason_definitions rd
  left join public.question_definitions q on q.id = rd.question_id
  where rd.active = true
    and rd.reason_type in ('review_org', 'review_role')
    and (
      rd.question_id is null
      or q.id is null
      or q.active is not true
      or q.company_id <> rd.company_id
      or q.config_version_id <> rd.config_version_id
      or q.role_id is distinct from rd.role_id
      or split_part(rd.external_code, ':', 1) <> q.question_code
      or split_part(rd.external_code, ':', 2) <> rd.rating_code
      or split_part(rd.external_code, ':', 3) not in ('1', '2', '3')
      or rd.label is null
      or rd.label <> btrim(rd.label)
      or rd.label !~ '\.$'
      or rd.label ~ '\?'
      or rd.label ~ '[[:space:]]{2,}'
      or rd.label ~ '\.\.'
      or rd.label ilike '%in this area:%'
      or rd.label ilike '%How % does this employee%'
      or char_length(rd.label) > 160
    );

  if v_bad_rows <> 0 then
    raise exception 'Review reason wording/link validation failed for % rows', v_bad_rows;
  end if;

  select count(*)
    into v_bad_rows
  from (
    select external_code
    from public.reason_definitions
    where active = true
      and reason_type in ('review_org', 'review_role')
    group by external_code
    having count(*) <> 1
  ) duplicate_codes;

  if v_bad_rows <> 0 then
    raise exception 'Review reason external_code validation found % duplicates', v_bad_rows;
  end if;
end
$$;

commit;
