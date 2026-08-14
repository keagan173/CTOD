-- CTOD 002 Platform Release Control tables
create table if not exists private.platform_release_validations (
  id uuid primary key default extensions.gen_random_uuid(),
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
create index if not exists platform_release_validations_release_idx on private.platform_release_validations(release_id, validated_at desc);
create table if not exists private.platform_release_targets (
  id uuid primary key default extensions.gen_random_uuid(),
  release_id uuid not null references private.platform_releases(id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete cascade,
  rollout_stage text not null default 'selected' check (rollout_stage in ('pilot','selected','all')),
  status text not null default 'scheduled' check (status in ('scheduled','active','failed','rolled_back','cancelled')),
  reason text,
  scheduled_by_user_id uuid not null,
  scheduled_at timestamptz not null default now(),
  activated_at timestamptz,
  rolled_back_at timestamptz,
  updated_at timestamptz not null default now(),
  unique(release_id, company_id)
);
create index if not exists platform_release_targets_release_idx on private.platform_release_targets(release_id,status,scheduled_at desc);
