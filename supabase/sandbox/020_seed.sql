-- CTOD SANDBOX ONLY. Idempotent synthetic roster for Location 040.

begin;

do $$
declare
  v_company uuid;
  v_location uuid;
  v_general_manager uuid;
  v_assistant_manager uuid;
  v_tire_technician uuid;
begin
  if not exists (
    select 1
    from ctod_sandbox.environment_guard
    where singleton
      and environment = 'sandbox'
      and production_project_ref <> sandbox_project_ref
  ) then
    raise exception 'Sandbox seed refused: environment guard is missing or invalid';
  end if;

  select id into strict v_company from public.companies order by created_at limit 1;
  select id into strict v_location from public.locations where location_code = '040' and status = 'active';
  select id into strict v_general_manager from public.roles where title = 'General Manager' and active;
  select id into strict v_assistant_manager from public.roles where title = 'Assistant Manager' and active;
  select id into strict v_tire_technician from public.roles where title = 'Tire Technician' and active;

  insert into public.employees (
    id, company_id, employee_code, first_name, last_name, hire_date, employment_status
  ) values
    ('90000000-0000-4000-8000-000000990001', v_company, '990001', 'Avery', 'Sandbox', '2022-03-14', 'active'),
    ('90000000-0000-4000-8000-000000990002', v_company, '990002', 'Jordan', 'Sandbox', '2023-08-21', 'active'),
    ('90000000-0000-4000-8000-000000990003', v_company, '990003', 'Riley', 'Sandbox', '2025-01-06', 'active')
  on conflict (id) do update
  set employee_code = excluded.employee_code,
      first_name = excluded.first_name,
      last_name = excluded.last_name,
      hire_date = excluded.hire_date,
      employment_status = excluded.employment_status,
      updated_at = now();

  insert into public.employment_assignments (
    id, company_id, employee_id, location_id, role_id, manager_employee_id,
    current_pay, pay_type, effective_from, effective_to
  ) values
    ('91000000-0000-4000-8000-000000990001', v_company, '90000000-0000-4000-8000-000000990001', v_location, v_general_manager, null, 85000, 'salary', '2022-03-14', null),
    ('91000000-0000-4000-8000-000000990002', v_company, '90000000-0000-4000-8000-000000990002', v_location, v_assistant_manager, '90000000-0000-4000-8000-000000990001', 28.50, 'hourly', '2023-08-21', null),
    ('91000000-0000-4000-8000-000000990003', v_company, '90000000-0000-4000-8000-000000990003', v_location, v_tire_technician, '90000000-0000-4000-8000-000000990001', 21.00, 'hourly', '2025-01-06', null)
  on conflict (id) do update
  set location_id = excluded.location_id,
      role_id = excluded.role_id,
      manager_employee_id = excluded.manager_employee_id,
      current_pay = excluded.current_pay,
      pay_type = excluded.pay_type,
      effective_from = excluded.effective_from,
      effective_to = excluded.effective_to;

  insert into public.audit_events (
    company_id, event_type, entity_type, after_json, reason
  ) values (
    v_company,
    'sandbox.seeded',
    'environment',
    jsonb_build_object('employee_codes', array['990001','990002','990003'], 'location_code', '040'),
    'Synthetic CTOD sandbox baseline'
  );
end;
$$;

commit;
