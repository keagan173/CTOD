begin;

create table if not exists private.platform_releases (
  id uuid primary key default gen_random_uuid(),
  version_code text not null unique,
  status text not null default 'candidate' check(status in ('candidate','validated','available','retired')),
  minimum_schema_version text,
  release_notes text,
  released_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists private.platform_release_validations (
  id uuid primary key default gen_random_uuid(),
  release_id uuid not null references private.platform_releases(id) on delete cascade,
  actor_user_id uuid not null,
  source_commit_sha text,
  automated_tests_passed boolean not null default false,
  security_review_passed boolean not null default false,
  acceptance_test_passed boolean not null default false,
  notes text,
  passed boolean generated always as (automated_tests_passed and security_review_passed and acceptance_test_passed) stored,
  validated_at timestamptz not null default now()
);
create index if not exists platform_release_validations_release_idx on private.platform_release_validations(release_id,validated_at desc);

create table if not exists private.platform_release_targets (
  id uuid primary key default gen_random_uuid(),
  release_id uuid not null references private.platform_releases(id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete cascade,
  rollout_stage text not null default 'selected' check(rollout_stage in ('pilot','selected','all')),
  status text not null default 'scheduled' check(status in ('scheduled','active','failed','rolled_back','cancelled')),
  reason text,
  scheduled_by_user_id uuid not null,
  scheduled_at timestamptz not null default now(),
  activated_at timestamptz,
  rolled_back_at timestamptz,
  updated_at timestamptz not null default now(),
  unique(release_id,company_id)
);
create index if not exists platform_release_targets_release_idx on private.platform_release_targets(release_id,status,scheduled_at desc);

create table if not exists private.customer_release_history (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  actor_user_id uuid not null,
  action text not null,
  from_version text,
  to_version text,
  reason text,
  occurred_at timestamptz not null default now()
);
create index if not exists customer_release_history_company_idx on private.customer_release_history(company_id,occurred_at desc);

revoke all on private.platform_releases from public,anon,authenticated;
revoke all on private.platform_release_validations from public,anon,authenticated;
revoke all on private.platform_release_targets from public,anon,authenticated;
revoke all on private.customer_release_history from public,anon,authenticated;
grant select,insert,update,delete on private.platform_releases to service_role;
grant select,insert,update,delete on private.platform_release_validations to service_role;
grant select,insert,update,delete on private.platform_release_targets to service_role;
grant select,insert on private.customer_release_history to service_role;

insert into private.platform_releases(version_code,status,minimum_schema_version,release_notes,released_at)
values('1.0.1','available','1.0.1','Protected CTOD 001 production baseline.',now())
on conflict(version_code) do update set status='available',minimum_schema_version=excluded.minimum_schema_version,release_notes=excluded.release_notes,released_at=coalesce(private.platform_releases.released_at,excluded.released_at);

insert into private.platform_releases(version_code,status,minimum_schema_version,release_notes)
values('1.1.0','candidate','1.0.1','Validated multi-tenant platform architecture from CTOD 002. Production release remains gated until production compatibility and smoke tests pass.')
on conflict(version_code) do nothing;

commit;
