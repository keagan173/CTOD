-- CTOD SANDBOX ONLY. Never add this file to supabase/migrations.
-- This script refuses to install when Auth or CTOD access users already exist.

begin;

do $$
begin
  if exists (select 1 from auth.users)
     or exists (select 1 from public.profiles)
     or exists (select 1 from public.company_memberships) then
    raise exception 'Sandbox bootstrap refused: this database already contains login/access users';
  end if;
end;
$$;

create schema if not exists ctod_sandbox;
revoke all on schema ctod_sandbox from public, anon, authenticated;

create table if not exists ctod_sandbox.environment_guard (
  singleton boolean primary key default true check (singleton),
  environment text not null check (environment = 'sandbox'),
  production_project_ref text not null,
  sandbox_project_ref text not null,
  installed_at timestamptz not null default now(),
  last_reset_at timestamptz
);

insert into ctod_sandbox.environment_guard (
  singleton,
  environment,
  production_project_ref,
  sandbox_project_ref
)
values (
  true,
  'sandbox',
  'wezcuprboyvbmlnuqdoi',
  '__CTOD_SANDBOX_PROJECT_REF__'
)
on conflict (singleton) do update
set environment = excluded.environment,
    production_project_ref = excluded.production_project_ref,
    sandbox_project_ref = excluded.sandbox_project_ref;

revoke all on all tables in schema ctod_sandbox from public, anon, authenticated;

commit;
