-- Read-only CTOD sandbox verification.

select
  g.environment,
  g.production_project_ref,
  g.sandbox_project_ref,
  g.installed_at,
  g.last_reset_at,
  (select count(*) from auth.users) as auth_users,
  (select count(*) from public.profiles) as profiles,
  (select count(*) from public.company_memberships where active) as active_memberships,
  (select role::text from public.company_memberships where active limit 1) as membership_role,
  (select count(*) from public.audit_events where event_type = 'sandbox.master.created') as bootstrap_markers,
  (select count(*) from public.employees) as employees,
  (select count(*) from public.employment_assignments where effective_to is null) as active_assignments,
  (select count(*) from public.reviews) as reviews,
  (select count(*) from public.review_answers) as review_answers,
  (select count(*) from public.coaching_moments) as coaching_moments,
  (select count(*) from public.goals) as goals,
  not exists (
    select 1 from public.employees
    where employee_code not like '99%'
       or last_name <> 'Sandbox'
  ) as contains_only_synthetic_employees
from ctod_sandbox.environment_guard g
where g.singleton;
