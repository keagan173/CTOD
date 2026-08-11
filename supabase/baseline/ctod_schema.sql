-- CTOD database schema baseline
-- Generated from the verified production catalog on 2026-08-11.
-- This file is for provisioning a new, empty CTOD environment. It is
-- intentionally outside supabase/migrations so it can never replay on
-- the existing production project.

begin;

set search_path = public, extensions, auth, pg_catalog;

-- Extensions
create extension if not exists "pg_net" with schema "extensions";
create extension if not exists "pgcrypto" with schema "extensions";
create extension if not exists "supabase_vault" with schema "vault";
create extension if not exists "uuid-ossp" with schema "extensions";

-- Private helper schema
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

-- Enum types
create type public."campaign_status" as enum ('draft', 'upcoming', 'open', 'closed');
create type public."coaching_disposition" as enum ('carry_forward', 'escalated', 'resolved');
create type public."coaching_type" as enum ('recognition', 'development', 'corrective');
create type public."config_status" as enum ('draft', 'published', 'retired');
create type public."goal_status" as enum ('not_started', 'in_progress', 'completed', 'cancelled');
create type public."membership_role" as enum ('owner', 'admin', 'executive', 'area_leader', 'market_leader', 'manager', 'viewer');
create type public."review_status" as enum ('not_due', 'queued', 'in_progress', 'blocked', 'ready_to_finalize', 'finalized', 'reopened');

-- Tables
create table public."access_invite_locations" (
  "invite_id" uuid not null,
  "location_id" uuid not null
);

create table public."access_invites" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "email" text not null,
  "intended_role" membership_role not null,
  "invited_by_user_id" uuid not null,
  "token" uuid default gen_random_uuid() not null,
  "expires_at" timestamp with time zone default (now() + '14 days'::interval) not null,
  "accepted_at" timestamp with time zone,
  "revoked_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null
);

create table public."attachments" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "entity_type" text not null,
  "entity_id" uuid not null,
  "file_uri" text not null,
  "file_name" text not null,
  "mime_type" text not null,
  "uploaded_by_user_id" uuid,
  "uploaded_at" timestamp with time zone default now() not null
);

create table public."audit_events" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "actor_user_id" uuid,
  "event_type" text not null,
  "entity_type" text not null,
  "entity_id" uuid,
  "occurred_at" timestamp with time zone default now() not null,
  "before_json" jsonb,
  "after_json" jsonb,
  "reason" text
);

create table public."career_decisions" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "review_id" uuid not null,
  "employee_id" uuid not null,
  "promotion_interest" boolean default false not null,
  "desired_role_id" uuid,
  "promotion_readiness" text,
  "more_responsibility_interest" boolean default false not null,
  "schedule_change_interest" boolean default false not null,
  "transfer_interest" boolean default false not null,
  "relocation_interest" boolean default false not null,
  "mobility_scope" text,
  "created_at" timestamp with time zone default now() not null,
  "final_desired_role_id" uuid,
  "career_direction" text,
  "career_direction_reason" text
);

create table public."coaching_moments" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "employee_id" uuid not null,
  "created_by_user_id" uuid,
  "occurred_at" timestamp with time zone not null,
  "type" coaching_type not null,
  "category" text not null,
  "reason_id" uuid,
  "notes" text,
  "expected_outcome" text,
  "include_in_review" boolean default true not null,
  "record_status" text default 'active'::text not null,
  "resolved_streak" integer default 0 not null,
  "active_carry_forward" boolean default true not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "external_coaching_id" text,
  "reason_text" text,
  "legacy_status" text,
  "review_cycle" text,
  "source_version" text
);

create table public."coaching_review_links" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "coaching_id" uuid not null,
  "review_id" uuid not null,
  "disposition" coaching_disposition not null,
  "included_on_summary" boolean default true not null,
  "created_at" timestamp with time zone default now() not null
);

create table public."companies" (
  "id" uuid default gen_random_uuid() not null,
  "industry_code" text default '001'::text not null,
  "name" text not null,
  "slug" text not null,
  "timezone" text default 'America/Boise'::text not null,
  "status" text default 'active'::text not null,
  "branding" jsonb default '{}'::jsonb not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

create table public."company_memberships" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "user_id" uuid not null,
  "role" membership_role default 'viewer'::membership_role not null,
  "location_id" uuid,
  "active" boolean default true not null,
  "created_at" timestamp with time zone default now() not null
);

create table public."compensation_decisions" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "review_id" uuid not null,
  "employee_id" uuid not null,
  "raise_requested" boolean default false not null,
  "raise_basis" text,
  "decision_status" text default 'not_discussed'::text not null,
  "timing_type" text,
  "planned_effective_date" date,
  "amount_type" text,
  "amount_value" numeric(12,2),
  "linked_goal_id" uuid,
  "completed_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null,
  "raise_reason_code" text,
  "employee_raise_note" text,
  "requested_timing" text,
  "requested_specific_date" date,
  "manager_timing" text,
  "manager_comment_code" text
);

create table public."configuration_options" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "config_version_id" uuid not null,
  "library_type" text not null,
  "option_code" text not null,
  "label" text not null,
  "sort_order" integer default 0 not null,
  "active" boolean default true not null,
  "metadata" jsonb default '{}'::jsonb not null
);

create table public."configuration_versions" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "schema_version" text not null,
  "version_label" text not null,
  "status" config_status default 'draft'::config_status not null,
  "minimum_client_version" text,
  "checksum" text,
  "published_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null
);

create table public."employees" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "employee_code" text not null,
  "first_name" text not null,
  "last_name" text not null,
  "hire_date" date,
  "employment_status" text default 'active'::text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

create table public."employment_assignments" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "employee_id" uuid not null,
  "location_id" uuid not null,
  "role_id" uuid not null,
  "manager_employee_id" uuid,
  "current_pay" numeric(12,2),
  "pay_type" text,
  "effective_from" date not null,
  "effective_to" date,
  "created_at" timestamp with time zone default now() not null
);

create table public."goal_templates" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "config_version_id" uuid not null,
  "role_id" uuid,
  "label" text not null,
  "goal_type" text not null,
  "default_text" text not null,
  "active" boolean default true not null
);

create table public."goals" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "employee_id" uuid not null,
  "origin_review_id" uuid,
  "goal_template_id" uuid,
  "goal_text" text not null,
  "goal_type" text not null,
  "status" goal_status default 'not_started'::goal_status not null,
  "target_date" date,
  "completed_at" timestamp with time zone,
  "raise_linked" boolean default false not null,
  "promotion_linked" boolean default false not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "external_goal_id" text,
  "external_review_id" text,
  "carry_forward" boolean default true not null,
  "source_version" text
);

create table public."import_batches" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "source_type" text not null,
  "source_name" text not null,
  "source_version" text,
  "schema_version" text,
  "started_at" timestamp with time zone default now() not null,
  "completed_at" timestamp with time zone,
  "status" text default 'pending'::text not null,
  "warning_count" integer default 0 not null,
  "error_count" integer default 0 not null,
  "record_counts" jsonb default '{}'::jsonb not null
);

create table public."locations" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "location_code" text not null,
  "name" text not null,
  "status" text default 'active'::text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "address_line1" text,
  "city" text,
  "state_code" text,
  "postal_code" text,
  "latitude" numeric,
  "longitude" numeric,
  "market_name" text,
  "area_name" text
);

create table public."manager_invitations" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "location_id" uuid not null,
  "email" text not null,
  "role" membership_role default 'manager'::membership_role not null,
  "status" text default 'pending'::text not null,
  "invited_by_user_id" uuid,
  "accepted_by_user_id" uuid,
  "created_at" timestamp with time zone default now() not null,
  "expires_at" timestamp with time zone default (now() + '14 days'::interval) not null,
  "accepted_at" timestamp with time zone,
  "revoked_at" timestamp with time zone
);

create table public."profiles" (
  "id" uuid not null,
  "display_name" text,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

create table public."question_definitions" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "config_version_id" uuid not null,
  "role_id" uuid,
  "question_code" text not null,
  "section_code" text not null,
  "section_name" text not null,
  "question_text" text not null,
  "category" text,
  "active" boolean default true not null,
  "sort_order" integer default 0 not null,
  "question_weight" numeric(8,6) default 0 not null,
  "section_weight" numeric(8,6) default 0 not null,
  "requires_rating" boolean default true not null,
  "requires_reason" boolean default true not null,
  "notes_required_for_exceptional" boolean default true not null,
  "notes_required_for_unsatisfactory" boolean default true not null
);

create table public."raise_reason_definitions" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "code" text not null,
  "label" text not null,
  "sort_order" integer default 0 not null,
  "active" boolean default true not null
);

create table public."rating_scale_items" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "config_version_id" uuid not null,
  "code" text not null,
  "label" text not null,
  "score_value" numeric(6,3) not null,
  "sort_order" integer default 0 not null,
  "employee_visible" boolean default true not null
);

create table public."reason_definitions" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "config_version_id" uuid not null,
  "label" text not null,
  "reason_type" text default 'review'::text not null,
  "rating_code" text,
  "category" text,
  "role_id" uuid,
  "active" boolean default true not null,
  "sort_order" integer default 0 not null,
  "external_code" text,
  "question_id" uuid
);

create table public."review_answers" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "review_id" uuid not null,
  "question_id" uuid not null,
  "rating_id" uuid,
  "primary_reason_id" uuid,
  "additional_reason_id" uuid,
  "manager_note" text,
  "prior_review_answer_id" uuid,
  "confirmed_current_cycle" boolean default false not null,
  "confirmed_at" timestamp with time zone,
  "backend_score" numeric(10,4),
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

create table public."review_campaigns" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "location_id" uuid,
  "cycle_code" text not null,
  "due_date" date not null,
  "reminder_mode" text default 'month_of'::text not null,
  "reminder_start_date" date,
  "status" campaign_status default 'draft'::campaign_status not null,
  "created_at" timestamp with time zone default now() not null
);

create table public."review_summaries" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "review_id" uuid not null,
  "generated_at" timestamp with time zone default now() not null,
  "template_version" text not null,
  "document_uri" text,
  "employee_acknowledged" boolean default false not null,
  "manager_acknowledged" boolean default false not null,
  "employee_comments" text,
  "manager_summary" text,
  "employee_signature_date" date,
  "manager_signature_date" date,
  "signed_copy_attachment_id" uuid
);

create table public."reviews" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "employee_id" uuid not null,
  "campaign_id" uuid not null,
  "manager_employee_id" uuid,
  "location_id" uuid not null,
  "role_id" uuid not null,
  "config_version_id" uuid not null,
  "status" review_status default 'queued'::review_status not null,
  "started_at" timestamp with time zone,
  "finalized_at" timestamp with time zone,
  "reopened_at" timestamp with time zone,
  "next_review_date" date,
  "source_client" text default 'web'::text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "external_review_id" text,
  "overall_rating_label" text,
  "overall_score" numeric(10,4),
  "overall_percent" numeric(10,6),
  "raise_recommendation" text,
  "promotion_readiness" text,
  "safety_cap_applied" boolean default false not null,
  "legacy_manager_name" text,
  "source_version" text,
  "review_date" date,
  "scheduled_review_date" date
);

create table public."roles" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "title" text not null,
  "active" boolean default true not null,
  "sort_order" integer default 0 not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

create table public."succession_records" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "employee_id" uuid not null,
  "current_role_id" uuid,
  "target_role_id" uuid,
  "readiness" text,
  "mobility" text,
  "manager_recommendation" text,
  "performance_trend" text,
  "active" boolean default true not null,
  "last_updated_at" timestamp with time zone default now() not null,
  "external_succession_id" text,
  "leadership_rating" text,
  "active_development_goal" boolean default false not null,
  "source_version" text,
  "legacy_target_role_name" text,
  "legacy_current_role_name" text
);

create table public."user_location_access" (
  "id" uuid default gen_random_uuid() not null,
  "company_id" uuid not null,
  "user_id" uuid not null,
  "location_id" uuid not null,
  "access_role" membership_role not null,
  "active" boolean default true not null,
  "granted_by_user_id" uuid,
  "granted_at" timestamp with time zone default now() not null,
  "revoked_at" timestamp with time zone
);

-- Constraints
alter table only public."access_invite_locations" add constraint "access_invite_locations_pkey" PRIMARY KEY (invite_id, location_id);
alter table only public."access_invites" add constraint "access_invites_pkey" PRIMARY KEY (id);
alter table only public."attachments" add constraint "attachments_pkey" PRIMARY KEY (id);
alter table only public."audit_events" add constraint "audit_events_pkey" PRIMARY KEY (id);
alter table only public."career_decisions" add constraint "career_decisions_pkey" PRIMARY KEY (id);
alter table only public."coaching_moments" add constraint "coaching_moments_pkey" PRIMARY KEY (id);
alter table only public."coaching_review_links" add constraint "coaching_review_links_pkey" PRIMARY KEY (id);
alter table only public."companies" add constraint "companies_pkey" PRIMARY KEY (id);
alter table only public."company_memberships" add constraint "company_memberships_pkey" PRIMARY KEY (id);
alter table only public."compensation_decisions" add constraint "compensation_decisions_pkey" PRIMARY KEY (id);
alter table only public."configuration_options" add constraint "configuration_options_pkey" PRIMARY KEY (id);
alter table only public."configuration_versions" add constraint "configuration_versions_pkey" PRIMARY KEY (id);
alter table only public."employees" add constraint "employees_pkey" PRIMARY KEY (id);
alter table only public."employment_assignments" add constraint "employment_assignments_pkey" PRIMARY KEY (id);
alter table only public."goal_templates" add constraint "goal_templates_pkey" PRIMARY KEY (id);
alter table only public."goals" add constraint "goals_pkey" PRIMARY KEY (id);
alter table only public."import_batches" add constraint "import_batches_pkey" PRIMARY KEY (id);
alter table only public."locations" add constraint "locations_pkey" PRIMARY KEY (id);
alter table only public."manager_invitations" add constraint "manager_invitations_pkey" PRIMARY KEY (id);
alter table only public."profiles" add constraint "profiles_pkey" PRIMARY KEY (id);
alter table only public."question_definitions" add constraint "question_definitions_pkey" PRIMARY KEY (id);
alter table only public."raise_reason_definitions" add constraint "raise_reason_definitions_pkey" PRIMARY KEY (id);
alter table only public."rating_scale_items" add constraint "rating_scale_items_pkey" PRIMARY KEY (id);
alter table only public."reason_definitions" add constraint "reason_definitions_pkey" PRIMARY KEY (id);
alter table only public."review_answers" add constraint "review_answers_pkey" PRIMARY KEY (id);
alter table only public."review_campaigns" add constraint "review_campaigns_pkey" PRIMARY KEY (id);
alter table only public."review_summaries" add constraint "review_summaries_pkey" PRIMARY KEY (id);
alter table only public."reviews" add constraint "reviews_pkey" PRIMARY KEY (id);
alter table only public."roles" add constraint "roles_pkey" PRIMARY KEY (id);
alter table only public."succession_records" add constraint "succession_records_pkey" PRIMARY KEY (id);
alter table only public."user_location_access" add constraint "user_location_access_pkey" PRIMARY KEY (id);
alter table only public."access_invites" add constraint "access_invites_token_key" UNIQUE (token);
alter table only public."career_decisions" add constraint "career_decisions_review_id_employee_id_key" UNIQUE (review_id, employee_id);
alter table only public."coaching_review_links" add constraint "coaching_review_links_coaching_id_review_id_key" UNIQUE (coaching_id, review_id);
alter table only public."companies" add constraint "companies_slug_key" UNIQUE (slug);
alter table only public."company_memberships" add constraint "company_memberships_company_id_user_id_key" UNIQUE (company_id, user_id);
alter table only public."compensation_decisions" add constraint "compensation_decisions_review_id_employee_id_key" UNIQUE (review_id, employee_id);
alter table only public."configuration_options" add constraint "configuration_options_config_version_id_option_code_key" UNIQUE (config_version_id, option_code);
alter table only public."configuration_versions" add constraint "configuration_versions_company_id_version_label_key" UNIQUE (company_id, version_label);
alter table only public."employees" add constraint "employees_company_id_employee_code_key" UNIQUE (company_id, employee_code);
alter table only public."locations" add constraint "locations_company_id_location_code_key" UNIQUE (company_id, location_code);
alter table only public."question_definitions" add constraint "question_definitions_config_version_id_question_code_key" UNIQUE (config_version_id, question_code);
alter table only public."raise_reason_definitions" add constraint "raise_reason_definitions_company_id_code_key" UNIQUE (company_id, code);
alter table only public."rating_scale_items" add constraint "rating_scale_items_config_version_id_code_key" UNIQUE (config_version_id, code);
alter table only public."review_answers" add constraint "review_answers_review_id_question_id_key" UNIQUE (review_id, question_id);
alter table only public."review_campaigns" add constraint "review_campaigns_company_id_cycle_code_location_id_key" UNIQUE (company_id, cycle_code, location_id);
alter table only public."review_summaries" add constraint "review_summaries_review_id_key" UNIQUE (review_id);
alter table only public."reviews" add constraint "reviews_employee_id_campaign_id_key" UNIQUE (employee_id, campaign_id);
alter table only public."roles" add constraint "roles_company_id_title_key" UNIQUE (company_id, title);
alter table only public."user_location_access" add constraint "user_location_access_user_id_location_id_key" UNIQUE (user_id, location_id);
alter table only public."coaching_moments" add constraint "coaching_moments_record_status_check" CHECK (record_status = ANY (ARRAY['active'::text, 'archived'::text]));
alter table only public."companies" add constraint "companies_status_check" CHECK (status = ANY (ARRAY['active'::text, 'inactive'::text]));
alter table only public."employees" add constraint "employees_employee_code_check" CHECK (employee_code ~ '^[0-9]{6}$'::text);
alter table only public."employees" add constraint "employees_employee_code_six_digits" CHECK (employee_code ~ '^[0-9]{6}$'::text);
alter table only public."employees" add constraint "employees_employment_status_check" CHECK (employment_status = ANY (ARRAY['active'::text, 'leave'::text, 'terminated'::text, 'archived'::text]));
alter table only public."employment_assignments" add constraint "employment_assignments_check" CHECK (effective_to IS NULL OR effective_to >= effective_from);
alter table only public."locations" add constraint "locations_status_check" CHECK (status = ANY (ARRAY['active'::text, 'inactive'::text]));
alter table only public."manager_invitations" add constraint "manager_invitations_status_check" CHECK (status = ANY (ARRAY['pending'::text, 'accepted'::text, 'revoked'::text, 'expired'::text]));
alter table only public."access_invite_locations" add constraint "access_invite_locations_invite_id_fkey" FOREIGN KEY (invite_id) REFERENCES access_invites(id) ON DELETE CASCADE;
alter table only public."access_invite_locations" add constraint "access_invite_locations_location_id_fkey" FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE;
alter table only public."access_invites" add constraint "access_invites_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."access_invites" add constraint "access_invites_invited_by_user_id_fkey" FOREIGN KEY (invited_by_user_id) REFERENCES auth.users(id);
alter table only public."attachments" add constraint "attachments_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."attachments" add constraint "attachments_uploaded_by_user_id_fkey" FOREIGN KEY (uploaded_by_user_id) REFERENCES auth.users(id);
alter table only public."audit_events" add constraint "audit_events_actor_user_id_fkey" FOREIGN KEY (actor_user_id) REFERENCES auth.users(id);
alter table only public."audit_events" add constraint "audit_events_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."career_decisions" add constraint "career_decisions_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."career_decisions" add constraint "career_decisions_desired_role_id_fkey" FOREIGN KEY (desired_role_id) REFERENCES roles(id);
alter table only public."career_decisions" add constraint "career_decisions_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES employees(id);
alter table only public."career_decisions" add constraint "career_decisions_final_desired_role_id_fkey" FOREIGN KEY (final_desired_role_id) REFERENCES roles(id);
alter table only public."career_decisions" add constraint "career_decisions_review_id_fkey" FOREIGN KEY (review_id) REFERENCES reviews(id) ON DELETE CASCADE;
alter table only public."coaching_moments" add constraint "coaching_moments_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."coaching_moments" add constraint "coaching_moments_created_by_user_id_fkey" FOREIGN KEY (created_by_user_id) REFERENCES auth.users(id);
alter table only public."coaching_moments" add constraint "coaching_moments_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES employees(id);
alter table only public."coaching_moments" add constraint "coaching_moments_reason_id_fkey" FOREIGN KEY (reason_id) REFERENCES reason_definitions(id);
alter table only public."coaching_review_links" add constraint "coaching_review_links_coaching_id_fkey" FOREIGN KEY (coaching_id) REFERENCES coaching_moments(id) ON DELETE CASCADE;
alter table only public."coaching_review_links" add constraint "coaching_review_links_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."coaching_review_links" add constraint "coaching_review_links_review_id_fkey" FOREIGN KEY (review_id) REFERENCES reviews(id) ON DELETE CASCADE;
alter table only public."company_memberships" add constraint "company_memberships_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."company_memberships" add constraint "company_memberships_location_id_fkey" FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE SET NULL;
alter table only public."company_memberships" add constraint "company_memberships_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table only public."compensation_decisions" add constraint "compensation_decisions_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."compensation_decisions" add constraint "compensation_decisions_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES employees(id);
alter table only public."compensation_decisions" add constraint "compensation_decisions_linked_goal_id_fkey" FOREIGN KEY (linked_goal_id) REFERENCES goals(id);
alter table only public."compensation_decisions" add constraint "compensation_decisions_review_id_fkey" FOREIGN KEY (review_id) REFERENCES reviews(id) ON DELETE CASCADE;
alter table only public."configuration_options" add constraint "configuration_options_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."configuration_options" add constraint "configuration_options_config_version_id_fkey" FOREIGN KEY (config_version_id) REFERENCES configuration_versions(id) ON DELETE CASCADE;
alter table only public."configuration_versions" add constraint "configuration_versions_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."employees" add constraint "employees_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."employment_assignments" add constraint "employment_assignments_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."employment_assignments" add constraint "employment_assignments_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE;
alter table only public."employment_assignments" add constraint "employment_assignments_location_id_fkey" FOREIGN KEY (location_id) REFERENCES locations(id);
alter table only public."employment_assignments" add constraint "employment_assignments_manager_employee_id_fkey" FOREIGN KEY (manager_employee_id) REFERENCES employees(id);
alter table only public."employment_assignments" add constraint "employment_assignments_role_id_fkey" FOREIGN KEY (role_id) REFERENCES roles(id);
alter table only public."goal_templates" add constraint "goal_templates_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."goal_templates" add constraint "goal_templates_config_version_id_fkey" FOREIGN KEY (config_version_id) REFERENCES configuration_versions(id) ON DELETE CASCADE;
alter table only public."goal_templates" add constraint "goal_templates_role_id_fkey" FOREIGN KEY (role_id) REFERENCES roles(id);
alter table only public."goals" add constraint "goals_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."goals" add constraint "goals_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES employees(id);
alter table only public."goals" add constraint "goals_goal_template_id_fkey" FOREIGN KEY (goal_template_id) REFERENCES goal_templates(id);
alter table only public."goals" add constraint "goals_origin_review_id_fkey" FOREIGN KEY (origin_review_id) REFERENCES reviews(id);
alter table only public."import_batches" add constraint "import_batches_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."locations" add constraint "locations_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."manager_invitations" add constraint "manager_invitations_accepted_by_user_id_fkey" FOREIGN KEY (accepted_by_user_id) REFERENCES auth.users(id);
alter table only public."manager_invitations" add constraint "manager_invitations_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."manager_invitations" add constraint "manager_invitations_invited_by_user_id_fkey" FOREIGN KEY (invited_by_user_id) REFERENCES auth.users(id);
alter table only public."manager_invitations" add constraint "manager_invitations_location_id_fkey" FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE;
alter table only public."profiles" add constraint "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table only public."question_definitions" add constraint "question_definitions_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."question_definitions" add constraint "question_definitions_config_version_id_fkey" FOREIGN KEY (config_version_id) REFERENCES configuration_versions(id) ON DELETE CASCADE;
alter table only public."question_definitions" add constraint "question_definitions_role_id_fkey" FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;
alter table only public."raise_reason_definitions" add constraint "raise_reason_definitions_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."rating_scale_items" add constraint "rating_scale_items_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."rating_scale_items" add constraint "rating_scale_items_config_version_id_fkey" FOREIGN KEY (config_version_id) REFERENCES configuration_versions(id) ON DELETE CASCADE;
alter table only public."reason_definitions" add constraint "reason_definitions_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."reason_definitions" add constraint "reason_definitions_config_version_id_fkey" FOREIGN KEY (config_version_id) REFERENCES configuration_versions(id) ON DELETE CASCADE;
alter table only public."reason_definitions" add constraint "reason_definitions_question_id_fkey" FOREIGN KEY (question_id) REFERENCES question_definitions(id) ON DELETE CASCADE;
alter table only public."reason_definitions" add constraint "reason_definitions_role_id_fkey" FOREIGN KEY (role_id) REFERENCES roles(id);
alter table only public."review_answers" add constraint "review_answers_additional_reason_id_fkey" FOREIGN KEY (additional_reason_id) REFERENCES reason_definitions(id);
alter table only public."review_answers" add constraint "review_answers_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."review_answers" add constraint "review_answers_primary_reason_id_fkey" FOREIGN KEY (primary_reason_id) REFERENCES reason_definitions(id);
alter table only public."review_answers" add constraint "review_answers_prior_review_answer_id_fkey" FOREIGN KEY (prior_review_answer_id) REFERENCES review_answers(id);
alter table only public."review_answers" add constraint "review_answers_question_id_fkey" FOREIGN KEY (question_id) REFERENCES question_definitions(id);
alter table only public."review_answers" add constraint "review_answers_rating_id_fkey" FOREIGN KEY (rating_id) REFERENCES rating_scale_items(id);
alter table only public."review_answers" add constraint "review_answers_review_id_fkey" FOREIGN KEY (review_id) REFERENCES reviews(id) ON DELETE CASCADE;
alter table only public."review_campaigns" add constraint "review_campaigns_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."review_campaigns" add constraint "review_campaigns_location_id_fkey" FOREIGN KEY (location_id) REFERENCES locations(id);
alter table only public."review_summaries" add constraint "review_summaries_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."review_summaries" add constraint "review_summaries_review_id_fkey" FOREIGN KEY (review_id) REFERENCES reviews(id) ON DELETE CASCADE;
alter table only public."review_summaries" add constraint "review_summaries_signed_copy_attachment_id_fkey" FOREIGN KEY (signed_copy_attachment_id) REFERENCES attachments(id) ON DELETE SET NULL;
alter table only public."reviews" add constraint "reviews_campaign_id_fkey" FOREIGN KEY (campaign_id) REFERENCES review_campaigns(id);
alter table only public."reviews" add constraint "reviews_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."reviews" add constraint "reviews_config_version_id_fkey" FOREIGN KEY (config_version_id) REFERENCES configuration_versions(id);
alter table only public."reviews" add constraint "reviews_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES employees(id);
alter table only public."reviews" add constraint "reviews_location_id_fkey" FOREIGN KEY (location_id) REFERENCES locations(id);
alter table only public."reviews" add constraint "reviews_role_id_fkey" FOREIGN KEY (role_id) REFERENCES roles(id);
alter table only public."roles" add constraint "roles_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."succession_records" add constraint "succession_records_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."succession_records" add constraint "succession_records_current_role_id_fkey" FOREIGN KEY (current_role_id) REFERENCES roles(id);
alter table only public."succession_records" add constraint "succession_records_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES employees(id);
alter table only public."succession_records" add constraint "succession_records_target_role_id_fkey" FOREIGN KEY (target_role_id) REFERENCES roles(id);
alter table only public."user_location_access" add constraint "user_location_access_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
alter table only public."user_location_access" add constraint "user_location_access_granted_by_user_id_fkey" FOREIGN KEY (granted_by_user_id) REFERENCES auth.users(id);
alter table only public."user_location_access" add constraint "user_location_access_location_id_fkey" FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE;
alter table only public."user_location_access" add constraint "user_location_access_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Functions
CREATE OR REPLACE FUNCTION private.current_company_ids()
 RETURNS SETOF uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select company_id from public.company_memberships
  where user_id = (select auth.uid()) and active = true;
$function$;

CREATE OR REPLACE FUNCTION private.current_location_ids()
 RETURNS SETOF uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select ula.location_id
  from public.user_location_access ula
  where ula.user_id = (select auth.uid()) and ula.active = true
  union
  select cm.location_id
  from public.company_memberships cm
  where cm.user_id = (select auth.uid()) and cm.active = true and cm.location_id is not null;
$function$;

CREATE OR REPLACE FUNCTION private.has_company_role(p_company_id uuid, allowed membership_role[])
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists(
    select 1 from public.company_memberships
    where company_id = p_company_id
      and user_id = (select auth.uid())
      and active = true
      and role = any(allowed)
  );
$function$;

CREATE OR REPLACE FUNCTION private.is_company_leader(p_company_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select exists(select 1 from public.company_memberships m where m.company_id=p_company_id and m.user_id=auth.uid() and m.active and m.role in ('owner','admin','executive'));
$function$;

CREATE OR REPLACE FUNCTION private.refresh_finalized_review_intelligence(p_review_id uuid)
 RETURNS reviews
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_catalog'
AS $function$
declare
  v_review public.reviews;
  v_weighted_score numeric;
  v_simple_score numeric;
  v_score numeric;
  v_label text;
  v_readiness text;
  v_target_role uuid;
  v_has_active_goal boolean;
begin
  select * into v_review
  from public.reviews
  where id = p_review_id
  for update;

  if not found then
    raise exception 'Review not found';
  end if;

  -- Finalized answer rows are immutable. Calculate intelligence from the
  -- locked rating relationship below instead of rewriting answer snapshots.

  select
    sum(
      scale.score_value
      * coalesce(nullif(question.question_weight, 0), 1)
      * coalesce(nullif(question.section_weight, 0), 1)
    ) / nullif(sum(
      coalesce(nullif(question.question_weight, 0), 1)
      * coalesce(nullif(question.section_weight, 0), 1)
    ), 0),
    avg(scale.score_value)
  into v_weighted_score, v_simple_score
  from public.review_answers answer
  join public.rating_scale_items scale on scale.id = answer.rating_id
  join public.question_definitions question on question.id = answer.question_id
  where answer.review_id = p_review_id;

  v_score := coalesce(v_weighted_score, v_simple_score);

  select decision.promotion_readiness, decision.desired_role_id
  into v_readiness, v_target_role
  from public.career_decisions decision
  where decision.review_id = p_review_id;

  if v_score is not null then
    select scale.label
    into v_label
    from public.rating_scale_items scale
    where scale.config_version_id = v_review.config_version_id
    order by abs(scale.score_value - v_score), scale.score_value desc
    limit 1;
  end if;

  update public.reviews
  set overall_score = coalesce(round(v_score, 2), overall_score),
      overall_percent = coalesce(round((v_score / 5.0) * 100.0, 2), overall_percent),
      overall_rating_label = coalesce(v_label, overall_rating_label),
      promotion_readiness = coalesce(v_readiness, promotion_readiness),
      updated_at = now()
  where id = p_review_id
  returning * into v_review;

  if v_readiness is not null
     and not exists(
       select 1
       from public.reviews newer
       where newer.employee_id = v_review.employee_id
         and newer.status = 'finalized'
         and newer.id <> v_review.id
         and coalesce(newer.finalized_at, newer.created_at)
             > coalesce(v_review.finalized_at, v_review.created_at)
     ) then
    select exists(
      select 1
      from public.goals goal
      where goal.employee_id = v_review.employee_id
        and goal.status in ('not_started', 'in_progress')
    ) into v_has_active_goal;

    insert into public.succession_records(
      company_id,
      employee_id,
      current_role_id,
      target_role_id,
      readiness,
      active,
      active_development_goal,
      last_updated_at,
      source_version
    )
    values(
      v_review.company_id,
      v_review.employee_id,
      v_review.role_id,
      v_target_role,
      v_readiness,
      true,
      v_has_active_goal,
      now(),
      'CTOD-REVIEW-INTELLIGENCE-1.0'
    )
    on conflict(company_id, employee_id) where active = true
    do update set
      current_role_id = excluded.current_role_id,
      target_role_id = excluded.target_role_id,
      readiness = excluded.readiness,
      active_development_goal = excluded.active_development_goal,
      last_updated_at = excluded.last_updated_at,
      source_version = excluded.source_version;
  end if;

  return v_review;
end
$function$;

CREATE OR REPLACE FUNCTION public.accept_access_invite(p_token uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  v_user uuid := auth.uid();
  v_email text;
  v_inv public.access_invites;
  v_loc uuid;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  select lower(email) into v_email from auth.users where id=v_user;

  select * into v_inv
  from public.access_invites
  where token=p_token
    and accepted_at is null
    and revoked_at is null
    and expires_at > now()
  for update;
  if not found then raise exception 'Invite is invalid or expired'; end if;
  if v_email <> lower(v_inv.email) then raise exception 'Invite email does not match signed-in user'; end if;

  insert into public.profiles(id,display_name)
  values(v_user, coalesce((select raw_user_meta_data->>'full_name' from auth.users where id=v_user),split_part(v_email,'@',1)))
  on conflict (id) do nothing;

  insert into public.company_memberships(company_id,user_id,role,location_id,active)
  values(v_inv.company_id,v_user,v_inv.intended_role,null,true)
  on conflict (company_id,user_id) do update set role=excluded.role, active=true, location_id=null;

  for v_loc in select location_id from public.access_invite_locations where invite_id=v_inv.id loop
    insert into public.user_location_access(company_id,user_id,location_id,access_role,active,granted_by_user_id)
    values(v_inv.company_id,v_user,v_loc,v_inv.intended_role,true,v_inv.invited_by_user_id)
    on conflict (user_id,location_id) do update set access_role=excluded.access_role,active=true,revoked_at=null,granted_by_user_id=excluded.granted_by_user_id,granted_at=now();
  end loop;

  update public.access_invites set accepted_at=now() where id=v_inv.id;

  insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,after_json)
  values(v_inv.company_id,v_user,'access.invite_accepted','user',v_user,
         jsonb_build_object('role',v_inv.intended_role,'invite_id',v_inv.id));

  return jsonb_build_object('company_id',v_inv.company_id,'role',v_inv.intended_role,
    'locations',(select coalesce(jsonb_agg(location_id),'[]'::jsonb) from public.access_invite_locations where invite_id=v_inv.id));
end; $function$;

CREATE OR REPLACE FUNCTION public.accept_manager_invitation()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'auth'
AS $function$
declare v_user uuid:=auth.uid(); v_email text; v_invite public.manager_invitations; v_membership uuid;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  select lower(email) into v_email from auth.users where id=v_user;
  select * into v_invite from public.manager_invitations
   where lower(email)=v_email and status='pending' and expires_at>now()
   order by created_at desc limit 1 for update;
  if not found then raise exception 'No active manager invitation found for this account'; end if;
  insert into public.profiles(id,display_name)
  values(v_user,coalesce((select raw_user_meta_data->>'full_name' from auth.users where id=v_user),'CTOD Manager'))
  on conflict(id) do nothing;
  insert into public.company_memberships(company_id,user_id,role,location_id,active)
  values(v_invite.company_id,v_user,'manager',v_invite.location_id,true)
  on conflict(company_id,user_id) do update set role='manager',location_id=excluded.location_id,active=true
  returning id into v_membership;
  update public.manager_invitations set status='accepted',accepted_by_user_id=v_user,accepted_at=now() where id=v_invite.id;
  insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,after_json)
  values(v_invite.company_id,v_user,'manager.invitation_accepted','company_membership',v_membership,jsonb_build_object('location_id',v_invite.location_id,'role','manager'));
  return jsonb_build_object('company_id',v_invite.company_id,'location_id',v_invite.location_id,'role','manager');
end; $function$;

CREATE OR REPLACE FUNCTION public.admin_grant_location_access_by_email(p_location_id uuid, p_email text, p_access_role membership_role DEFAULT 'manager'::membership_role)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_catalog'
AS $function$
declare
  v_actor_user_id uuid := auth.uid();
  v_company_id uuid;
  v_user_id uuid;
  v_membership_role public.membership_role;
  v_membership_active boolean;
  v_derived_role public.membership_role;
begin
  select cm.company_id
    into v_company_id
  from public.company_memberships cm
  where cm.user_id = v_actor_user_id
    and cm.active = true
    and cm.role in ('owner','admin')
  order by case cm.role when 'owner' then 1 else 2 end
  limit 1;

  if v_company_id is null then
    raise exception 'Owner/Admin access required';
  end if;

  if p_access_role not in ('manager','market_leader','area_leader','viewer') then
    raise exception 'Unsupported location access role %', p_access_role;
  end if;

  if not exists (
    select 1
    from public.locations l
    where l.id = p_location_id
      and l.company_id = v_company_id
      and l.status = 'active'
  ) then
    raise exception 'Location is not active in this company';
  end if;

  select u.id
    into v_user_id
  from auth.users u
  where lower(u.email) = lower(trim(p_email))
  limit 1;

  if v_user_id is null then
    return jsonb_build_object('status','invite_required','email',lower(trim(p_email)));
  end if;

  select cm.role, cm.active
    into v_membership_role, v_membership_active
  from public.company_memberships cm
  where cm.company_id = v_company_id
    and cm.user_id = v_user_id;

  if not found or not coalesce(v_membership_active,false) then
    return jsonb_build_object(
      'status','invite_required',
      'email',lower(trim(p_email)),
      'existing_auth_user',true
    );
  end if;

  if v_membership_role in ('owner','admin','executive') then
    return jsonb_build_object(
      'status','already_company_wide',
      'email',lower(trim(p_email)),
      'user_id',v_user_id,
      'role',v_membership_role
    );
  end if;

  insert into public.user_location_access(
    company_id,
    user_id,
    location_id,
    access_role,
    active,
    granted_by_user_id,
    granted_at,
    revoked_at
  )
  values(
    v_company_id,
    v_user_id,
    p_location_id,
    p_access_role,
    true,
    v_actor_user_id,
    now(),
    null
  )
  on conflict (user_id,location_id) do update
    set access_role = excluded.access_role,
        active = true,
        granted_by_user_id = excluded.granted_by_user_id,
        granted_at = now(),
        revoked_at = null;

  select case
           when bool_or(ula.access_role = 'area_leader') then 'area_leader'::public.membership_role
           when bool_or(ula.access_role = 'market_leader') then 'market_leader'::public.membership_role
           when bool_or(ula.access_role = 'manager') then 'manager'::public.membership_role
           else 'viewer'::public.membership_role
         end
    into v_derived_role
  from public.user_location_access ula
  where ula.company_id = v_company_id
    and ula.user_id = v_user_id
    and ula.active = true;

  update public.company_memberships cm
     set active = true,
         role = coalesce(v_derived_role,p_access_role),
         location_id = null
   where cm.company_id = v_company_id
     and cm.user_id = v_user_id;

  insert into public.audit_events(
    company_id,
    actor_user_id,
    event_type,
    entity_type,
    entity_id,
    after_json
  )
  values(
    v_company_id,
    v_actor_user_id,
    'access.location_granted',
    'user',
    v_user_id,
    jsonb_build_object(
      'email',lower(trim(p_email)),
      'location_id',p_location_id,
      'access_role',p_access_role
    )
  );

  return jsonb_build_object(
    'status','granted',
    'email',lower(trim(p_email)),
    'user_id',v_user_id,
    'location_id',p_location_id,
    'access_role',p_access_role
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.admin_list_location_access()
 RETURNS TABLE(location_id uuid, user_id uuid, email text, access_role membership_role, membership_role membership_role, granted_at timestamp with time zone, access_source text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_catalog'
AS $function$
declare
  v_company_id uuid;
begin
  select cm.company_id
    into v_company_id
  from public.company_memberships cm
  where cm.user_id = auth.uid()
    and cm.active = true
    and cm.role in ('owner','admin','executive')
  order by case cm.role when 'owner' then 1 when 'admin' then 2 else 3 end
  limit 1;

  if v_company_id is null then
    raise exception 'Master access required';
  end if;

  return query
  with effective_access as (
    -- Owners, administrators, and executives can see every location through
    -- their company-wide role, even when they do not have a ULA row.
    select
      l.id as location_id,
      cm.user_id,
      u.email::text as email,
      cm.role as access_role,
      cm.role as membership_role,
      cm.created_at as granted_at,
      'company_wide'::text as access_source
    from public.locations l
    join public.company_memberships cm
      on cm.company_id = l.company_id
     and cm.active = true
     and cm.role in ('owner','admin','executive')
    join auth.users u on u.id = cm.user_id
    where l.company_id = v_company_id

    union all

    -- All other access is effective only when both the membership and the
    -- specific location grant are active.
    select
      ula.location_id,
      ula.user_id,
      u.email::text as email,
      ula.access_role,
      cm.role as membership_role,
      ula.granted_at,
      'location'::text as access_source
    from public.user_location_access ula
    join public.company_memberships cm
      on cm.company_id = ula.company_id
     and cm.user_id = ula.user_id
     and cm.active = true
     and cm.role not in ('owner','admin','executive')
    join auth.users u on u.id = ula.user_id
    where ula.company_id = v_company_id
      and ula.active = true
  )
  select
    ea.location_id,
    ea.user_id,
    ea.email,
    ea.access_role,
    ea.membership_role,
    ea.granted_at,
    ea.access_source
  from effective_access ea
  order by ea.location_id,
           case ea.access_source when 'company_wide' then 1 else 2 end,
           lower(ea.email);
end;
$function$;

CREATE OR REPLACE FUNCTION public.admin_set_location_access(p_location_id uuid, p_user_id uuid, p_active boolean, p_access_role membership_role DEFAULT 'manager'::membership_role)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_catalog'
AS $function$
declare
  v_actor_user_id uuid := auth.uid();
  v_company_id uuid;
  v_target_role public.membership_role;
  v_derived_role public.membership_role;
  v_remaining_count integer := 0;
  v_before jsonb;
begin
  select cm.company_id
    into v_company_id
  from public.company_memberships cm
  where cm.user_id = v_actor_user_id
    and cm.active = true
    and cm.role in ('owner','admin')
  order by case cm.role when 'owner' then 1 else 2 end
  limit 1;

  if v_company_id is null then
    raise exception 'Owner/Admin access required';
  end if;

  if p_access_role not in ('manager','market_leader','area_leader','viewer') then
    raise exception 'Unsupported location access role %', p_access_role;
  end if;

  if not exists (
    select 1
    from public.locations l
    where l.id = p_location_id
      and l.company_id = v_company_id
  ) then
    raise exception 'Location is not in this company';
  end if;

  select cm.role
    into v_target_role
  from public.company_memberships cm
  where cm.company_id = v_company_id
    and cm.user_id = p_user_id;

  if not found then
    raise exception 'User is not a company member';
  end if;

  if v_target_role in ('owner','admin','executive') then
    raise exception 'Company-wide access cannot be changed from a single location';
  end if;

  select to_jsonb(ula)
    into v_before
  from public.user_location_access ula
  where ula.company_id = v_company_id
    and ula.user_id = p_user_id
    and ula.location_id = p_location_id;

  if p_active then
    insert into public.user_location_access(
      company_id,
      user_id,
      location_id,
      access_role,
      active,
      granted_by_user_id,
      granted_at,
      revoked_at
    )
    values(
      v_company_id,
      p_user_id,
      p_location_id,
      p_access_role,
      true,
      v_actor_user_id,
      now(),
      null
    )
    on conflict (user_id,location_id) do update
      set access_role = excluded.access_role,
          active = true,
          granted_by_user_id = excluded.granted_by_user_id,
          granted_at = now(),
          revoked_at = null;
  else
    update public.user_location_access ula
       set active = false,
           revoked_at = now()
     where ula.company_id = v_company_id
       and ula.user_id = p_user_id
       and ula.location_id = p_location_id
       and ula.active = true;
  end if;

  select
    count(*)::integer,
    case
      when bool_or(ula.access_role = 'area_leader') then 'area_leader'::public.membership_role
      when bool_or(ula.access_role = 'market_leader') then 'market_leader'::public.membership_role
      when bool_or(ula.access_role = 'manager') then 'manager'::public.membership_role
      when count(*) > 0 then 'viewer'::public.membership_role
      else null::public.membership_role
    end
    into v_remaining_count, v_derived_role
  from public.user_location_access ula
  where ula.company_id = v_company_id
    and ula.user_id = p_user_id
    and ula.active = true;

  update public.company_memberships cm
     set active = (v_remaining_count > 0),
         role = coalesce(v_derived_role,cm.role),
         location_id = null
   where cm.company_id = v_company_id
     and cm.user_id = p_user_id;

  insert into public.audit_events(
    company_id,
    actor_user_id,
    event_type,
    entity_type,
    entity_id,
    before_json,
    after_json
  )
  values(
    v_company_id,
    v_actor_user_id,
    case when p_active then 'access.location_granted' else 'access.location_revoked' end,
    'user',
    p_user_id,
    v_before,
    jsonb_build_object(
      'location_id',p_location_id,
      'active',p_active,
      'access_role',p_access_role,
      'remaining_location_count',v_remaining_count,
      'membership_active',(v_remaining_count > 0)
    )
  );

  return jsonb_build_object(
    'status',case when p_active then 'granted' else 'revoked' end,
    'user_id',p_user_id,
    'location_id',p_location_id,
    'active',p_active,
    'remaining_location_count',v_remaining_count,
    'membership_active',(v_remaining_count > 0)
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.admin_set_location_active(p_location_id uuid, p_active boolean)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_catalog'
AS $function$ declare v_company uuid; begin select company_id into v_company from public.company_memberships where user_id=auth.uid() and active=true and role in ('owner','admin','executive') limit 1; if v_company is null then raise exception 'Admin access required'; end if; update public.locations set status=case when p_active then 'active' else 'inactive' end,updated_at=now() where id=p_location_id and company_id=v_company; return found; end $function$;

CREATE OR REPLACE FUNCTION public.admin_set_question_active(p_question_id uuid, p_active boolean)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_catalog'
AS $function$ declare v_company uuid; begin select company_id into v_company from public.company_memberships where user_id=auth.uid() and active=true and role in ('owner','admin','executive') limit 1; if v_company is null then raise exception 'Admin access required'; end if; update public.question_definitions set active=p_active where id=p_question_id and company_id=v_company; return found; end $function$;

CREATE OR REPLACE FUNCTION public.admin_set_role_active(p_role_id uuid, p_active boolean)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_catalog'
AS $function$ declare v_company uuid; begin select company_id into v_company from public.company_memberships where user_id=auth.uid() and active=true and role in ('owner','admin','executive') limit 1; if v_company is null then raise exception 'Admin access required'; end if; update public.roles set active=p_active,updated_at=now() where id=p_role_id and company_id=v_company; return found; end $function$;

CREATE OR REPLACE FUNCTION public.admin_upsert_location(p_location_id uuid DEFAULT NULL::uuid, p_location_code text DEFAULT NULL::text, p_name text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_state text DEFAULT NULL::text, p_postal text DEFAULT NULL::text, p_market text DEFAULT NULL::text, p_area text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_catalog'
AS $function$ declare v_company uuid; v_id uuid; begin select company_id into v_company from public.company_memberships where user_id=auth.uid() and active=true and role in ('owner','admin','executive') limit 1; if v_company is null then raise exception 'Admin access required'; end if; if p_location_id is null then insert into public.locations(company_id,location_code,name,status,address_line1,city,state_code,postal_code,market_name,area_name) values(v_company,lpad(trim(p_location_code),3,'0'),trim(p_name),'active',p_address,p_city,upper(p_state),p_postal,p_market,p_area) returning id into v_id; else update public.locations set location_code=lpad(trim(p_location_code),3,'0'),name=trim(p_name),address_line1=p_address,city=p_city,state_code=upper(p_state),postal_code=p_postal,market_name=p_market,area_name=p_area,updated_at=now() where id=p_location_id and company_id=v_company returning id into v_id; end if; return v_id; end $function$;

CREATE OR REPLACE FUNCTION public.admin_upsert_question(p_question_id uuid DEFAULT NULL::uuid, p_role_id uuid DEFAULT NULL::uuid, p_question_text text DEFAULT NULL::text, p_section_name text DEFAULT 'Performance'::text, p_category text DEFAULT 'Performance'::text, p_sort_order integer DEFAULT 10)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_catalog'
AS $function$ declare v_company uuid; v_config uuid; v_id uuid; begin select company_id into v_company from public.company_memberships where user_id=auth.uid() and active=true and role in ('owner','admin','executive') limit 1; if v_company is null then raise exception 'Admin access required'; end if; select id into v_config from public.configuration_versions where company_id=v_company order by case when status::text='published' then 0 else 1 end,created_at desc limit 1; if p_question_id is null then insert into public.question_definitions(company_id,config_version_id,role_id,question_code,section_code,section_name,question_text,category,active,sort_order,question_weight,section_weight,requires_rating,requires_reason,notes_required_for_exceptional,notes_required_for_unsatisfactory) values(v_company,v_config,p_role_id,'CUSTOM_'||substr(replace(gen_random_uuid()::text,'-',''),1,12),'CUSTOM',p_section_name,trim(p_question_text),p_category,true,p_sort_order,1,1,true,true,true,true) returning id into v_id; else update public.question_definitions set question_text=trim(p_question_text),section_name=p_section_name,category=p_category,sort_order=p_sort_order where id=p_question_id and company_id=v_company and role_id=p_role_id returning id into v_id; end if; return v_id; end $function$;

CREATE OR REPLACE FUNCTION public.admin_upsert_role(p_role_id uuid DEFAULT NULL::uuid, p_title text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_catalog'
AS $function$ declare v_company uuid; v_id uuid; begin select company_id into v_company from public.company_memberships where user_id=auth.uid() and active=true and role in ('owner','admin','executive') limit 1; if v_company is null then raise exception 'Admin access required'; end if; if p_role_id is null then insert into public.roles(company_id,title,active,sort_order) values(v_company,trim(p_title),true,coalesce((select max(sort_order)+1 from public.roles where company_id=v_company),1)) returning id into v_id; else update public.roles set title=trim(p_title),updated_at=now() where id=p_role_id and company_id=v_company returning id into v_id; end if; return v_id; end $function$;

CREATE OR REPLACE FUNCTION public.claim_initial_owner()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  v_user uuid := auth.uid();
  v_company uuid;
  v_existing integer;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  select count(*) into v_existing from public.company_memberships;
  if v_existing > 0 then raise exception 'Initial owner already assigned'; end if;
  select id into v_company from public.companies where slug='commercial-tire' limit 1;
  if v_company is null then raise exception 'Commercial Tire company missing'; end if;

  insert into public.profiles(id,display_name)
  values(v_user, coalesce((select raw_user_meta_data->>'full_name' from auth.users where id=v_user),'CTOD Owner'))
  on conflict (id) do nothing;

  insert into public.company_memberships(company_id,user_id,role,location_id,active)
  values(v_company,v_user,'owner',null,true);

  return jsonb_build_object('company_id',v_company,'location_id',null,'role','owner');
end;
$function$;

CREATE OR REPLACE FUNCTION public.complete_goal(p_goal_id uuid)
 RETURNS goals
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare g public.goals;
begin
  update public.goals set status='completed', completed_at=now(), updated_at=now()
  where id=p_goal_id returning * into g;
  if not found then raise exception 'Goal not found'; end if;
  update public.compensation_decisions
  set decision_status='due'
  where linked_goal_id=p_goal_id and decision_status in ('goal_pending','planned');
  return g;
end; $function$;

CREATE OR REPLACE FUNCTION public.create_access_invite(p_email text, p_role membership_role, p_location_ids uuid[] DEFAULT '{}'::uuid[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_catalog'
AS $function$
declare
  v_company uuid;
  v_invite uuid;
  v_token uuid;
  v_location_ids uuid[];
  v_loc uuid;
  v_reused boolean := false;
  v_normalized_email text := lower(trim(p_email));
begin
  if v_normalized_email is null
     or v_normalized_email = ''
     or position('@' in v_normalized_email) <= 1 then
    raise exception 'A valid email address is required';
  end if;

  select cm.company_id
    into v_company
  from public.company_memberships cm
  where cm.user_id = (select auth.uid())
    and cm.active = true
    and cm.role in ('owner','admin')
  order by case cm.role when 'owner' then 1 else 2 end
  limit 1;

  if v_company is null then
    raise exception 'Owner/Admin access required';
  end if;

  if p_role not in ('manager','market_leader','area_leader','executive','viewer') then
    raise exception 'Unsupported invited role %', p_role;
  end if;

  select coalesce(array_agg(distinct location_id order by location_id), '{}'::uuid[])
    into v_location_ids
  from unnest(coalesce(p_location_ids, '{}'::uuid[])) as requested(location_id)
  where location_id is not null;

  if p_role in ('manager','market_leader','area_leader')
     and coalesce(array_length(v_location_ids,1),0) = 0 then
    raise exception 'At least one location is required for this role';
  end if;

  foreach v_loc in array v_location_ids loop
    if not exists (
      select 1
      from public.locations l
      where l.id = v_loc
        and l.company_id = v_company
        and l.status = 'active'
    ) then
      raise exception 'Location % is not active in this company', v_loc;
    end if;
  end loop;

  -- Serialize create/resend decisions for the same company, recipient and role.
  perform pg_advisory_xact_lock(
    hashtextextended(v_company::text || '|' || v_normalized_email || '|' || p_role::text, 0)
  );

  update public.access_invites i
     set revoked_at = now()
   where i.company_id = v_company
     and lower(i.email) = v_normalized_email
     and i.intended_role = p_role
     and i.accepted_at is null
     and i.revoked_at is null
     and i.expires_at <= now();

  select i.id, i.token
    into v_invite, v_token
  from public.access_invites i
  where i.company_id = v_company
    and lower(i.email) = v_normalized_email
    and i.intended_role = p_role
    and i.accepted_at is null
    and i.revoked_at is null
    and i.expires_at > now()
    and coalesce((
      select array_agg(ail.location_id order by ail.location_id)
      from public.access_invite_locations ail
      where ail.invite_id = i.id
    ), '{}'::uuid[]) = v_location_ids
  order by i.created_at desc
  limit 1;

  if v_invite is not null then
    v_reused := true;

    update public.access_invites
       set expires_at = now() + interval '14 days',
           invited_by_user_id = (select auth.uid())
     where id = v_invite;

    -- Repair any historical duplicate with the exact same pending scope.
    update public.access_invites i
       set revoked_at = now()
     where i.id <> v_invite
       and i.company_id = v_company
       and lower(i.email) = v_normalized_email
       and i.intended_role = p_role
       and i.accepted_at is null
       and i.revoked_at is null
       and i.expires_at > now()
       and coalesce((
         select array_agg(ail.location_id order by ail.location_id)
         from public.access_invite_locations ail
         where ail.invite_id = i.id
       ), '{}'::uuid[]) = v_location_ids;

    insert into public.audit_events(
      company_id,
      actor_user_id,
      event_type,
      entity_type,
      entity_id,
      after_json
    )
    values(
      v_company,
      (select auth.uid()),
      'access.invite_reused',
      'access_invite',
      v_invite,
      jsonb_build_object(
        'email',v_normalized_email,
        'role',p_role,
        'locations',v_location_ids
      )
    );
  else
    insert into public.access_invites(
      company_id,
      email,
      intended_role,
      invited_by_user_id
    )
    values(
      v_company,
      v_normalized_email,
      p_role,
      (select auth.uid())
    )
    returning id, token into v_invite, v_token;

    insert into public.access_invite_locations(invite_id,location_id)
    select v_invite, unnest(v_location_ids);

    insert into public.audit_events(
      company_id,
      actor_user_id,
      event_type,
      entity_type,
      entity_id,
      after_json
    )
    values(
      v_company,
      (select auth.uid()),
      'access.invite_created',
      'access_invite',
      v_invite,
      jsonb_build_object(
        'email',v_normalized_email,
        'role',p_role,
        'locations',v_location_ids
      )
    );
  end if;

  return jsonb_build_object(
    'invite_id',v_invite,
    'token',v_token,
    'role',p_role,
    'location_count',coalesce(array_length(v_location_ids,1),0),
    'reused',v_reused
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.deactivate_location_manager(p_location_id uuid, p_user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'auth'
AS $function$
declare v_company uuid; v_changed integer;
begin
  select company_id into v_company from public.locations where id=p_location_id;
  if v_company is null then raise exception 'Location not found'; end if;
  if not private.has_company_role(v_company,array['owner','admin']::public.membership_role[]) then raise exception 'Owner or admin permission required'; end if;
  update public.company_memberships set active=false,location_id=null
   where company_id=v_company and user_id=p_user_id and location_id=p_location_id and role='manager' and active=true;
  get diagnostics v_changed=row_count;
  if v_changed>0 then
    insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,after_json)
    values(v_company,auth.uid(),'location.manager_deactivated','location',p_location_id,jsonb_build_object('user_id',p_user_id));
  end if;
  return v_changed>0;
end; $function$;

CREATE OR REPLACE FUNCTION public.ensure_review_summary(p_review_id uuid)
 RETURNS review_summaries
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare s public.review_summaries; declare r public.reviews;
begin
  select * into r from public.reviews where id=p_review_id;
  if not found then raise exception 'Review not found'; end if;
  if r.status <> 'finalized' then raise exception 'Review must be finalized before summary generation'; end if;
  insert into public.review_summaries(company_id,review_id,template_version)
  values(r.company_id,r.id,'CTOD-REVIEW-SUMMARY-2P-v1')
  on conflict(review_id) do update set generated_at=now(),template_version='CTOD-REVIEW-SUMMARY-2P-v1'
  returning * into s;
  return s;
end;$function$;

CREATE OR REPLACE FUNCTION public.get_review_coaching_items(p_review_id uuid)
 RETURNS TABLE(coaching_id uuid, occurred_at timestamp with time zone, coaching_type coaching_type, category text, notes text, expected_outcome text, resolved_streak integer, active_carry_forward boolean, current_disposition coaching_disposition, included_on_summary boolean, resolution_progress text)
 LANGUAGE sql
 SET search_path TO 'public'
AS $function$
  select cm.id,
         cm.occurred_at,
         cm.type,
         cm.category,
         cm.notes,
         cm.expected_outcome,
         cm.resolved_streak,
         cm.active_carry_forward,
         l.disposition,
         coalesce(l.included_on_summary,true),
         case
           when cm.type='recognition' and not cm.active_carry_forward then 'Reviewed'
           when not cm.active_carry_forward then 'Resolved 2 of 2'
           when cm.resolved_streak = 1 then 'Resolved 1 of 2'
           else 'Active'
         end
  from public.reviews r
  join public.coaching_moments cm
    on cm.employee_id = r.employee_id
   and cm.company_id = r.company_id
   and cm.record_status = 'active'
   and cm.include_in_review = true
   and (cm.active_carry_forward = true or exists (
       select 1 from public.coaching_review_links x
       where x.coaching_id=cm.id and x.review_id=r.id
   ))
  left join public.coaching_review_links l
    on l.coaching_id = cm.id and l.review_id = r.id
  where r.id = p_review_id
  order by cm.occurred_at, cm.id;
$function$;

CREATE OR REPLACE FUNCTION public.get_review_coaching_validation_issues(p_review_id uuid)
 RETURNS TABLE(coaching_id uuid, category text, issue text)
 LANGUAGE sql
 SET search_path TO 'public'
AS $function$
  select cm.id, cm.category, 'Select Carry Forward, Resolved, or Escalated'::text
  from public.reviews r
  join public.coaching_moments cm
    on cm.employee_id=r.employee_id
   and cm.company_id=r.company_id
   and cm.record_status='active'
   and cm.include_in_review=true
   and cm.active_carry_forward=true
  left join public.coaching_review_links l
    on l.review_id=r.id and l.coaching_id=cm.id
  where r.id=p_review_id
    and l.id is null
  order by cm.occurred_at, cm.id;
$function$;

CREATE OR REPLACE FUNCTION public.get_review_validation_issues(p_review_id uuid)
 RETURNS TABLE(question_id uuid, sort_order integer, section_name text, question_text text, issue_code text, issue_message text)
 LANGUAGE sql
 SET search_path TO 'public', 'pg_catalog'
AS $function$
  select q.id,q.sort_order,q.section_name,q.question_text,
         case
           when a.id is null then 'NOT_SAVED'
           when a.confirmed_current_cycle is not true then 'NOT_CONFIRMED'
           when q.requires_rating and a.rating_id is null then 'RATING_MISSING'
           when q.requires_reason and a.primary_reason_id is null then 'REASON_MISSING'
           when q.notes_required_for_exceptional and rs.code='EXCEPTIONAL' and nullif(trim(a.manager_note),'') is null then 'NOTE_REQUIRED'
           when q.notes_required_for_unsatisfactory and rs.code='UNSATISFACTORY' and nullif(trim(a.manager_note),'') is null then 'NOTE_REQUIRED'
         end as issue_code,
         case
           when a.id is null then 'Answer this question'
           when a.confirmed_current_cycle is not true then 'Confirm this answer for the current review cycle'
           when q.requires_rating and a.rating_id is null then 'Rating required'
           when q.requires_reason and a.primary_reason_id is null then 'Reason required'
           when q.notes_required_for_exceptional and rs.code='EXCEPTIONAL' and nullif(trim(a.manager_note),'') is null then 'Manager note required for Exceptional'
           when q.notes_required_for_unsatisfactory and rs.code='UNSATISFACTORY' and nullif(trim(a.manager_note),'') is null then 'Manager note required for Unsatisfactory'
         end as issue_message
  from public.reviews rv
  join public.question_definitions q on q.config_version_id=rv.config_version_id and q.active and (q.role_id is null or q.role_id=rv.role_id)
  left join public.review_answers a on a.review_id=rv.id and a.question_id=q.id
  left join public.rating_scale_items rs on rs.id=a.rating_id
  where rv.id=p_review_id
    and (
      a.id is null
      or a.confirmed_current_cycle is not true
      or (q.requires_rating and a.rating_id is null)
      or (q.requires_reason and a.primary_reason_id is null)
      or (q.notes_required_for_exceptional and rs.code='EXCEPTIONAL' and nullif(trim(a.manager_note),'') is null)
      or (q.notes_required_for_unsatisfactory and rs.code='UNSATISFACTORY' and nullif(trim(a.manager_note),'') is null)
    )
  order by q.section_name,q.sort_order,q.question_text;
$function$;

CREATE OR REPLACE FUNCTION public.import_org_reasons(p_items jsonb)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_count integer;
begin
  with c as (select id from public.companies where slug='commercial-tire'),
  v as (select id,company_id from public.configuration_versions where company_id=(select id from c) and version_label='CTOD-CLOUD-1.0.0'),
  x as (select * from jsonb_to_recordset(p_items) as t(category text,rating text,label text,sort_order int)),
  ins as (
    insert into public.reason_definitions(company_id,config_version_id,label,reason_type,rating_code,category,active,sort_order)
    select c.id,v.id,x.label,'review_org',
      case x.rating when 'Exceptional' then 'EXCEPTIONAL' when 'Exceeds Expectations' then 'EXCEEDS' when 'Meets Expectations' then 'MEETS' when 'Needs Improvement' then 'NEEDS_IMPROVEMENT' when 'Unsatisfactory' then 'UNSATISFACTORY' end,
      x.category,true,x.sort_order
    from c join v on true cross join x
    where not exists (
      select 1 from public.reason_definitions rd where rd.config_version_id=v.id and rd.reason_type='review_org' and rd.category=x.category and rd.rating_code=case x.rating when 'Exceptional' then 'EXCEPTIONAL' when 'Exceeds Expectations' then 'EXCEEDS' when 'Meets Expectations' then 'MEETS' when 'Needs Improvement' then 'NEEDS_IMPROVEMENT' when 'Unsatisfactory' then 'UNSATISFACTORY' end and rd.label=x.label)
    returning 1
  ) select count(*) into v_count from ins;
  return v_count;
end; $function$;

CREATE OR REPLACE FUNCTION public.invite_location_manager(p_location_id uuid, p_email text)
 RETURNS manager_invitations
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'auth'
AS $function$
declare v_company uuid; v_invite public.manager_invitations;
begin
  select company_id into v_company from public.locations where id=p_location_id;
  if v_company is null then raise exception 'Location not found'; end if;
  if not private.has_company_role(v_company, array['owner','admin']::public.membership_role[]) then raise exception 'Owner or admin permission required'; end if;
  update public.manager_invitations set status='revoked',revoked_at=now()
   where company_id=v_company and location_id=p_location_id and lower(email)=lower(trim(p_email)) and status='pending';
  insert into public.manager_invitations(company_id,location_id,email,role,invited_by_user_id)
  values(v_company,p_location_id,lower(trim(p_email)),'manager',auth.uid()) returning * into v_invite;
  insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,after_json)
  values(v_company,auth.uid(),'manager.invited','manager_invitation',v_invite.id,to_jsonb(v_invite));
  return v_invite;
end; $function$;

CREATE OR REPLACE FUNCTION public.list_access_invites()
 RETURNS TABLE(invite_id uuid, email text, intended_role membership_role, token uuid, expires_at timestamp with time zone, accepted_at timestamp with time zone, revoked_at timestamp with time zone, created_at timestamp with time zone, location_ids uuid[], location_labels text[])
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
  select i.id,
         i.email,
         i.intended_role,
         i.token,
         i.expires_at,
         i.accepted_at,
         i.revoked_at,
         i.created_at,
         coalesce(array_agg(l.id order by l.location_code) filter (where l.id is not null), '{}'::uuid[]),
         coalesce(array_agg(('Location '||l.location_code||' - '||l.name) order by l.location_code) filter (where l.id is not null), '{}'::text[])
  from public.access_invites i
  left join public.access_invite_locations ail on ail.invite_id=i.id
  left join public.locations l on l.id=ail.location_id
  where private.has_company_role(i.company_id, array['owner','admin']::public.membership_role[])
  group by i.id
  order by i.created_at desc;
$function$;

CREATE OR REPLACE FUNCTION public.protect_finalized_review_answers()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare s public.review_status;
begin
  select status into s from public.reviews where id = coalesce(new.review_id, old.review_id);
  if s = 'finalized' then raise exception 'Finalized review answers are immutable'; end if;
  return coalesce(new, old);
end; $function$;

CREATE OR REPLACE FUNCTION public.recalculate_coaching_lifecycle(p_coaching_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_streak integer;
declare v_type public.coaching_type;
declare v_include boolean;
declare v_reviewed_count integer;
begin
  select type, include_in_review into v_type, v_include
  from public.coaching_moments where id=p_coaching_id;

  if not coalesce(v_include,false) then
    update public.coaching_moments
    set resolved_streak=0, active_carry_forward=false, updated_at=now()
    where id=p_coaching_id;
    return;
  end if;

  if v_type='recognition' then
    select count(*) into v_reviewed_count
    from public.coaching_review_links l
    join public.reviews r on r.id=l.review_id
    where l.coaching_id=p_coaching_id and r.status='finalized';
    update public.coaching_moments
    set resolved_streak=0,
        active_carry_forward=(coalesce(v_reviewed_count,0)=0),
        updated_at=now()
    where id=p_coaching_id;
    return;
  end if;

  with x as (
    select l.disposition,
           row_number() over(order by r.finalized_at desc, r.id desc) rn
    from public.coaching_review_links l
    join public.reviews r on r.id = l.review_id
    where l.coaching_id = p_coaching_id and r.status = 'finalized'
  )
  select count(*) into v_streak
  from x
  where disposition = 'resolved'
    and not exists (select 1 from x p where p.rn < x.rn and p.disposition <> 'resolved');

  update public.coaching_moments
  set resolved_streak = coalesce(v_streak,0),
      active_carry_forward = (coalesce(v_streak,0) < 2),
      updated_at = now()
  where id = p_coaching_id;
end;
$function$;

CREATE OR REPLACE FUNCTION public.refresh_review_queue(p_company_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare n integer;
begin
  update public.reviews r set status='queued',updated_at=now()
  from public.review_campaigns c
  where r.campaign_id=c.id and r.company_id=p_company_id and r.status='not_due'
    and current_date >= coalesce(c.reminder_start_date,c.due_date);
  get diagnostics n = row_count;
  return n;
end; $function$;

CREATE OR REPLACE FUNCTION public.replace_location_manager(p_location_id uuid, p_new_user_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'auth'
AS $function$
declare v_company uuid; v_old_count integer;
begin
  select company_id into v_company from public.locations where id=p_location_id;
  if v_company is null then raise exception 'Location not found'; end if;
  if not private.has_company_role(v_company,array['owner','admin']::public.membership_role[]) then raise exception 'Owner or admin permission required'; end if;
  update public.company_memberships set active=false,location_id=null
   where company_id=v_company and location_id=p_location_id and role='manager' and user_id<>p_new_user_id and active=true;
  get diagnostics v_old_count=row_count;
  insert into public.company_memberships(company_id,user_id,role,location_id,active)
  values(v_company,p_new_user_id,'manager',p_location_id,true)
  on conflict(company_id,user_id) do update set role='manager',location_id=excluded.location_id,active=true;
  insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,after_json)
  values(v_company,auth.uid(),'location.manager_replaced','location',p_location_id,jsonb_build_object('new_user_id',p_new_user_id,'prior_managers_deactivated',v_old_count));
  return jsonb_build_object('location_id',p_location_id,'new_user_id',p_new_user_id,'prior_managers_deactivated',v_old_count);
end; $function$;

CREATE OR REPLACE FUNCTION public.revoke_access_invite(p_invite_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
declare v_company uuid;
begin
  select company_id into v_company from public.access_invites where id=p_invite_id;
  if v_company is null then raise exception 'Invite not found'; end if;
  if not private.has_company_role(v_company, array['owner','admin']::public.membership_role[]) then
    raise exception 'Owner/Admin access required';
  end if;
  update public.access_invites set revoked_at=now() where id=p_invite_id and accepted_at is null;
end;
$function$;

CREATE OR REPLACE FUNCTION public.set_coaching_review_link_company()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.company_id is null then
    select r.company_id into new.company_id from public.reviews r where r.id=new.review_id;
  end if;
  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.set_review_coaching_disposition(p_review_id uuid, p_coaching_id uuid, p_disposition coaching_disposition, p_included_on_summary boolean DEFAULT true)
 RETURNS coaching_review_links
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_catalog'
AS $function$
declare
  v_review public.reviews;
  v_coaching public.coaching_moments;
  v_link public.coaching_review_links;
begin
  select * into v_review from public.reviews where id=p_review_id;
  if not found then raise exception 'Review not found'; end if;
  if v_review.status='finalized' then raise exception 'Finalized review is immutable'; end if;

  select * into v_coaching from public.coaching_moments where id=p_coaching_id;
  if not found then raise exception 'Coaching moment not found'; end if;
  if v_coaching.company_id <> v_review.company_id or v_coaching.employee_id <> v_review.employee_id then
    raise exception 'Coaching moment does not belong to this review employee';
  end if;

  insert into public.coaching_review_links(company_id,coaching_id,review_id,disposition,included_on_summary)
  values(v_review.company_id,p_coaching_id,p_review_id,p_disposition,p_included_on_summary)
  on conflict (coaching_id,review_id)
  do update set disposition=excluded.disposition,
                included_on_summary=excluded.included_on_summary
  returning * into v_link;

  return v_link;
end;
$function$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$ begin new.updated_at = now(); return new; end; $function$;

CREATE OR REPLACE FUNCTION public.set_user_location_access(p_user_id uuid, p_location_ids uuid[], p_role membership_role)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
  v_company uuid;
  v_loc uuid;
begin
  select company_id into v_company
  from public.company_memberships
  where user_id=(select auth.uid()) and active=true and role in ('owner','admin')
  limit 1;
  if v_company is null then raise exception 'Owner/Admin access required'; end if;

  if not exists(select 1 from public.company_memberships where company_id=v_company and user_id=p_user_id and active=true) then
    raise exception 'User is not an active company member';
  end if;

  update public.user_location_access
  set active=false, revoked_at=now()
  where company_id=v_company and user_id=p_user_id and active=true;

  foreach v_loc in array coalesce(p_location_ids,'{}'::uuid[]) loop
    if not exists(select 1 from public.locations where id=v_loc and company_id=v_company and status='active') then
      raise exception 'Invalid location';
    end if;
    insert into public.user_location_access(company_id,user_id,location_id,access_role,active,granted_by_user_id,revoked_at)
    values(v_company,p_user_id,v_loc,p_role,true,(select auth.uid()),null)
    on conflict (user_id,location_id) do update
      set access_role=excluded.access_role,active=true,granted_by_user_id=excluded.granted_by_user_id,granted_at=now(),revoked_at=null;
  end loop;

  update public.company_memberships
  set role=p_role, location_id=null
  where company_id=v_company and user_id=p_user_id;

  insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,after_json)
  values(v_company,(select auth.uid()),'access.locations_updated','user',p_user_id,
    jsonb_build_object('role',p_role,'locations',p_location_ids));

  return jsonb_build_object('user_id',p_user_id,'role',p_role,'location_count',coalesce(array_length(p_location_ids,1),0));
end; $function$;

CREATE OR REPLACE FUNCTION public.validate_review_manager_employee()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_catalog'
AS $function$
begin
  if new.manager_employee_id is not null and not exists (
    select 1 from public.employees e where e.id = new.manager_employee_id
  ) then
    raise exception 'manager_employee_id % does not reference a valid employee', new.manager_employee_id;
  end if;
  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION private.can_access_location(p_company_id uuid, p_location_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select private.is_company_leader(p_company_id)
 or exists(select 1 from public.user_location_access ula where ula.company_id=p_company_id and ula.user_id=auth.uid() and ula.location_id=p_location_id and ula.active)
 or exists(select 1 from public.company_memberships m where m.company_id=p_company_id and m.user_id=auth.uid() and m.active and m.location_id=p_location_id);
$function$;

CREATE OR REPLACE FUNCTION public.coaching_link_recalc_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
begin
  perform public.recalculate_coaching_lifecycle(coalesce(new.coaching_id, old.coaching_id));
  return coalesce(new, old);
end; $function$;

CREATE OR REPLACE FUNCTION public.finalize_review(p_review_id uuid)
 RETURNS reviews
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
declare
  v_review public.reviews;
  v_missing integer;
  v_raise_missing integer;
  v_coaching_missing integer;
  v_direction text;
  v_next uuid;
  v_final uuid;
  v_next_date date;
  v_next_campaign uuid;
  v_next_config uuid;
  v_cycle text;
  v_due date;
begin
  select * into v_review
  from public.reviews
  where id = p_review_id
  for update;

  if not found then
    raise exception 'Review not found';
  end if;

  if auth.uid() is null
     or not private.can_access_location(v_review.company_id, v_review.location_id) then
    raise exception 'Access denied';
  end if;

  if v_review.status = 'finalized' then
    return private.refresh_finalized_review_intelligence(p_review_id);
  end if;

  if v_review.status not in ('in_progress', 'blocked', 'ready_to_finalize', 'reopened') then
    raise exception 'Review cannot be finalized from status %', v_review.status;
  end if;

  select count(*) into v_missing
  from public.get_review_validation_issues(p_review_id);

  if v_missing > 0 then
    update public.reviews set status = 'blocked' where id = p_review_id;
    raise exception 'Review has % incomplete or unconfirmed required answers', v_missing;
  end if;

  select count(*) into v_coaching_missing
  from public.get_review_coaching_validation_issues(p_review_id);

  if v_coaching_missing > 0 then
    update public.reviews set status = 'blocked' where id = p_review_id;
    raise exception 'Review has % active coaching moments that must be addressed', v_coaching_missing;
  end if;

  select career_direction, desired_role_id, final_desired_role_id
  into v_direction, v_next, v_final
  from public.career_decisions
  where review_id = p_review_id;

  if v_direction is null then
    raise exception 'Employee career direction must be selected before finalizing';
  end if;

  if v_direction = 'ADVANCEMENT' and (v_next is null or v_final is null) then
    raise exception 'Next job role and ultimate job role are required for advancement before finalizing';
  end if;

  select count(*) into v_raise_missing
  from public.compensation_decisions d
  where d.review_id = p_review_id
    and d.raise_requested = true
    and (
      nullif(trim(d.raise_reason_code), '') is null
      or nullif(trim(d.requested_timing), '') is null
      or nullif(trim(d.manager_timing), '') is null
    );

  if v_raise_missing > 0 then
    update public.reviews set status = 'blocked' where id = p_review_id;
    raise exception 'Raise request is incomplete';
  end if;

  update public.reviews
  set status = 'finalized',
      finalized_at = now(),
      review_date = coalesce(review_date, current_date),
      updated_at = now()
  where id = p_review_id
  returning * into v_review;

  v_review := private.refresh_finalized_review_intelligence(v_review.id);

  insert into public.review_summaries(company_id, review_id, template_version)
  values(v_review.company_id, v_review.id, 'CTOD-2PAGE-1.2')
  on conflict(review_id) do update
  set generated_at = now(),
      template_version = excluded.template_version;

  insert into public.audit_events(
    company_id,
    actor_user_id,
    event_type,
    entity_type,
    entity_id,
    after_json
  )
  values(
    v_review.company_id,
    auth.uid(),
    'review.finalized',
    'review',
    v_review.id,
    to_jsonb(v_review)
  );

  perform public.recalculate_coaching_lifecycle(l.coaching_id)
  from public.coaching_review_links l
  where l.review_id = p_review_id;

  if not exists(
    select 1
    from public.reviews x
    where x.employee_id = v_review.employee_id
      and x.status <> 'finalized'
  ) then
    v_next_date := coalesce(
      v_review.next_review_date,
      (v_review.review_date + interval '6 months')::date
    );
    v_cycle := extract(year from v_next_date)::int::text
      || case when extract(month from v_next_date)::int <= 6 then '-H1' else '-H2' end;
    v_due := case
      when extract(month from v_next_date)::int <= 6
        then make_date(extract(year from v_next_date)::int, 6, 30)
      else make_date(extract(year from v_next_date)::int, 12, 31)
    end;

    insert into public.review_campaigns(company_id, location_id, cycle_code, due_date, status)
    values(v_review.company_id, v_review.location_id, v_cycle, v_due, 'upcoming')
    on conflict(company_id, cycle_code, location_id) do update
    set due_date = excluded.due_date
    returning id into v_next_campaign;

    select id into v_next_config
    from public.configuration_versions
    where company_id = v_review.company_id
      and status::text = 'published'
    order by published_at desc nulls last, created_at desc
    limit 1;

    v_next_config := coalesce(v_next_config, v_review.config_version_id);

    insert into public.reviews(
      company_id,
      employee_id,
      campaign_id,
      location_id,
      role_id,
      config_version_id,
      status,
      review_date,
      scheduled_review_date,
      next_review_date,
      source_client
    )
    values(
      v_review.company_id,
      v_review.employee_id,
      v_next_campaign,
      v_review.location_id,
      v_review.role_id,
      v_next_config,
      'not_due',
      null,
      v_next_date,
      (v_next_date + interval '6 months')::date,
      'web'
    );

    insert into public.audit_events(
      company_id,
      actor_user_id,
      event_type,
      entity_type,
      entity_id,
      after_json
    )
    select
      v_review.company_id,
      auth.uid(),
      'review.next_cycle_created',
      'review',
      x.id,
      jsonb_build_object(
        'prior_review_id', v_review.id,
        'scheduled_review_date', v_next_date,
        'next_review_date', (v_next_date + interval '6 months')::date
      )
    from public.reviews x
    where x.employee_id = v_review.employee_id
      and x.campaign_id = v_next_campaign;
  end if;

  return v_review;
end
$function$;

CREATE OR REPLACE FUNCTION public.manager_add_employee(p_first_name text, p_last_name text, p_employee_code text, p_location_id uuid, p_role_id uuid, p_hire_date date DEFAULT NULL::date)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_catalog'
AS $function$
declare v_company uuid; v_emp uuid; v_code text; v_current public.employment_assignments; v_existing boolean:=false; v_campaign uuid; v_config uuid;
begin
 select company_id into v_company from public.locations where id=p_location_id and status='active';
 if v_company is null or not private.can_access_location(v_company,p_location_id) then raise exception 'Access denied'; end if;
 if not exists(select 1 from public.roles where id=p_role_id and company_id=v_company and active=true) then raise exception 'Invalid role'; end if;
 v_code:=trim(coalesce(p_employee_code,'')); if v_code !~ '^[0-9]{6}$' then raise exception 'Employee number must be exactly 6 digits'; end if;
 select id into v_emp from public.employees where company_id=v_company and employee_code=v_code limit 1; v_existing:=v_emp is not null;
 if v_emp is null then insert into public.employees(company_id,employee_code,first_name,last_name,hire_date,employment_status) values(v_company,v_code,trim(p_first_name),trim(p_last_name),p_hire_date,'active') returning id into v_emp;
 else update public.employees set first_name=coalesce(nullif(trim(p_first_name),''),first_name),last_name=coalesce(nullif(trim(p_last_name),''),last_name),hire_date=coalesce(p_hire_date,hire_date),employment_status='active',updated_at=now() where id=v_emp; end if;
 select * into v_current from public.employment_assignments where employee_id=v_emp and effective_to is null order by effective_from desc limit 1;
 if v_current.id is null then insert into public.employment_assignments(company_id,employee_id,location_id,role_id,effective_from) values(v_company,v_emp,p_location_id,p_role_id,coalesce(p_hire_date,current_date));
 elsif v_current.location_id is distinct from p_location_id or v_current.role_id is distinct from p_role_id then
  if v_current.effective_from=current_date then update public.employment_assignments set location_id=p_location_id,role_id=p_role_id where id=v_current.id;
  else update public.employment_assignments set effective_to=current_date-1 where id=v_current.id; insert into public.employment_assignments(company_id,employee_id,location_id,role_id,effective_from) values(v_company,v_emp,p_location_id,p_role_id,current_date); end if;
 end if;
 if v_existing then update public.reviews set location_id=p_location_id,role_id=p_role_id,updated_at=now() where employee_id=v_emp and status<>'finalized'; end if;
 if not exists(select 1 from public.reviews where employee_id=v_emp and status<>'finalized') then
   select id into v_campaign from public.review_campaigns where company_id=v_company and location_id=p_location_id and status::text in ('open','upcoming') order by due_date asc nulls last,created_at desc limit 1;
   if v_campaign is null then select id into v_campaign from public.review_campaigns where company_id=v_company and location_id=p_location_id order by created_at desc limit 1; end if;
   select id into v_config from public.configuration_versions where company_id=v_company and status::text='published' order by published_at desc nulls last,created_at desc limit 1;
   if v_campaign is null or v_config is null then raise exception 'Review campaign or published configuration is missing'; end if;
   insert into public.reviews(company_id,employee_id,campaign_id,location_id,role_id,config_version_id,status,review_date,scheduled_review_date,next_review_date,source_client)
   values(v_company,v_emp,v_campaign,p_location_id,p_role_id,v_config,'not_due',null,null,(current_date+interval '6 months')::date,'web');
 end if;
 insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,after_json) values(v_company,auth.uid(),case when v_existing then 'employee.roster_reactivated' else 'employee.roster_upsert' end,'employee',v_emp,jsonb_build_object('employee_number',v_code,'location_id',p_location_id,'role_id',p_role_id,'existing_employee',v_existing));
 return v_emp;
end $function$;

CREATE OR REPLACE FUNCTION public.manager_deactivate_employee(p_employee_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_catalog'
AS $function$
declare v_company uuid; v_location uuid;
begin
  select e.company_id,a.location_id into v_company,v_location
  from public.employees e join public.employment_assignments a on a.employee_id=e.id and a.effective_to is null
  where e.id=p_employee_id limit 1;
  if v_company is null or not private.can_access_location(v_company,v_location) then raise exception 'Access denied'; end if;
  update public.employees set employment_status='inactive',updated_at=now() where id=p_employee_id;
  update public.employment_assignments set effective_to=current_date where employee_id=p_employee_id and effective_to is null;
  insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,after_json)
  values(v_company,auth.uid(),'employee.deactivated','employee',p_employee_id,jsonb_build_object('location_id',v_location));
  return true;
end$function$;

CREATE OR REPLACE FUNCTION public.manager_edit_employee(p_employee_id uuid, p_first_name text, p_last_name text, p_hire_date date, p_location_id uuid, p_role_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_catalog'
AS $function$
declare
  v_company uuid;
  v_current public.employment_assignments;
  v_old jsonb;
begin
  select e.company_id into v_company from public.employees e where e.id=p_employee_id;
  if v_company is null then raise exception 'Employee not found'; end if;

  select * into v_current
  from public.employment_assignments
  where employee_id=p_employee_id and effective_to is null
  order by effective_from desc limit 1;

  if v_current.id is null or not private.can_access_location(v_company,v_current.location_id) then
    raise exception 'Access denied';
  end if;
  if not private.can_access_location(v_company,p_location_id) then raise exception 'Access denied'; end if;
  if not exists(select 1 from public.roles where id=p_role_id and company_id=v_company and active=true) then raise exception 'Invalid role'; end if;

  select jsonb_build_object('first_name',first_name,'last_name',last_name,'hire_date',hire_date,'location_id',v_current.location_id,'role_id',v_current.role_id)
    into v_old from public.employees where id=p_employee_id;

  update public.employees
    set first_name=trim(p_first_name), last_name=trim(p_last_name), hire_date=p_hire_date, updated_at=now()
  where id=p_employee_id;

  if v_current.location_id is distinct from p_location_id or v_current.role_id is distinct from p_role_id then
    if v_current.effective_from=current_date then
      update public.employment_assignments set location_id=p_location_id, role_id=p_role_id where id=v_current.id;
    else
      update public.employment_assignments set effective_to=current_date-1 where id=v_current.id;
      insert into public.employment_assignments(company_id,employee_id,location_id,role_id,effective_from)
      values(v_company,p_employee_id,p_location_id,p_role_id,current_date);
    end if;
    update public.reviews
      set location_id=p_location_id, role_id=p_role_id, updated_at=now()
    where employee_id=p_employee_id and status <> 'finalized';
  end if;

  insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,before_json,after_json)
  values(v_company,auth.uid(),'employee.info_updated','employee',p_employee_id,v_old,
    jsonb_build_object('first_name',trim(p_first_name),'last_name',trim(p_last_name),'hire_date',p_hire_date,'location_id',p_location_id,'role_id',p_role_id));
  return true;
end
$function$;

CREATE OR REPLACE FUNCTION public.manager_prepare_review(p_employee_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_catalog'
AS $function$
declare v_emp public.employees; v_assignment public.employment_assignments; v_review public.reviews; v_campaign uuid; v_config uuid;
begin
 select * into v_emp from public.employees where id=p_employee_id and employment_status='active'; if not found then raise exception 'Active employee not found'; end if;
 select * into v_assignment from public.employment_assignments where employee_id=p_employee_id and effective_to is null order by effective_from desc limit 1; if v_assignment.id is null then raise exception 'Employee has no active assignment'; end if;
 if not private.can_access_location(v_emp.company_id,v_assignment.location_id) then raise exception 'Access denied'; end if;
 select * into v_review from public.reviews where employee_id=p_employee_id and status<>'finalized' order by created_at desc limit 1;
 if v_review.id is not null then
   if v_review.location_id is distinct from v_assignment.location_id or v_review.role_id is distinct from v_assignment.role_id then update public.reviews set location_id=v_assignment.location_id,role_id=v_assignment.role_id,updated_at=now() where id=v_review.id returning * into v_review; end if;
   return v_review.id;
 end if;
 select id into v_campaign from public.review_campaigns where company_id=v_emp.company_id and location_id=v_assignment.location_id and status::text in ('open','upcoming') order by due_date asc nulls last,created_at desc limit 1;
 if v_campaign is null then select id into v_campaign from public.review_campaigns where company_id=v_emp.company_id and location_id=v_assignment.location_id order by created_at desc limit 1; end if;
 select id into v_config from public.configuration_versions where company_id=v_emp.company_id and status::text='published' order by published_at desc nulls last,created_at desc limit 1;
 if v_campaign is null or v_config is null then raise exception 'Review campaign or published configuration is missing'; end if;
 insert into public.reviews(company_id,employee_id,campaign_id,location_id,role_id,config_version_id,status,review_date,scheduled_review_date,next_review_date,source_client)
 values(v_emp.company_id,p_employee_id,v_campaign,v_assignment.location_id,v_assignment.role_id,v_config,'not_due',null,null,(current_date+interval '6 months')::date,'web') returning id into v_review.id;
 insert into public.audit_events(company_id,actor_user_id,event_type,entity_type,entity_id,after_json) values(v_emp.company_id,auth.uid(),'review.prepared','review',v_review.id,jsonb_build_object('employee_id',p_employee_id,'location_id',v_assignment.location_id,'role_id',v_assignment.role_id));
 return v_review.id;
end $function$;

CREATE OR REPLACE FUNCTION public.manager_set_review_schedule(p_review_id uuid, p_scheduled_date date, p_next_review_date date DEFAULT NULL::date)
 RETURNS reviews
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_catalog'
AS $function$
declare v public.reviews; v_next date;
begin
  select * into v from public.reviews where id=p_review_id for update;
  if not found then raise exception 'Review not found'; end if;
  if not private.can_access_location(v.company_id,v.location_id) then raise exception 'Access denied'; end if;
  if v.status='finalized' then raise exception 'Finalized review schedule cannot be changed'; end if;
  v_next:=coalesce(p_next_review_date,(p_scheduled_date + interval '6 months')::date);
  update public.reviews set scheduled_review_date=p_scheduled_date,next_review_date=v_next,updated_at=now() where id=p_review_id returning * into v;
  return v;
end$function$;

CREATE OR REPLACE FUNCTION public.manager_workspace_employees()
 RETURNS TABLE(employee_id uuid, employee_code text, first_name text, last_name text, hire_date date, employment_status text, location_id uuid, location_code text, location_name text, role_id uuid, role_title text, review_id uuid, review_status review_status, scheduled_review_date date, next_review_date date)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_catalog'
AS $function$
  select e.id,e.employee_code,e.first_name,e.last_name,e.hire_date,e.employment_status,
         a.location_id,l.location_code,l.name,a.role_id,r.title,
         rv.id,rv.status,coalesce(rv.scheduled_review_date, case when rv.status<>'finalized' then rv.next_review_date end),rv.next_review_date
  from public.employees e
  join public.employment_assignments a on a.employee_id=e.id and a.effective_to is null
  join public.locations l on l.id=a.location_id
  join public.roles r on r.id=a.role_id
  left join lateral (
    select x.* from public.reviews x where x.employee_id=e.id and x.location_id=a.location_id
    order by (x.status='finalized') asc, x.created_at desc limit 1
  ) rv on true
  where e.employment_status='active' and private.can_access_location(e.company_id,a.location_id)
  order by e.last_name,e.first_name;
$function$;

CREATE OR REPLACE FUNCTION public.my_ctod_context()
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
 select jsonb_build_object(
  'user_id',auth.uid(),
  'company_id',m.company_id,
  'company_name',c.name,
  'product_name',coalesce(c.branding->>'product_name','Commercial Team Organization Development'),
  'role',m.role,
  'is_master',m.role in ('owner','admin','executive'),
  'locations',coalesce((select jsonb_agg(jsonb_build_object('id',l.id,'code',l.location_code,'name',l.name) order by l.location_code)
    from public.locations l where l.company_id=m.company_id and (private.is_company_leader(m.company_id) or private.can_access_location(m.company_id,l.id))),'[]'::jsonb)
 )
 from public.company_memberships m join public.companies c on c.id=m.company_id
 where m.user_id=auth.uid() and m.active limit 1;
$function$;

CREATE OR REPLACE FUNCTION public.review_finalize_check(p_review_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
declare r public.reviews; missing_count int; unconfirmed_count int;
begin
 select * into r from public.reviews where id=p_review_id;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(r.company_id,r.location_id) then raise exception 'Access denied'; end if;
 select count(*) into missing_count from public.question_definitions q left join public.review_answers a on a.review_id=r.id and a.question_id=q.id
 where q.config_version_id=r.config_version_id and q.active and (q.role_id is null or q.role_id=r.role_id)
 and (a.id is null or (q.requires_rating and a.rating_id is null) or (q.requires_reason and a.primary_reason_id is null));
 select count(*) into unconfirmed_count from public.question_definitions q left join public.review_answers a on a.review_id=r.id and a.question_id=q.id
 where q.config_version_id=r.config_version_id and q.active and (q.role_id is null or q.role_id=r.role_id) and coalesce(a.confirmed_current_cycle,false)=false;
 return jsonb_build_object('ready',missing_count=0 and unconfirmed_count=0,'missing',missing_count,'unconfirmed',unconfirmed_count);
end $function$;

CREATE OR REPLACE FUNCTION public.review_print_summary(p_review_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
declare r public.reviews; j jsonb;
begin
 select * into r from public.reviews where id=p_review_id;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(r.company_id,r.location_id) then raise exception 'Access denied'; end if;
 select jsonb_build_object(
 'product_name',coalesce(c.branding->>'product_name','Commercial Team Organization Development'),'company_name',c.name,
 'employee',e.first_name||' '||e.last_name,'employee_code',e.employee_code,'role',ro.title,'location',l.name,'review_date',r.review_date,'next_review_date',r.next_review_date,'overall_rating',r.overall_rating_label,'overall_score',r.overall_score,'overall_percent',r.overall_percent,
 'manager_summary',s.manager_summary,'employee_comments',s.employee_comments,
 'strengths',coalesce((select jsonb_agg(jsonb_build_object('question',q.question_text,'rating',rs.label,'reason',rd.label,'note',a.manager_note)) from public.review_answers a join public.question_definitions q on q.id=a.question_id join public.rating_scale_items rs on rs.id=a.rating_id left join public.reason_definitions rd on rd.id=a.primary_reason_id where a.review_id=r.id and rs.score_value>=4),'[]'::jsonb),
 'development',coalesce((select jsonb_agg(jsonb_build_object('question',q.question_text,'rating',rs.label,'reason',rd.label,'note',a.manager_note)) from public.review_answers a join public.question_definitions q on q.id=a.question_id join public.rating_scale_items rs on rs.id=a.rating_id left join public.reason_definitions rd on rd.id=a.primary_reason_id where a.review_id=r.id and rs.score_value<=2),'[]'::jsonb),
 'goals',coalesce((select jsonb_agg(jsonb_build_object('text',g.goal_text,'target_date',g.target_date,'status',g.status)) from public.goals g where g.origin_review_id=r.id),'[]'::jsonb),
 'career',(select jsonb_build_object('promotion_interest',cd.promotion_interest,'desired_role',dr.title,'promotion_readiness',cd.promotion_readiness,'transfer_interest',cd.transfer_interest,'relocation_interest',cd.relocation_interest) from public.career_decisions cd left join public.roles dr on dr.id=cd.desired_role_id where cd.review_id=r.id limit 1),
 'compensation',(select jsonb_build_object('raise_requested',cc.raise_requested,'raise_basis',cc.raise_basis,'decision_status',cc.decision_status,'planned_effective_date',cc.planned_effective_date,'amount_type',cc.amount_type,'amount_value',cc.amount_value) from public.compensation_decisions cc where cc.review_id=r.id limit 1)
 ) into j
 from public.companies c,public.employees e,public.roles ro,public.locations l left join public.review_summaries s on s.review_id=r.id
 where c.id=r.company_id and e.id=r.employee_id and ro.id=r.role_id and l.id=r.location_id;
 return j;
end $function$;

CREATE OR REPLACE FUNCTION public.save_review_answer(p_review_id uuid, p_question_id uuid, p_rating_id uuid, p_primary_reason_id uuid, p_additional_reason_id uuid, p_manager_note text, p_confirmed boolean)
 RETURNS review_answers
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare r public.reviews; a public.review_answers; prior_id uuid;
begin
 select * into r from public.reviews where id=p_review_id for update;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(r.company_id,r.location_id) then raise exception 'Access denied'; end if;
 if r.status='finalized' then raise exception 'Finalized review is immutable'; end if;
 select ra.id into prior_id from public.review_answers ra join public.reviews pr on pr.id=ra.review_id
 where pr.employee_id=r.employee_id and pr.status='finalized' and ra.question_id=p_question_id and pr.id<>r.id
 order by pr.finalized_at desc nulls last,pr.review_date desc nulls last limit 1;
 insert into public.review_answers(company_id,review_id,question_id,rating_id,primary_reason_id,additional_reason_id,manager_note,prior_review_answer_id,confirmed_current_cycle,confirmed_at)
 values(r.company_id,r.id,p_question_id,p_rating_id,p_primary_reason_id,p_additional_reason_id,nullif(trim(p_manager_note),''),prior_id,coalesce(p_confirmed,false),case when p_confirmed then now() end)
 on conflict(review_id,question_id) do update set rating_id=excluded.rating_id,primary_reason_id=excluded.primary_reason_id,additional_reason_id=excluded.additional_reason_id,manager_note=excluded.manager_note,prior_review_answer_id=coalesce(public.review_answers.prior_review_answer_id,excluded.prior_review_answer_id),confirmed_current_cycle=excluded.confirmed_current_cycle,confirmed_at=case when excluded.confirmed_current_cycle then now() else null end,updated_at=now()
 returning * into a;
 update public.reviews set status='in_progress',started_at=coalesce(started_at,now()),updated_at=now() where id=r.id and status in ('not_due','queued','reopened');
 return a;
end $function$;

CREATE OR REPLACE FUNCTION public.save_review_career_path(p_review_id uuid, p_career_direction text, p_career_direction_reason text, p_desired_role_id uuid, p_final_desired_role_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_catalog'
AS $function$
declare v_company uuid; v_employee uuid; v_location uuid; v_direction text:=nullif(trim(coalesce(p_career_direction,'')),''); v_reason text:=nullif(trim(coalesce(p_career_direction_reason,'')),'');
begin
 select company_id,employee_id,location_id into v_company,v_employee,v_location from public.reviews where id=p_review_id;
 if v_company is null then raise exception 'Review not found'; end if;
 if not private.can_access_location(v_company,v_location) then raise exception 'Access denied'; end if;
 if v_direction is not null and v_direction not in ('ADVANCEMENT','CURRENT_ROLE','SPECIALIST','EXPLORING') then raise exception 'Invalid career direction'; end if;
 if v_direction in ('CURRENT_ROLE','SPECIALIST') and v_reason is null then raise exception 'A reason is required for this career direction'; end if;
 if v_direction in ('CURRENT_ROLE','SPECIALIST') then p_desired_role_id:=null; p_final_desired_role_id:=null; end if;
 if p_desired_role_id is not null and not exists(select 1 from public.roles where id=p_desired_role_id and company_id=v_company and active=true) then raise exception 'Invalid next role'; end if;
 if p_final_desired_role_id is not null and not exists(select 1 from public.roles where id=p_final_desired_role_id and company_id=v_company and active=true) then raise exception 'Invalid final role'; end if;
 insert into public.career_decisions(company_id,review_id,employee_id,career_direction,career_direction_reason,desired_role_id,final_desired_role_id)
 values(v_company,p_review_id,v_employee,v_direction,v_reason,p_desired_role_id,p_final_desired_role_id)
 on conflict(review_id,employee_id) do update set career_direction=excluded.career_direction,career_direction_reason=excluded.career_direction_reason,desired_role_id=excluded.desired_role_id,final_desired_role_id=excluded.final_desired_role_id;
 return true;
end $function$;

CREATE OR REPLACE FUNCTION public.save_review_career_roles(p_review_id uuid, p_desired_role_id uuid, p_final_desired_role_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_catalog'
AS $function$
declare v_company uuid; v_employee uuid; v_location uuid;
begin
  select company_id,employee_id,location_id into v_company,v_employee,v_location from public.reviews where id=p_review_id;
  if v_company is null then raise exception 'Review not found'; end if;
  if not private.can_access_location(v_company,v_location) then raise exception 'Access denied'; end if;
  if p_desired_role_id is not null and not exists(select 1 from public.roles where id=p_desired_role_id and company_id=v_company and active=true) then raise exception 'Invalid next role'; end if;
  if p_final_desired_role_id is not null and not exists(select 1 from public.roles where id=p_final_desired_role_id and company_id=v_company and active=true) then raise exception 'Invalid final role'; end if;
  insert into public.career_decisions(company_id,review_id,employee_id,desired_role_id,final_desired_role_id)
  values(v_company,p_review_id,v_employee,p_desired_role_id,p_final_desired_role_id)
  on conflict (review_id) do update set desired_role_id=excluded.desired_role_id,final_desired_role_id=excluded.final_desired_role_id;
  return true;
end$function$;

CREATE OR REPLACE FUNCTION public.save_review_development(p_review_id uuid, p_manager_summary text, p_employee_comments text, p_goal_text text, p_goal_target_date date, p_promotion_interest boolean, p_desired_role_id uuid, p_promotion_readiness text, p_raise_requested boolean, p_raise_basis text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
  r public.reviews;
  g_id uuid;
begin
  select * into r
  from public.reviews
  where id = p_review_id
  for update;

  if not found then
    raise exception 'Review not found';
  end if;

  if not private.can_access_location(r.company_id, r.location_id) then
    raise exception 'Access denied';
  end if;

  if r.status = 'finalized' then
    raise exception 'Finalized review is immutable';
  end if;

  insert into public.review_summaries(
    company_id,
    review_id,
    template_version,
    manager_summary,
    employee_comments
  )
  values(
    r.company_id,
    r.id,
    'CTOD-2PAGE-1.2',
    nullif(trim(p_manager_summary), ''),
    nullif(trim(p_employee_comments), '')
  )
  on conflict(review_id) do update
  set manager_summary = excluded.manager_summary,
      employee_comments = excluded.employee_comments,
      generated_at = now(),
      template_version = excluded.template_version;

  if nullif(trim(p_goal_text), '') is not null then
    select id into g_id
    from public.goals
    where origin_review_id = r.id
    order by created_at
    limit 1
    for update;

    if g_id is null then
      select id into g_id
      from public.goals
      where company_id = r.company_id
        and employee_id = r.employee_id
        and status in ('not_started', 'in_progress')
        and lower(trim(goal_text)) = lower(trim(p_goal_text))
      order by updated_at desc, created_at desc
      limit 1
      for update;
    end if;

    if g_id is null then
      insert into public.goals(
        company_id,
        employee_id,
        origin_review_id,
        goal_text,
        goal_type,
        status,
        target_date
      )
      values(
        r.company_id,
        r.employee_id,
        r.id,
        trim(p_goal_text),
        'development',
        'in_progress',
        p_goal_target_date
      )
      returning id into g_id;
    else
      update public.goals
      set goal_text = trim(p_goal_text),
          target_date = p_goal_target_date,
          status = 'in_progress',
          updated_at = now()
      where id = g_id;
    end if;
  end if;

  insert into public.career_decisions(
    company_id,
    review_id,
    employee_id,
    promotion_interest,
    desired_role_id,
    promotion_readiness
  )
  values(
    r.company_id,
    r.id,
    r.employee_id,
    coalesce(p_promotion_interest, false),
    p_desired_role_id,
    nullif(trim(p_promotion_readiness), '')
  )
  on conflict(review_id, employee_id) do update
  set promotion_interest = excluded.promotion_interest,
      desired_role_id = coalesce(excluded.desired_role_id, public.career_decisions.desired_role_id),
      promotion_readiness = excluded.promotion_readiness;

  insert into public.compensation_decisions(
    company_id,
    review_id,
    employee_id,
    raise_requested,
    raise_basis,
    decision_status
  )
  values(
    r.company_id,
    r.id,
    r.employee_id,
    coalesce(p_raise_requested, false),
    nullif(trim(p_raise_basis), ''),
    case when p_raise_requested then 'planned' else 'not_requested' end
  )
  on conflict(review_id, employee_id) do update
  set raise_requested = excluded.raise_requested,
      raise_basis = coalesce(excluded.raise_basis, public.compensation_decisions.raise_basis),
      decision_status = excluded.decision_status;

  return jsonb_build_object('ok', true, 'goal_id', g_id);
end
$function$;

CREATE OR REPLACE FUNCTION public.start_review(p_review_id uuid)
 RETURNS reviews
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare r public.reviews;
begin
 select * into r from public.reviews where id=p_review_id for update;
 if not found then raise exception 'Review not found'; end if;
 if not private.can_access_location(r.company_id,r.location_id) then raise exception 'Access denied'; end if;
 if r.status='not_due' then update public.reviews set status='in_progress',started_at=coalesce(started_at,now()),updated_at=now() where id=p_review_id returning * into r;
 elsif r.status in ('queued','reopened') then update public.reviews set status='in_progress',started_at=coalesce(started_at,now()),updated_at=now() where id=p_review_id returning * into r;
 end if;
 return r;
end $function$;

CREATE OR REPLACE FUNCTION private.can_access_employee(p_company_id uuid, p_employee_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select private.is_company_leader(p_company_id)
 or exists(
   select 1 from public.employment_assignments a
   where a.company_id=p_company_id and a.employee_id=p_employee_id and a.effective_to is null
     and private.can_access_location(p_company_id,a.location_id)
 );
$function$;

CREATE OR REPLACE FUNCTION public.get_review_form(p_review_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
declare r public.reviews; outj jsonb;
begin
 select * into r from reviews where id=p_review_id; if not found then raise exception 'Review not found'; end if; if not private.can_access_location(r.company_id,r.location_id) then raise exception 'Access denied'; end if;
 select jsonb_build_object(
 'review',jsonb_build_object('id',r.id,'status',r.status,'review_date',r.review_date,'next_review_date',r.next_review_date,'overall_rating_label',r.overall_rating_label,'overall_score',r.overall_score,'overall_percent',r.overall_percent),
 'employee',(select jsonb_build_object('id',e.id,'employee_code',e.employee_code,'name',e.first_name||' '||e.last_name,'role',ro.title,'location',l.name,'location_code',l.location_code) from employees e join roles ro on ro.id=r.role_id join locations l on l.id=r.location_id where e.id=r.employee_id),
 'ratings',(select coalesce(jsonb_agg(jsonb_build_object('id',x.id,'code',x.code,'label',x.label,'score',x.score_value) order by x.sort_order),'[]'::jsonb) from rating_scale_items x where x.config_version_id=r.config_version_id and x.employee_visible),
 'reasons',(select coalesce(jsonb_agg(jsonb_build_object('id',rd.id,'label',rd.label,'rating_code',rd.rating_code,'category',rd.category,'role_id',rd.role_id,'question_id',rd.question_id) order by rd.sort_order),'[]'::jsonb) from reason_definitions rd where rd.config_version_id=r.config_version_id and rd.active and rd.question_id in (select q.id from question_definitions q where q.config_version_id=r.config_version_id and q.active and (q.role_id is null or q.role_id=r.role_id)) and rd.reason_type in ('review_org','review_role')),
 'questions',(select coalesce(jsonb_agg(jsonb_build_object('id',q.id,'code',q.question_code,'section',q.section_name,'section_code',q.section_code,'text',q.question_text,'category',q.question_code,'display_category',q.category,'sort_order',q.sort_order,'requires_rating',q.requires_rating,'requires_reason',q.requires_reason,'answer',case when a.id is null then null else jsonb_build_object('id',a.id,'rating_id',a.rating_id,'primary_reason_id',a.primary_reason_id,'additional_reason_id',a.additional_reason_id,'manager_note',a.manager_note,'confirmed',a.confirmed_current_cycle) end) order by q.section_code,q.sort_order),'[]'::jsonb) from question_definitions q left join review_answers a on a.review_id=r.id and a.question_id=q.id where q.config_version_id=r.config_version_id and q.active and (q.role_id is null or q.role_id=r.role_id)),
 'goals',(select coalesce(jsonb_agg(jsonb_build_object('id',g.id,'goal_text',g.goal_text,'goal_type',g.goal_type,'status',g.status,'target_date',g.target_date,'raise_linked',g.raise_linked,'promotion_linked',g.promotion_linked) order by g.created_at),'[]'::jsonb) from goals g where g.employee_id=r.employee_id and g.status in ('not_started','in_progress') and private.can_access_employee(g.company_id,g.employee_id)),
 'career',(select jsonb_build_object('promotion_interest',cd.promotion_interest,'desired_role_id',cd.desired_role_id,'desired_role',dr.title,'final_desired_role_id',cd.final_desired_role_id,'final_desired_role',fr.title,'career_direction',cd.career_direction,'career_direction_reason',cd.career_direction_reason,'promotion_readiness',cd.promotion_readiness) from career_decisions cd left join roles dr on dr.id=cd.desired_role_id left join roles fr on fr.id=cd.final_desired_role_id where cd.review_id=r.id limit 1),
 'compensation',(select to_jsonb(cc) from compensation_decisions cc where cc.review_id=r.id limit 1),
 'summary',(select jsonb_build_object('employee_comments',s.employee_comments,'manager_summary',s.manager_summary) from review_summaries s where s.review_id=r.id)
 ) into outj; return outj;
end $function$;

-- Views
create view public."v_active_employee_assignments" with (security_invoker=true) as
 SELECT e.company_id,
    e.id AS employee_id,
    e.employee_code,
    e.first_name,
    e.last_name,
    e.employment_status,
    a.id AS assignment_id,
    a.location_id,
    l.location_code,
    l.name AS location_name,
    a.role_id,
    r.title AS role_title,
    a.manager_employee_id,
    a.current_pay,
    a.pay_type,
    a.effective_from
   FROM employees e
     JOIN employment_assignments a ON a.employee_id = e.id AND a.effective_to IS NULL
     JOIN locations l ON l.id = a.location_id
     JOIN roles r ON r.id = a.role_id;

create view public."v_company_dashboard" with (security_invoker=true) as
 SELECT id AS company_id,
    name AS company_name,
    ( SELECT count(*) AS count
           FROM locations l
          WHERE l.company_id = c.id AND l.status = 'active'::text) AS active_locations,
    ( SELECT count(*) AS count
           FROM employees e
          WHERE e.company_id = c.id AND e.employment_status = 'active'::text) AS active_employees,
    ( SELECT count(*) AS count
           FROM reviews r
          WHERE r.company_id = c.id AND (r.status = ANY (ARRAY['queued'::review_status, 'in_progress'::review_status, 'blocked'::review_status, 'ready_to_finalize'::review_status]))) AS open_reviews,
    ( SELECT count(*) AS count
           FROM coaching_moments m
          WHERE m.company_id = c.id AND m.active_carry_forward) AS active_coaching,
    ( SELECT count(*) AS count
           FROM goals g
          WHERE g.company_id = c.id AND (g.status = ANY (ARRAY['not_started'::goal_status, 'in_progress'::goal_status]))) AS active_goals,
    ( SELECT count(*) AS count
           FROM compensation_decisions d
          WHERE d.company_id = c.id AND d.decision_status = 'due'::text) AS raises_due
   FROM companies c;

create view public."v_employee_development" with (security_invoker=true) as
 SELECT e.company_id,
    e.id AS employee_id,
    e.employee_code,
    (e.first_name || ' '::text) || e.last_name AS employee_name,
    count(DISTINCT g.id) FILTER (WHERE g.status = ANY (ARRAY['not_started'::goal_status, 'in_progress'::goal_status])) AS active_goals,
    count(DISTINCT cm.id) FILTER (WHERE cm.active_carry_forward) AS active_coaching,
    max(rv.finalized_at) AS last_review_date,
    max(cd.promotion_readiness) AS promotion_readiness
   FROM employees e
     LEFT JOIN goals g ON g.employee_id = e.id
     LEFT JOIN coaching_moments cm ON cm.employee_id = e.id
     LEFT JOIN reviews rv ON rv.employee_id = e.id AND rv.status = 'finalized'::review_status
     LEFT JOIN career_decisions cd ON cd.employee_id = e.id
  GROUP BY e.company_id, e.id, e.employee_code, e.first_name, e.last_name;

create view public."v_manager_team" with (security_invoker=true) as
 SELECT e.company_id,
    e.id AS employee_id,
    e.employee_code,
    e.first_name,
    e.last_name,
    (e.first_name || ' '::text) || e.last_name AS employee_name,
    l.id AS location_id,
    l.location_code,
    l.name AS location_name,
    r.id AS role_id,
    r.title AS role_title,
    e.hire_date,
    e.employment_status,
    ( SELECT max(rv.review_date) AS max
           FROM reviews rv
          WHERE rv.employee_id = e.id AND rv.status = 'finalized'::review_status) AS last_review_date,
    ( SELECT rv.next_review_date
           FROM reviews rv
          WHERE rv.employee_id = e.id AND rv.status <> 'finalized'::review_status
          ORDER BY rv.next_review_date
         LIMIT 1) AS next_review_date,
    ( SELECT rv.status::text AS status
           FROM reviews rv
          WHERE rv.employee_id = e.id AND rv.status <> 'finalized'::review_status
          ORDER BY rv.next_review_date
         LIMIT 1) AS review_status,
    ( SELECT count(*) AS count
           FROM coaching_moments cm
          WHERE cm.employee_id = e.id AND cm.active_carry_forward) AS active_coaching,
    ( SELECT count(*) AS count
           FROM goals g
          WHERE g.employee_id = e.id AND (g.status = ANY (ARRAY['not_started'::goal_status, 'in_progress'::goal_status]))) AS active_goals,
    ( SELECT s.readiness
           FROM succession_records s
          WHERE s.employee_id = e.id AND s.active
          ORDER BY s.last_updated_at DESC
         LIMIT 1) AS succession_readiness,
    ( SELECT s.legacy_target_role_name
           FROM succession_records s
          WHERE s.employee_id = e.id AND s.active
          ORDER BY s.last_updated_at DESC
         LIMIT 1) AS target_role
   FROM employees e
     JOIN employment_assignments a ON a.employee_id = e.id AND a.effective_to IS NULL
     JOIN locations l ON l.id = a.location_id
     JOIN roles r ON r.id = a.role_id
  WHERE e.employment_status = 'active'::text;

create view public."v_master_kpis" with (security_invoker=true) as
 SELECT company_id,
    count(DISTINCT id) FILTER (WHERE employment_status = 'active'::text) AS active_employees,
    ( SELECT count(*) AS count
           FROM reviews r
          WHERE r.company_id = e.company_id AND r.status = 'finalized'::review_status) AS finalized_reviews,
    ( SELECT count(*) AS count
           FROM reviews r
          WHERE r.company_id = e.company_id AND (r.status = ANY (ARRAY['queued'::review_status, 'in_progress'::review_status, 'blocked'::review_status, 'ready_to_finalize'::review_status, 'reopened'::review_status]))) AS open_reviews,
    ( SELECT count(*) AS count
           FROM coaching_moments c
          WHERE c.company_id = e.company_id AND c.active_carry_forward) AS active_coaching,
    ( SELECT count(*) AS count
           FROM goals g
          WHERE g.company_id = e.company_id AND (g.status = ANY (ARRAY['not_started'::goal_status, 'in_progress'::goal_status]))) AS active_goals
   FROM employees e
  GROUP BY company_id;

create view public."v_master_review_history" with (security_invoker=true) as
 SELECT r.company_id,
    r.id AS review_id,
    r.employee_id,
    (e.first_name || ' '::text) || e.last_name AS employee_name,
    r.location_id,
    l.location_code,
    l.name AS location_name,
    ro.title AS "current_role",
    r.review_date,
    r.finalized_at,
    r.overall_score,
    r.overall_percent,
    r.overall_rating_label,
    COALESCE(r.promotion_readiness, cd.promotion_readiness) AS promotion_readiness,
        CASE
            WHEN COALESCE(cp.raise_requested, false) THEN COALESCE(r.raise_recommendation, 'Requested'::text)
            ELSE COALESCE(r.raise_recommendation, 'No raise requested'::text)
        END AS raise_recommendation,
    r.next_review_date
   FROM reviews r
     JOIN employees e ON e.id = r.employee_id
     LEFT JOIN locations l ON l.id = r.location_id
     LEFT JOIN roles ro ON ro.id = r.role_id
     LEFT JOIN career_decisions cd ON cd.review_id = r.id
     LEFT JOIN compensation_decisions cp ON cp.review_id = r.id
  WHERE r.status = 'finalized'::review_status;

create view public."v_my_location_access" with (security_invoker=true) as
 SELECT m.company_id,
    m.user_id,
    l.id AS location_id,
    l.location_code,
    l.name AS location_name,
    m.role AS access_role,
    true AS active
   FROM company_memberships m
     JOIN locations l ON l.company_id = m.company_id AND l.status = 'active'::text
  WHERE m.user_id = (( SELECT auth.uid() AS uid)) AND m.active = true AND (m.role = ANY (ARRAY['owner'::membership_role, 'admin'::membership_role, 'executive'::membership_role]))
UNION ALL
 SELECT ula.company_id,
    ula.user_id,
    ula.location_id,
    l.location_code,
    l.name AS location_name,
    ula.access_role,
    ula.active
   FROM user_location_access ula
     JOIN locations l ON l.id = ula.location_id
  WHERE ula.user_id = (( SELECT auth.uid() AS uid)) AND ula.active = true AND NOT (EXISTS ( SELECT 1
           FROM company_memberships m2
          WHERE m2.company_id = ula.company_id AND m2.user_id = ula.user_id AND m2.active = true AND (m2.role = ANY (ARRAY['owner'::membership_role, 'admin'::membership_role, 'executive'::membership_role]))));

create view public."v_promotion_pipeline" with (security_invoker=true) as
 WITH latest AS (
         SELECT DISTINCT ON (cd.employee_id) cd.employee_id,
            cd.review_id,
            cd.career_direction,
            cd.career_direction_reason,
            cd.desired_role_id,
            cd.final_desired_role_id,
            cd.promotion_readiness,
            r_1.finalized_at,
            r_1.location_id
           FROM career_decisions cd
             JOIN reviews r_1 ON r_1.id = cd.review_id AND r_1.status = 'finalized'::review_status
          ORDER BY cd.employee_id, r_1.finalized_at DESC NULLS LAST, cd.created_at DESC
        ), current_assignment AS (
         SELECT DISTINCT ON (ea.employee_id) ea.employee_id,
            ea.location_id,
            ea.role_id
           FROM employment_assignments ea
          WHERE ea.effective_to IS NULL
          ORDER BY ea.employee_id, ea.effective_from DESC
        )
 SELECT e.company_id,
    e.id AS employee_id,
    e.employee_code,
    e.first_name,
    e.last_name,
    ca.location_id,
    l.location_code,
    l.name AS location_name,
    ca.role_id AS current_role_id,
    cr.title AS "current_role",
    x.career_direction,
    x.career_direction_reason,
    x.desired_role_id,
    nr.title AS next_role,
    x.final_desired_role_id,
    fr.title AS final_desired_role,
    COALESCE(x.promotion_readiness, r.promotion_readiness, 'Not set'::text) AS readiness,
    x.review_id,
    x.finalized_at
   FROM latest x
     JOIN employees e ON e.id = x.employee_id
     LEFT JOIN current_assignment ca ON ca.employee_id = e.id
     LEFT JOIN locations l ON l.id = ca.location_id
     LEFT JOIN roles cr ON cr.id = ca.role_id
     LEFT JOIN roles nr ON nr.id = x.desired_role_id
     LEFT JOIN roles fr ON fr.id = x.final_desired_role_id
     LEFT JOIN reviews r ON r.id = x.review_id
  WHERE e.employment_status = 'active'::text;

create view public."v_promotion_readiness" with (security_invoker=true) as
 SELECT e.company_id,
    e.id AS employee_id,
    e.employee_code,
    (e.first_name || ' '::text) || e.last_name AS employee_name,
    a.location_id,
    l.location_code,
    l.name AS location_name,
    a.role_id,
    r.title AS current_job_title,
    sr.target_role_id,
    tr.title AS target_role,
    sr.readiness,
        CASE
            WHEN sr.readiness = 'Ready Now'::text THEN 'green'::text
            WHEN sr.readiness = 'Ready in 1 Year'::text THEN 'green'::text
            WHEN sr.readiness = 'Ready in 2-3 Years'::text THEN 'yellow'::text
            ELSE 'red'::text
        END AS readiness_light,
        CASE
            WHEN sr.readiness = 'Ready Now'::text THEN 100
            WHEN sr.readiness = 'Ready in 1 Year'::text THEN 75
            WHEN sr.readiness = 'Ready in 2-3 Years'::text THEN 50
            ELSE 20
        END AS readiness_score,
    sr.mobility,
    sr.manager_recommendation,
    sr.performance_trend,
    sr.last_updated_at,
    ( SELECT count(DISTINCT ROW(lower(TRIM(BOTH FROM g.goal_text)), g.target_date)) AS count
           FROM goals g
          WHERE g.employee_id = e.id AND (g.status = ANY (ARRAY['not_started'::goal_status, 'in_progress'::goal_status]))) AS active_goals,
    ( SELECT count(*) AS count
           FROM coaching_moments c
          WHERE c.employee_id = e.id AND c.active_carry_forward) AS active_coaching,
    ( SELECT max(rv.finalized_at) AS max
           FROM reviews rv
          WHERE rv.employee_id = e.id AND rv.status = 'finalized'::review_status) AS last_review_date
   FROM employees e
     JOIN employment_assignments a ON a.employee_id = e.id AND a.effective_to IS NULL
     JOIN locations l ON l.id = a.location_id
     JOIN roles r ON r.id = a.role_id
     LEFT JOIN succession_records sr ON sr.employee_id = e.id AND sr.active = true
     LEFT JOIN roles tr ON tr.id = sr.target_role_id
  WHERE e.employment_status = 'active'::text;

create view public."v_promotion_readiness_gauges" with (security_invoker=true) as
 SELECT company_id,
    count(*) FILTER (WHERE readiness = 'Ready Now'::text) AS ready_now,
    count(*) FILTER (WHERE readiness = 'Ready in 1 Year'::text) AS ready_1_year,
    count(*) FILTER (WHERE readiness = 'Ready in 2-3 Years'::text) AS ready_2_3_years,
    count(*) FILTER (WHERE readiness IS NULL OR readiness = 'Not Yet Ready'::text) AS not_yet_ready,
    count(*) FILTER (WHERE readiness_light = 'green'::text) AS green_count,
    count(*) FILTER (WHERE readiness_light = 'yellow'::text) AS yellow_count,
    count(*) FILTER (WHERE readiness_light = 'red'::text) AS red_count,
    count(*) AS total_employees,
    round(avg(readiness_score), 1) AS avg_readiness_score
   FROM v_promotion_readiness
  GROUP BY company_id;

create view public."v_review_queue" with (security_invoker=true) as
 SELECT rv.company_id,
    rv.id AS review_id,
    rv.employee_id,
    e.employee_code,
    (e.first_name || ' '::text) || e.last_name AS employee_name,
    rv.location_id,
    l.location_code,
    rv.role_id,
    ro.title AS role_title,
    rv.campaign_id,
    c.cycle_code,
    c.due_date,
    c.reminder_start_date,
    rv.status,
    rv.started_at,
    rv.finalized_at,
    rv.next_review_date
   FROM reviews rv
     JOIN employees e ON e.id = rv.employee_id
     JOIN locations l ON l.id = rv.location_id
     JOIN roles ro ON ro.id = rv.role_id
     JOIN review_campaigns c ON c.id = rv.campaign_id
  WHERE rv.status <> 'finalized'::review_status;

create view public."v_review_summary_data" with (security_invoker=true) as
 SELECT rv.company_id,
    rv.id AS review_id,
    rv.employee_id,
    e.employee_code,
    (e.first_name || ' '::text) || e.last_name AS employee_name,
    l.location_code,
    l.name AS location_name,
    ro.title AS role_title,
    rv.review_date,
    rv.finalized_at,
    rv.next_review_date,
    rv.overall_rating_label,
    rv.overall_score,
    rv.overall_percent,
    rv.raise_recommendation,
    rv.promotion_readiness,
    COALESCE(rv.legacy_manager_name, (me.first_name || ' '::text) || me.last_name) AS manager_name,
    ( SELECT string_agg((x.question_text || ': '::text) || x.rating_label, '
'::text ORDER BY x.score DESC, x.question_text) AS string_agg
           FROM ( SELECT q.question_text,
                    rs_1.label AS rating_label,
                    rs_1.score_value AS score
                   FROM review_answers a
                     JOIN question_definitions q ON q.id = a.question_id
                     LEFT JOIN rating_scale_items rs_1 ON rs_1.id = a.rating_id
                  WHERE a.review_id = rv.id AND rs_1.score_value IS NOT NULL
                  ORDER BY rs_1.score_value DESC
                 LIMIT 4) x) AS strengths,
    ( SELECT string_agg((x.question_text || ': '::text) || x.rating_label, '
'::text ORDER BY x.score, x.question_text) AS string_agg
           FROM ( SELECT q.question_text,
                    rs_1.label AS rating_label,
                    rs_1.score_value AS score
                   FROM review_answers a
                     JOIN question_definitions q ON q.id = a.question_id
                     LEFT JOIN rating_scale_items rs_1 ON rs_1.id = a.rating_id
                  WHERE a.review_id = rv.id AND rs_1.score_value IS NOT NULL
                  ORDER BY rs_1.score_value
                 LIMIT 4) x) AS development_areas,
    ( SELECT string_agg(COALESCE(NULLIF(TRIM(BOTH FROM a.manager_note), ''::text), rd.label), '
'::text ORDER BY q.sort_order) AS string_agg
           FROM review_answers a
             JOIN question_definitions q ON q.id = a.question_id
             LEFT JOIN reason_definitions rd ON rd.id = a.primary_reason_id
          WHERE a.review_id = rv.id AND (NULLIF(TRIM(BOTH FROM a.manager_note), ''::text) IS NOT NULL OR rd.label IS NOT NULL)) AS manager_notes,
    ( SELECT string_agg(g.goal_text || COALESCE((' (Target '::text || to_char(g.target_date::timestamp with time zone, 'Mon DD, YYYY'::text)) || ')'::text, ''::text), '
'::text ORDER BY g.target_date) AS string_agg
           FROM goals g
          WHERE g.origin_review_id = rv.id) AS goals,
    cd.promotion_interest,
    dr.title AS desired_role,
    cd.mobility_scope,
    cp.raise_requested,
    cp.decision_status AS raise_status,
    cp.raise_basis,
    rs.employee_comments,
    rs.manager_summary,
    rs.employee_acknowledged,
    rs.manager_acknowledged,
    rs.employee_signature_date,
    rs.manager_signature_date,
    rs.signed_copy_attachment_id
   FROM reviews rv
     JOIN employees e ON e.id = rv.employee_id
     JOIN locations l ON l.id = rv.location_id
     JOIN roles ro ON ro.id = rv.role_id
     LEFT JOIN employees me ON me.id = rv.manager_employee_id
     LEFT JOIN career_decisions cd ON cd.review_id = rv.id
     LEFT JOIN roles dr ON dr.id = cd.desired_role_id
     LEFT JOIN compensation_decisions cp ON cp.review_id = rv.id
     LEFT JOIN review_summaries rs ON rs.review_id = rv.id;

create view public."v_review_work_queue" with (security_invoker=true) as
 SELECT rv.company_id,
    rv.id AS review_id,
    rv.employee_id,
    e.employee_code,
    (e.first_name || ' '::text) || e.last_name AS employee_name,
    rv.location_id,
    l.location_code,
    l.name AS location_name,
    rv.role_id,
    ro.title AS role_title,
    rv.status,
    rv.review_date,
    rv.next_review_date,
    rv.overall_rating_label,
    rv.overall_score,
    rv.overall_percent,
    rv.finalized_at,
    c.cycle_code,
    c.due_date
   FROM reviews rv
     JOIN employees e ON e.id = rv.employee_id
     JOIN locations l ON l.id = rv.location_id
     JOIN roles ro ON ro.id = rv.role_id
     JOIN review_campaigns c ON c.id = rv.campaign_id
  WHERE private.can_access_location(rv.company_id, rv.location_id);

create view public."v_manager_dashboard" with (security_invoker=true) as
 SELECT company_id,
    location_id,
    location_code,
    location_name,
    count(*) AS team_members,
    count(*) FILTER (WHERE review_status = ANY (ARRAY['queued'::text, 'in_progress'::text, 'blocked'::text, 'ready_to_finalize'::text, 'reopened'::text])) AS reviews_actionable,
    count(*) FILTER (WHERE review_status = 'not_due'::text) AS reviews_upcoming,
    sum(active_coaching) AS active_coaching,
    sum(active_goals) AS active_goals,
    count(*) FILTER (WHERE succession_readiness = ANY (ARRAY['Ready Now'::text, 'Ready in 1 Year'::text])) AS near_term_successors
   FROM v_manager_team m
  GROUP BY company_id, location_id, location_code, location_name;

-- Additional indexes
CREATE INDEX idx_access_invites_email ON public.access_invites USING btree (lower(email));
CREATE INDEX idx_access_invites_pending_scope ON public.access_invites USING btree (company_id, lower(email), intended_role, created_at DESC) WHERE ((accepted_at IS NULL) AND (revoked_at IS NULL));
CREATE INDEX idx_audit_company_time ON public.audit_events USING btree (company_id, occurred_at DESC);
CREATE INDEX idx_coaching_employee_active ON public.coaching_moments USING btree (company_id, employee_id, active_carry_forward);
CREATE UNIQUE INDEX uq_coaching_company_external ON public.coaching_moments USING btree (company_id, external_coaching_id) WHERE (external_coaching_id IS NOT NULL);
CREATE INDEX idx_memberships_user_company ON public.company_memberships USING btree (user_id, company_id) WHERE active;
CREATE INDEX idx_config_options_company_type ON public.configuration_options USING btree (company_id, library_type, active, sort_order);
CREATE UNIQUE INDEX employees_company_employee_code_uidx ON public.employees USING btree (company_id, employee_code);
CREATE INDEX idx_employees_company ON public.employees USING btree (company_id);
CREATE INDEX idx_assignments_company_employee ON public.employment_assignments USING btree (company_id, employee_id);
CREATE UNIQUE INDEX one_current_assignment_per_employee ON public.employment_assignments USING btree (employee_id) WHERE (effective_to IS NULL);
CREATE INDEX idx_goals_employee_status ON public.goals USING btree (company_id, employee_id, status);
CREATE UNIQUE INDEX uq_goals_company_external ON public.goals USING btree (company_id, external_goal_id) WHERE (external_goal_id IS NOT NULL);
CREATE INDEX idx_locations_company ON public.locations USING btree (company_id);
CREATE UNIQUE INDEX manager_invitations_one_pending ON public.manager_invitations USING btree (company_id, location_id, lower(email)) WHERE (status = 'pending'::text);
CREATE INDEX reason_definitions_question_idx ON public.reason_definitions USING btree (question_id, rating_code, active);
CREATE UNIQUE INDEX uq_reason_config_external ON public.reason_definitions USING btree (config_version_id, external_code) WHERE (external_code IS NOT NULL);
CREATE INDEX idx_answers_review ON public.review_answers USING btree (review_id);
CREATE INDEX idx_reviews_company_employee_status ON public.reviews USING btree (company_id, employee_id, status);
CREATE UNIQUE INDEX uq_reviews_company_external ON public.reviews USING btree (company_id, external_review_id) WHERE (external_review_id IS NOT NULL);
CREATE UNIQUE INDEX uq_succession_company_external ON public.succession_records USING btree (company_id, external_succession_id) WHERE (external_succession_id IS NOT NULL);
CREATE UNIQUE INDEX uq_succession_records_active_employee ON public.succession_records USING btree (company_id, employee_id) WHERE (active = true);
CREATE INDEX idx_user_location_access_location ON public.user_location_access USING btree (location_id, active);
CREATE INDEX idx_user_location_access_user ON public.user_location_access USING btree (user_id, active);

-- Triggers
CREATE TRIGGER coaching_updated_at BEFORE UPDATE ON coaching_moments FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER coaching_link_recalc AFTER INSERT OR DELETE OR UPDATE ON coaching_review_links FOR EACH ROW EXECUTE FUNCTION coaching_link_recalc_trigger();
CREATE TRIGGER trg_set_coaching_review_link_company BEFORE INSERT OR UPDATE ON coaching_review_links FOR EACH ROW EXECUTE FUNCTION set_coaching_review_link_company();
CREATE TRIGGER companies_updated_at BEFORE UPDATE ON companies FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER employees_updated_at BEFORE UPDATE ON employees FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER goals_updated_at BEFORE UPDATE ON goals FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER locations_updated_at BEFORE UPDATE ON locations FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER protect_finalized_review_answers BEFORE DELETE OR UPDATE ON review_answers FOR EACH ROW EXECUTE FUNCTION protect_finalized_review_answers();
CREATE TRIGGER review_answers_updated_at BEFORE UPDATE ON review_answers FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER reviews_updated_at BEFORE UPDATE ON reviews FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_validate_review_manager_employee BEFORE INSERT OR UPDATE OF manager_employee_id ON reviews FOR EACH ROW EXECUTE FUNCTION validate_review_manager_employee();
CREATE TRIGGER roles_updated_at BEFORE UPDATE ON roles FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Row-level security
alter table public."access_invite_locations" enable row level security;
alter table public."access_invites" enable row level security;
alter table public."attachments" enable row level security;
alter table public."audit_events" enable row level security;
alter table public."career_decisions" enable row level security;
alter table public."coaching_moments" enable row level security;
alter table public."coaching_review_links" enable row level security;
alter table public."companies" enable row level security;
alter table public."company_memberships" enable row level security;
alter table public."compensation_decisions" enable row level security;
alter table public."configuration_options" enable row level security;
alter table public."configuration_versions" enable row level security;
alter table public."employees" enable row level security;
alter table public."employment_assignments" enable row level security;
alter table public."goal_templates" enable row level security;
alter table public."goals" enable row level security;
alter table public."import_batches" enable row level security;
alter table public."locations" enable row level security;
alter table public."manager_invitations" enable row level security;
alter table public."profiles" enable row level security;
alter table public."question_definitions" enable row level security;
alter table public."raise_reason_definitions" enable row level security;
alter table public."rating_scale_items" enable row level security;
alter table public."reason_definitions" enable row level security;
alter table public."review_answers" enable row level security;
alter table public."review_campaigns" enable row level security;
alter table public."review_summaries" enable row level security;
alter table public."reviews" enable row level security;
alter table public."roles" enable row level security;
alter table public."succession_records" enable row level security;
alter table public."user_location_access" enable row level security;

-- RLS policies
create policy "access_invite_locations_admin_all" on public."access_invite_locations" as permissive for all to "authenticated" using ((EXISTS ( SELECT 1
   FROM access_invites i
  WHERE i.id = access_invite_locations.invite_id AND private.has_company_role(i.company_id, ARRAY['owner'::membership_role, 'admin'::membership_role])))) with check ((EXISTS ( SELECT 1
   FROM access_invites i
  WHERE i.id = access_invite_locations.invite_id AND private.has_company_role(i.company_id, ARRAY['owner'::membership_role, 'admin'::membership_role]))));
create policy "access_invites_admin_all" on public."access_invites" as permissive for all to "authenticated" using (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role])) with check (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role]));
create policy "attachments_tenant_all" on public."attachments" as permissive for all to "authenticated" using ((company_id IN ( SELECT private.current_company_ids() AS current_company_ids))) with check ((company_id IN ( SELECT private.current_company_ids() AS current_company_ids)));
create policy "audit_leader_select" on public."audit_events" as permissive for select to "authenticated" using (private.is_company_leader(company_id));
create policy "audit_tenant_insert" on public."audit_events" as permissive for insert to "authenticated" with check ((company_id IN ( SELECT private.current_company_ids() AS current_company_ids)) AND (actor_user_id IS NULL OR actor_user_id = (( SELECT auth.uid() AS uid))));
create policy "career_scope_all" on public."career_decisions" as permissive for all to "authenticated" using (private.can_access_employee(company_id, employee_id)) with check (private.can_access_employee(company_id, employee_id));
create policy "coaching_scope_all" on public."coaching_moments" as permissive for all to "authenticated" using (private.can_access_employee(company_id, employee_id)) with check (private.can_access_employee(company_id, employee_id));
create policy "coaching_links_scope_all" on public."coaching_review_links" as permissive for all to "authenticated" using ((EXISTS ( SELECT 1
   FROM reviews r
  WHERE r.id = coaching_review_links.review_id AND private.can_access_location(r.company_id, r.location_id)))) with check ((EXISTS ( SELECT 1
   FROM reviews r
  WHERE r.id = coaching_review_links.review_id AND private.can_access_location(r.company_id, r.location_id))));
create policy "companies_member_select" on public."companies" as permissive for select to "authenticated" using ((id IN ( SELECT private.current_company_ids() AS current_company_ids)));
create policy "memberships_admin_write" on public."company_memberships" as permissive for all to "authenticated" using (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role])) with check (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role]));
create policy "memberships_member_select" on public."company_memberships" as permissive for select to "authenticated" using ((company_id IN ( SELECT private.current_company_ids() AS current_company_ids)));
create policy "compensation_scope_all" on public."compensation_decisions" as permissive for all to "authenticated" using (private.can_access_employee(company_id, employee_id)) with check (private.can_access_employee(company_id, employee_id));
create policy "config_options_admin_write" on public."configuration_options" as permissive for all to "authenticated" using (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role])) with check (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role]));
create policy "config_options_tenant_select" on public."configuration_options" as permissive for select to "authenticated" using ((company_id IN ( SELECT private.current_company_ids() AS current_company_ids)));
create policy "config_admin_write" on public."configuration_versions" as permissive for all to "authenticated" using (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role])) with check (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role]));
create policy "config_member_select" on public."configuration_versions" as permissive for select to "authenticated" using ((company_id IN ( SELECT private.current_company_ids() AS current_company_ids)));
create policy "employees_leader_write" on public."employees" as permissive for all to "authenticated" using (private.is_company_leader(company_id)) with check (private.is_company_leader(company_id));
create policy "employees_scope_select" on public."employees" as permissive for select to "authenticated" using (private.can_access_employee(company_id, id));
create policy "assignments_leader_write" on public."employment_assignments" as permissive for all to "authenticated" using (private.is_company_leader(company_id)) with check (private.is_company_leader(company_id));
create policy "assignments_scope_select" on public."employment_assignments" as permissive for select to "authenticated" using (private.can_access_employee(company_id, employee_id));
create policy "goal_templates_admin_write" on public."goal_templates" as permissive for all to "authenticated" using (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role])) with check (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role]));
create policy "goal_templates_member_select" on public."goal_templates" as permissive for select to "authenticated" using ((company_id IN ( SELECT private.current_company_ids() AS current_company_ids)));
create policy "goals_scope_all" on public."goals" as permissive for all to "authenticated" using (private.can_access_employee(company_id, employee_id)) with check (private.can_access_employee(company_id, employee_id));
create policy "imports_tenant_all" on public."import_batches" as permissive for all to "authenticated" using ((company_id IN ( SELECT private.current_company_ids() AS current_company_ids))) with check ((company_id IN ( SELECT private.current_company_ids() AS current_company_ids)));
create policy "locations_leader_write" on public."locations" as permissive for all to "authenticated" using (private.is_company_leader(company_id)) with check (private.is_company_leader(company_id));
create policy "locations_scope_select" on public."locations" as permissive for select to "authenticated" using (private.can_access_location(company_id, id));
create policy "manager_invitations_admin_insert" on public."manager_invitations" as permissive for insert to "authenticated" with check (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role]));
create policy "manager_invitations_admin_select" on public."manager_invitations" as permissive for select to "authenticated" using (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role]));
create policy "manager_invitations_admin_update" on public."manager_invitations" as permissive for update to "authenticated" using (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role])) with check (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role]));
create policy "profile_self_select" on public."profiles" as permissive for select to "authenticated" using (id = (( SELECT auth.uid() AS uid)));
create policy "profile_self_update" on public."profiles" as permissive for update to "authenticated" using (id = (( SELECT auth.uid() AS uid))) with check (id = (( SELECT auth.uid() AS uid)));
create policy "questions_admin_write" on public."question_definitions" as permissive for all to "authenticated" using (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role])) with check (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role]));
create policy "questions_member_select" on public."question_definitions" as permissive for select to "authenticated" using ((company_id IN ( SELECT private.current_company_ids() AS current_company_ids)));
create policy "raise_reasons_tenant_select" on public."raise_reason_definitions" as permissive for select to "authenticated" using ((company_id IN ( SELECT private.current_company_ids() AS current_company_ids)));
create policy "ratings_admin_write" on public."rating_scale_items" as permissive for all to "authenticated" using (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role])) with check (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role]));
create policy "ratings_member_select" on public."rating_scale_items" as permissive for select to "authenticated" using ((company_id IN ( SELECT private.current_company_ids() AS current_company_ids)));
create policy "reasons_admin_write" on public."reason_definitions" as permissive for all to "authenticated" using (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role])) with check (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role]));
create policy "reasons_member_select" on public."reason_definitions" as permissive for select to "authenticated" using ((company_id IN ( SELECT private.current_company_ids() AS current_company_ids)));
create policy "answers_scope_all" on public."review_answers" as permissive for all to "authenticated" using ((EXISTS ( SELECT 1
   FROM reviews r
  WHERE r.id = review_answers.review_id AND private.can_access_location(r.company_id, r.location_id)))) with check ((EXISTS ( SELECT 1
   FROM reviews r
  WHERE r.id = review_answers.review_id AND private.can_access_location(r.company_id, r.location_id))));
create policy "campaigns_leader_write" on public."review_campaigns" as permissive for all to "authenticated" using (private.is_company_leader(company_id)) with check (private.is_company_leader(company_id));
create policy "campaigns_scope_select" on public."review_campaigns" as permissive for select to "authenticated" using (private.can_access_location(company_id, COALESCE(location_id, location_id)) OR private.is_company_leader(company_id));
create policy "summaries_scope_all" on public."review_summaries" as permissive for all to "authenticated" using ((EXISTS ( SELECT 1
   FROM reviews r
  WHERE r.id = review_summaries.review_id AND private.can_access_location(r.company_id, r.location_id)))) with check ((EXISTS ( SELECT 1
   FROM reviews r
  WHERE r.id = review_summaries.review_id AND private.can_access_location(r.company_id, r.location_id))));
create policy "reviews_scope_all" on public."reviews" as permissive for all to "authenticated" using (private.can_access_location(company_id, location_id)) with check (private.can_access_location(company_id, location_id));
create policy "roles_admin_write" on public."roles" as permissive for all to "authenticated" using (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role])) with check (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role]));
create policy "roles_member_select" on public."roles" as permissive for select to "authenticated" using ((company_id IN ( SELECT private.current_company_ids() AS current_company_ids)));
create policy "succession_scope_all" on public."succession_records" as permissive for all to "authenticated" using (private.can_access_employee(company_id, employee_id)) with check (private.can_access_employee(company_id, employee_id));
create policy "user_location_access_manage" on public."user_location_access" as permissive for all to "authenticated" using (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role])) with check (private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role]));
create policy "user_location_access_select" on public."user_location_access" as permissive for select to "authenticated" using (user_id = (( SELECT auth.uid() AS uid)) OR private.has_company_role(company_id, ARRAY['owner'::membership_role, 'admin'::membership_role, 'executive'::membership_role, 'area_leader'::membership_role, 'market_leader'::membership_role]));

-- Exact Data API table/view privileges
revoke all on table public."access_invite_locations" from public, anon, authenticated, service_role;
revoke all on table public."access_invites" from public, anon, authenticated, service_role;
revoke all on table public."attachments" from public, anon, authenticated, service_role;
revoke all on table public."audit_events" from public, anon, authenticated, service_role;
revoke all on table public."career_decisions" from public, anon, authenticated, service_role;
revoke all on table public."coaching_moments" from public, anon, authenticated, service_role;
revoke all on table public."coaching_review_links" from public, anon, authenticated, service_role;
revoke all on table public."companies" from public, anon, authenticated, service_role;
revoke all on table public."company_memberships" from public, anon, authenticated, service_role;
revoke all on table public."compensation_decisions" from public, anon, authenticated, service_role;
revoke all on table public."configuration_options" from public, anon, authenticated, service_role;
revoke all on table public."configuration_versions" from public, anon, authenticated, service_role;
revoke all on table public."employees" from public, anon, authenticated, service_role;
revoke all on table public."employment_assignments" from public, anon, authenticated, service_role;
revoke all on table public."goal_templates" from public, anon, authenticated, service_role;
revoke all on table public."goals" from public, anon, authenticated, service_role;
revoke all on table public."import_batches" from public, anon, authenticated, service_role;
revoke all on table public."locations" from public, anon, authenticated, service_role;
revoke all on table public."manager_invitations" from public, anon, authenticated, service_role;
revoke all on table public."profiles" from public, anon, authenticated, service_role;
revoke all on table public."question_definitions" from public, anon, authenticated, service_role;
revoke all on table public."raise_reason_definitions" from public, anon, authenticated, service_role;
revoke all on table public."rating_scale_items" from public, anon, authenticated, service_role;
revoke all on table public."reason_definitions" from public, anon, authenticated, service_role;
revoke all on table public."review_answers" from public, anon, authenticated, service_role;
revoke all on table public."review_campaigns" from public, anon, authenticated, service_role;
revoke all on table public."review_summaries" from public, anon, authenticated, service_role;
revoke all on table public."reviews" from public, anon, authenticated, service_role;
revoke all on table public."roles" from public, anon, authenticated, service_role;
revoke all on table public."succession_records" from public, anon, authenticated, service_role;
revoke all on table public."user_location_access" from public, anon, authenticated, service_role;
revoke all on table public."v_active_employee_assignments" from public, anon, authenticated, service_role;
revoke all on table public."v_company_dashboard" from public, anon, authenticated, service_role;
revoke all on table public."v_employee_development" from public, anon, authenticated, service_role;
revoke all on table public."v_manager_dashboard" from public, anon, authenticated, service_role;
revoke all on table public."v_manager_team" from public, anon, authenticated, service_role;
revoke all on table public."v_master_kpis" from public, anon, authenticated, service_role;
revoke all on table public."v_master_review_history" from public, anon, authenticated, service_role;
revoke all on table public."v_my_location_access" from public, anon, authenticated, service_role;
revoke all on table public."v_promotion_pipeline" from public, anon, authenticated, service_role;
revoke all on table public."v_promotion_readiness" from public, anon, authenticated, service_role;
revoke all on table public."v_promotion_readiness_gauges" from public, anon, authenticated, service_role;
revoke all on table public."v_review_queue" from public, anon, authenticated, service_role;
revoke all on table public."v_review_summary_data" from public, anon, authenticated, service_role;
revoke all on table public."v_review_work_queue" from public, anon, authenticated, service_role;
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."access_invite_locations" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."access_invite_locations" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."access_invite_locations" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."access_invites" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."access_invites" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."access_invites" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."attachments" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."attachments" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."attachments" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."audit_events" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."audit_events" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."audit_events" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."career_decisions" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."career_decisions" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."career_decisions" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."coaching_moments" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."coaching_moments" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."coaching_moments" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."coaching_review_links" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."coaching_review_links" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."coaching_review_links" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."companies" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."companies" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."companies" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."company_memberships" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."company_memberships" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."company_memberships" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."compensation_decisions" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."compensation_decisions" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."compensation_decisions" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."configuration_options" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."configuration_options" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."configuration_options" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."configuration_versions" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."configuration_versions" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."configuration_versions" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."employees" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."employees" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."employees" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."employment_assignments" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."employment_assignments" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."employment_assignments" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."goal_templates" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."goal_templates" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."goal_templates" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."goals" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."goals" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."goals" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."import_batches" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."import_batches" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."import_batches" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."locations" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."locations" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."locations" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."manager_invitations" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."manager_invitations" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."manager_invitations" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."profiles" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."profiles" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."profiles" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."question_definitions" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."question_definitions" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."question_definitions" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."raise_reason_definitions" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."raise_reason_definitions" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."raise_reason_definitions" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."rating_scale_items" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."rating_scale_items" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."rating_scale_items" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."reason_definitions" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."reason_definitions" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."reason_definitions" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."review_answers" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."review_answers" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."review_answers" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."review_campaigns" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."review_campaigns" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."review_campaigns" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."review_summaries" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."review_summaries" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."review_summaries" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."reviews" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."reviews" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."reviews" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."roles" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."roles" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."roles" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."succession_records" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."succession_records" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."succession_records" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."user_location_access" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."user_location_access" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."user_location_access" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_active_employee_assignments" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_active_employee_assignments" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_active_employee_assignments" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_company_dashboard" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_company_dashboard" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_company_dashboard" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_employee_development" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_employee_development" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_employee_development" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_manager_dashboard" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_manager_dashboard" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_manager_dashboard" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_manager_team" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_manager_team" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_manager_team" to "service_role";
grant SELECT on table public."v_master_kpis" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_master_kpis" to "service_role";
grant SELECT on table public."v_master_review_history" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_master_review_history" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_my_location_access" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_my_location_access" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_my_location_access" to "service_role";
grant SELECT on table public."v_promotion_pipeline" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_promotion_pipeline" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_promotion_readiness" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_promotion_readiness" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_promotion_readiness" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_promotion_readiness_gauges" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_promotion_readiness_gauges" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_promotion_readiness_gauges" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_review_queue" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_review_queue" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_review_queue" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_review_summary_data" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_review_summary_data" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_review_summary_data" to "service_role";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_review_work_queue" to "anon";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_review_work_queue" to "authenticated";
grant DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public."v_review_work_queue" to "service_role";

-- Exact function execution privileges
revoke all on function "private"."can_access_employee"(p_company_id uuid, p_employee_id uuid) from public, anon, authenticated, service_role;
revoke all on function "private"."can_access_location"(p_company_id uuid, p_location_id uuid) from public, anon, authenticated, service_role;
revoke all on function "private"."current_company_ids"() from public, anon, authenticated, service_role;
revoke all on function "private"."current_location_ids"() from public, anon, authenticated, service_role;
revoke all on function "private"."has_company_role"(p_company_id uuid, allowed membership_role[]) from public, anon, authenticated, service_role;
revoke all on function "private"."is_company_leader"(p_company_id uuid) from public, anon, authenticated, service_role;
revoke all on function "private"."refresh_finalized_review_intelligence"(p_review_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."accept_access_invite"(p_token uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."accept_manager_invitation"() from public, anon, authenticated, service_role;
revoke all on function "public"."admin_grant_location_access_by_email"(p_location_id uuid, p_email text, p_access_role membership_role) from public, anon, authenticated, service_role;
revoke all on function "public"."admin_list_location_access"() from public, anon, authenticated, service_role;
revoke all on function "public"."admin_set_location_access"(p_location_id uuid, p_user_id uuid, p_active boolean, p_access_role membership_role) from public, anon, authenticated, service_role;
revoke all on function "public"."admin_set_location_active"(p_location_id uuid, p_active boolean) from public, anon, authenticated, service_role;
revoke all on function "public"."admin_set_question_active"(p_question_id uuid, p_active boolean) from public, anon, authenticated, service_role;
revoke all on function "public"."admin_set_role_active"(p_role_id uuid, p_active boolean) from public, anon, authenticated, service_role;
revoke all on function "public"."admin_upsert_location"(p_location_id uuid, p_location_code text, p_name text, p_address text, p_city text, p_state text, p_postal text, p_market text, p_area text) from public, anon, authenticated, service_role;
revoke all on function "public"."admin_upsert_question"(p_question_id uuid, p_role_id uuid, p_question_text text, p_section_name text, p_category text, p_sort_order integer) from public, anon, authenticated, service_role;
revoke all on function "public"."admin_upsert_role"(p_role_id uuid, p_title text) from public, anon, authenticated, service_role;
revoke all on function "public"."claim_initial_owner"() from public, anon, authenticated, service_role;
revoke all on function "public"."coaching_link_recalc_trigger"() from public, anon, authenticated, service_role;
revoke all on function "public"."complete_goal"(p_goal_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."create_access_invite"(p_email text, p_role membership_role, p_location_ids uuid[]) from public, anon, authenticated, service_role;
revoke all on function "public"."deactivate_location_manager"(p_location_id uuid, p_user_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."ensure_review_summary"(p_review_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."finalize_review"(p_review_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."get_review_coaching_items"(p_review_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."get_review_coaching_validation_issues"(p_review_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."get_review_form"(p_review_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."get_review_validation_issues"(p_review_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."import_org_reasons"(p_items jsonb) from public, anon, authenticated, service_role;
revoke all on function "public"."invite_location_manager"(p_location_id uuid, p_email text) from public, anon, authenticated, service_role;
revoke all on function "public"."list_access_invites"() from public, anon, authenticated, service_role;
revoke all on function "public"."manager_add_employee"(p_first_name text, p_last_name text, p_employee_code text, p_location_id uuid, p_role_id uuid, p_hire_date date) from public, anon, authenticated, service_role;
revoke all on function "public"."manager_deactivate_employee"(p_employee_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."manager_edit_employee"(p_employee_id uuid, p_first_name text, p_last_name text, p_hire_date date, p_location_id uuid, p_role_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."manager_prepare_review"(p_employee_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."manager_set_review_schedule"(p_review_id uuid, p_scheduled_date date, p_next_review_date date) from public, anon, authenticated, service_role;
revoke all on function "public"."manager_workspace_employees"() from public, anon, authenticated, service_role;
revoke all on function "public"."my_ctod_context"() from public, anon, authenticated, service_role;
revoke all on function "public"."protect_finalized_review_answers"() from public, anon, authenticated, service_role;
revoke all on function "public"."recalculate_coaching_lifecycle"(p_coaching_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."refresh_review_queue"(p_company_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."replace_location_manager"(p_location_id uuid, p_new_user_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."review_finalize_check"(p_review_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."review_print_summary"(p_review_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."revoke_access_invite"(p_invite_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."save_review_answer"(p_review_id uuid, p_question_id uuid, p_rating_id uuid, p_primary_reason_id uuid, p_additional_reason_id uuid, p_manager_note text, p_confirmed boolean) from public, anon, authenticated, service_role;
revoke all on function "public"."save_review_career_path"(p_review_id uuid, p_career_direction text, p_career_direction_reason text, p_desired_role_id uuid, p_final_desired_role_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."save_review_career_roles"(p_review_id uuid, p_desired_role_id uuid, p_final_desired_role_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."save_review_development"(p_review_id uuid, p_manager_summary text, p_employee_comments text, p_goal_text text, p_goal_target_date date, p_promotion_interest boolean, p_desired_role_id uuid, p_promotion_readiness text, p_raise_requested boolean, p_raise_basis text) from public, anon, authenticated, service_role;
revoke all on function "public"."set_coaching_review_link_company"() from public, anon, authenticated, service_role;
revoke all on function "public"."set_review_coaching_disposition"(p_review_id uuid, p_coaching_id uuid, p_disposition coaching_disposition, p_included_on_summary boolean) from public, anon, authenticated, service_role;
revoke all on function "public"."set_updated_at"() from public, anon, authenticated, service_role;
revoke all on function "public"."set_user_location_access"(p_user_id uuid, p_location_ids uuid[], p_role membership_role) from public, anon, authenticated, service_role;
revoke all on function "public"."start_review"(p_review_id uuid) from public, anon, authenticated, service_role;
revoke all on function "public"."validate_review_manager_employee"() from public, anon, authenticated, service_role;
grant EXECUTE on function "private"."can_access_employee"(p_company_id uuid, p_employee_id uuid) to PUBLIC;
grant EXECUTE on function "private"."can_access_location"(p_company_id uuid, p_location_id uuid) to PUBLIC;
grant EXECUTE on function "private"."current_company_ids"() to PUBLIC;
grant EXECUTE on function "private"."current_company_ids"() to "authenticated";
grant EXECUTE on function "private"."current_location_ids"() to PUBLIC;
grant EXECUTE on function "private"."has_company_role"(p_company_id uuid, allowed membership_role[]) to PUBLIC;
grant EXECUTE on function "private"."has_company_role"(p_company_id uuid, allowed membership_role[]) to "authenticated";
grant EXECUTE on function "private"."is_company_leader"(p_company_id uuid) to PUBLIC;
grant EXECUTE on function "private"."refresh_finalized_review_intelligence"(p_review_id uuid) to "service_role";
grant EXECUTE on function "public"."accept_access_invite"(p_token uuid) to "authenticated";
grant EXECUTE on function "public"."accept_access_invite"(p_token uuid) to "service_role";
grant EXECUTE on function "public"."accept_manager_invitation"() to "authenticated";
grant EXECUTE on function "public"."accept_manager_invitation"() to "service_role";
grant EXECUTE on function "public"."admin_grant_location_access_by_email"(p_location_id uuid, p_email text, p_access_role membership_role) to "authenticated";
grant EXECUTE on function "public"."admin_grant_location_access_by_email"(p_location_id uuid, p_email text, p_access_role membership_role) to "service_role";
grant EXECUTE on function "public"."admin_list_location_access"() to "authenticated";
grant EXECUTE on function "public"."admin_list_location_access"() to "service_role";
grant EXECUTE on function "public"."admin_set_location_access"(p_location_id uuid, p_user_id uuid, p_active boolean, p_access_role membership_role) to "authenticated";
grant EXECUTE on function "public"."admin_set_location_access"(p_location_id uuid, p_user_id uuid, p_active boolean, p_access_role membership_role) to "service_role";
grant EXECUTE on function "public"."admin_set_location_active"(p_location_id uuid, p_active boolean) to "authenticated";
grant EXECUTE on function "public"."admin_set_location_active"(p_location_id uuid, p_active boolean) to "service_role";
grant EXECUTE on function "public"."admin_set_question_active"(p_question_id uuid, p_active boolean) to "authenticated";
grant EXECUTE on function "public"."admin_set_question_active"(p_question_id uuid, p_active boolean) to "service_role";
grant EXECUTE on function "public"."admin_set_role_active"(p_role_id uuid, p_active boolean) to "authenticated";
grant EXECUTE on function "public"."admin_set_role_active"(p_role_id uuid, p_active boolean) to "service_role";
grant EXECUTE on function "public"."admin_upsert_location"(p_location_id uuid, p_location_code text, p_name text, p_address text, p_city text, p_state text, p_postal text, p_market text, p_area text) to "authenticated";
grant EXECUTE on function "public"."admin_upsert_location"(p_location_id uuid, p_location_code text, p_name text, p_address text, p_city text, p_state text, p_postal text, p_market text, p_area text) to "service_role";
grant EXECUTE on function "public"."admin_upsert_question"(p_question_id uuid, p_role_id uuid, p_question_text text, p_section_name text, p_category text, p_sort_order integer) to "authenticated";
grant EXECUTE on function "public"."admin_upsert_question"(p_question_id uuid, p_role_id uuid, p_question_text text, p_section_name text, p_category text, p_sort_order integer) to "service_role";
grant EXECUTE on function "public"."admin_upsert_role"(p_role_id uuid, p_title text) to "authenticated";
grant EXECUTE on function "public"."admin_upsert_role"(p_role_id uuid, p_title text) to "service_role";
grant EXECUTE on function "public"."claim_initial_owner"() to "authenticated";
grant EXECUTE on function "public"."claim_initial_owner"() to "service_role";
grant EXECUTE on function "public"."coaching_link_recalc_trigger"() to PUBLIC;
grant EXECUTE on function "public"."coaching_link_recalc_trigger"() to "anon";
grant EXECUTE on function "public"."coaching_link_recalc_trigger"() to "authenticated";
grant EXECUTE on function "public"."coaching_link_recalc_trigger"() to "service_role";
grant EXECUTE on function "public"."complete_goal"(p_goal_id uuid) to PUBLIC;
grant EXECUTE on function "public"."complete_goal"(p_goal_id uuid) to "anon";
grant EXECUTE on function "public"."complete_goal"(p_goal_id uuid) to "authenticated";
grant EXECUTE on function "public"."complete_goal"(p_goal_id uuid) to "service_role";
grant EXECUTE on function "public"."create_access_invite"(p_email text, p_role membership_role, p_location_ids uuid[]) to "authenticated";
grant EXECUTE on function "public"."create_access_invite"(p_email text, p_role membership_role, p_location_ids uuid[]) to "service_role";
grant EXECUTE on function "public"."deactivate_location_manager"(p_location_id uuid, p_user_id uuid) to "authenticated";
grant EXECUTE on function "public"."deactivate_location_manager"(p_location_id uuid, p_user_id uuid) to "service_role";
grant EXECUTE on function "public"."ensure_review_summary"(p_review_id uuid) to PUBLIC;
grant EXECUTE on function "public"."ensure_review_summary"(p_review_id uuid) to "anon";
grant EXECUTE on function "public"."ensure_review_summary"(p_review_id uuid) to "authenticated";
grant EXECUTE on function "public"."ensure_review_summary"(p_review_id uuid) to "service_role";
grant EXECUTE on function "public"."finalize_review"(p_review_id uuid) to "authenticated";
grant EXECUTE on function "public"."finalize_review"(p_review_id uuid) to "service_role";
grant EXECUTE on function "public"."get_review_coaching_items"(p_review_id uuid) to PUBLIC;
grant EXECUTE on function "public"."get_review_coaching_items"(p_review_id uuid) to "anon";
grant EXECUTE on function "public"."get_review_coaching_items"(p_review_id uuid) to "authenticated";
grant EXECUTE on function "public"."get_review_coaching_items"(p_review_id uuid) to "service_role";
grant EXECUTE on function "public"."get_review_coaching_validation_issues"(p_review_id uuid) to PUBLIC;
grant EXECUTE on function "public"."get_review_coaching_validation_issues"(p_review_id uuid) to "anon";
grant EXECUTE on function "public"."get_review_coaching_validation_issues"(p_review_id uuid) to "authenticated";
grant EXECUTE on function "public"."get_review_coaching_validation_issues"(p_review_id uuid) to "service_role";
grant EXECUTE on function "public"."get_review_form"(p_review_id uuid) to PUBLIC;
grant EXECUTE on function "public"."get_review_form"(p_review_id uuid) to "anon";
grant EXECUTE on function "public"."get_review_form"(p_review_id uuid) to "authenticated";
grant EXECUTE on function "public"."get_review_form"(p_review_id uuid) to "service_role";
grant EXECUTE on function "public"."get_review_validation_issues"(p_review_id uuid) to PUBLIC;
grant EXECUTE on function "public"."get_review_validation_issues"(p_review_id uuid) to "anon";
grant EXECUTE on function "public"."get_review_validation_issues"(p_review_id uuid) to "authenticated";
grant EXECUTE on function "public"."get_review_validation_issues"(p_review_id uuid) to "service_role";
grant EXECUTE on function "public"."import_org_reasons"(p_items jsonb) to "service_role";
grant EXECUTE on function "public"."invite_location_manager"(p_location_id uuid, p_email text) to "authenticated";
grant EXECUTE on function "public"."invite_location_manager"(p_location_id uuid, p_email text) to "service_role";
grant EXECUTE on function "public"."list_access_invites"() to "authenticated";
grant EXECUTE on function "public"."list_access_invites"() to "service_role";
grant EXECUTE on function "public"."manager_add_employee"(p_first_name text, p_last_name text, p_employee_code text, p_location_id uuid, p_role_id uuid, p_hire_date date) to "authenticated";
grant EXECUTE on function "public"."manager_add_employee"(p_first_name text, p_last_name text, p_employee_code text, p_location_id uuid, p_role_id uuid, p_hire_date date) to "service_role";
grant EXECUTE on function "public"."manager_deactivate_employee"(p_employee_id uuid) to "authenticated";
grant EXECUTE on function "public"."manager_deactivate_employee"(p_employee_id uuid) to "service_role";
grant EXECUTE on function "public"."manager_edit_employee"(p_employee_id uuid, p_first_name text, p_last_name text, p_hire_date date, p_location_id uuid, p_role_id uuid) to "authenticated";
grant EXECUTE on function "public"."manager_edit_employee"(p_employee_id uuid, p_first_name text, p_last_name text, p_hire_date date, p_location_id uuid, p_role_id uuid) to "service_role";
grant EXECUTE on function "public"."manager_prepare_review"(p_employee_id uuid) to "authenticated";
grant EXECUTE on function "public"."manager_prepare_review"(p_employee_id uuid) to "service_role";
grant EXECUTE on function "public"."manager_set_review_schedule"(p_review_id uuid, p_scheduled_date date, p_next_review_date date) to "authenticated";
grant EXECUTE on function "public"."manager_set_review_schedule"(p_review_id uuid, p_scheduled_date date, p_next_review_date date) to "service_role";
grant EXECUTE on function "public"."manager_workspace_employees"() to "authenticated";
grant EXECUTE on function "public"."manager_workspace_employees"() to "service_role";
grant EXECUTE on function "public"."my_ctod_context"() to PUBLIC;
grant EXECUTE on function "public"."my_ctod_context"() to "anon";
grant EXECUTE on function "public"."my_ctod_context"() to "authenticated";
grant EXECUTE on function "public"."my_ctod_context"() to "service_role";
grant EXECUTE on function "public"."protect_finalized_review_answers"() to PUBLIC;
grant EXECUTE on function "public"."protect_finalized_review_answers"() to "anon";
grant EXECUTE on function "public"."protect_finalized_review_answers"() to "authenticated";
grant EXECUTE on function "public"."protect_finalized_review_answers"() to "service_role";
grant EXECUTE on function "public"."recalculate_coaching_lifecycle"(p_coaching_id uuid) to "authenticated";
grant EXECUTE on function "public"."recalculate_coaching_lifecycle"(p_coaching_id uuid) to "service_role";
grant EXECUTE on function "public"."refresh_review_queue"(p_company_id uuid) to PUBLIC;
grant EXECUTE on function "public"."refresh_review_queue"(p_company_id uuid) to "anon";
grant EXECUTE on function "public"."refresh_review_queue"(p_company_id uuid) to "authenticated";
grant EXECUTE on function "public"."refresh_review_queue"(p_company_id uuid) to "service_role";
grant EXECUTE on function "public"."replace_location_manager"(p_location_id uuid, p_new_user_id uuid) to "authenticated";
grant EXECUTE on function "public"."replace_location_manager"(p_location_id uuid, p_new_user_id uuid) to "service_role";
grant EXECUTE on function "public"."review_finalize_check"(p_review_id uuid) to PUBLIC;
grant EXECUTE on function "public"."review_finalize_check"(p_review_id uuid) to "anon";
grant EXECUTE on function "public"."review_finalize_check"(p_review_id uuid) to "authenticated";
grant EXECUTE on function "public"."review_finalize_check"(p_review_id uuid) to "service_role";
grant EXECUTE on function "public"."review_print_summary"(p_review_id uuid) to PUBLIC;
grant EXECUTE on function "public"."review_print_summary"(p_review_id uuid) to "anon";
grant EXECUTE on function "public"."review_print_summary"(p_review_id uuid) to "authenticated";
grant EXECUTE on function "public"."review_print_summary"(p_review_id uuid) to "service_role";
grant EXECUTE on function "public"."revoke_access_invite"(p_invite_id uuid) to "authenticated";
grant EXECUTE on function "public"."revoke_access_invite"(p_invite_id uuid) to "service_role";
grant EXECUTE on function "public"."save_review_answer"(p_review_id uuid, p_question_id uuid, p_rating_id uuid, p_primary_reason_id uuid, p_additional_reason_id uuid, p_manager_note text, p_confirmed boolean) to PUBLIC;
grant EXECUTE on function "public"."save_review_answer"(p_review_id uuid, p_question_id uuid, p_rating_id uuid, p_primary_reason_id uuid, p_additional_reason_id uuid, p_manager_note text, p_confirmed boolean) to "anon";
grant EXECUTE on function "public"."save_review_answer"(p_review_id uuid, p_question_id uuid, p_rating_id uuid, p_primary_reason_id uuid, p_additional_reason_id uuid, p_manager_note text, p_confirmed boolean) to "authenticated";
grant EXECUTE on function "public"."save_review_answer"(p_review_id uuid, p_question_id uuid, p_rating_id uuid, p_primary_reason_id uuid, p_additional_reason_id uuid, p_manager_note text, p_confirmed boolean) to "service_role";
grant EXECUTE on function "public"."save_review_career_path"(p_review_id uuid, p_career_direction text, p_career_direction_reason text, p_desired_role_id uuid, p_final_desired_role_id uuid) to "authenticated";
grant EXECUTE on function "public"."save_review_career_path"(p_review_id uuid, p_career_direction text, p_career_direction_reason text, p_desired_role_id uuid, p_final_desired_role_id uuid) to "service_role";
grant EXECUTE on function "public"."save_review_career_roles"(p_review_id uuid, p_desired_role_id uuid, p_final_desired_role_id uuid) to "authenticated";
grant EXECUTE on function "public"."save_review_career_roles"(p_review_id uuid, p_desired_role_id uuid, p_final_desired_role_id uuid) to "service_role";
grant EXECUTE on function "public"."save_review_development"(p_review_id uuid, p_manager_summary text, p_employee_comments text, p_goal_text text, p_goal_target_date date, p_promotion_interest boolean, p_desired_role_id uuid, p_promotion_readiness text, p_raise_requested boolean, p_raise_basis text) to "authenticated";
grant EXECUTE on function "public"."save_review_development"(p_review_id uuid, p_manager_summary text, p_employee_comments text, p_goal_text text, p_goal_target_date date, p_promotion_interest boolean, p_desired_role_id uuid, p_promotion_readiness text, p_raise_requested boolean, p_raise_basis text) to "service_role";
grant EXECUTE on function "public"."set_coaching_review_link_company"() to "authenticated";
grant EXECUTE on function "public"."set_coaching_review_link_company"() to "service_role";
grant EXECUTE on function "public"."set_review_coaching_disposition"(p_review_id uuid, p_coaching_id uuid, p_disposition coaching_disposition, p_included_on_summary boolean) to PUBLIC;
grant EXECUTE on function "public"."set_review_coaching_disposition"(p_review_id uuid, p_coaching_id uuid, p_disposition coaching_disposition, p_included_on_summary boolean) to "anon";
grant EXECUTE on function "public"."set_review_coaching_disposition"(p_review_id uuid, p_coaching_id uuid, p_disposition coaching_disposition, p_included_on_summary boolean) to "authenticated";
grant EXECUTE on function "public"."set_review_coaching_disposition"(p_review_id uuid, p_coaching_id uuid, p_disposition coaching_disposition, p_included_on_summary boolean) to "service_role";
grant EXECUTE on function "public"."set_updated_at"() to PUBLIC;
grant EXECUTE on function "public"."set_updated_at"() to "anon";
grant EXECUTE on function "public"."set_updated_at"() to "authenticated";
grant EXECUTE on function "public"."set_updated_at"() to "service_role";
grant EXECUTE on function "public"."set_user_location_access"(p_user_id uuid, p_location_ids uuid[], p_role membership_role) to PUBLIC;
grant EXECUTE on function "public"."set_user_location_access"(p_user_id uuid, p_location_ids uuid[], p_role membership_role) to "anon";
grant EXECUTE on function "public"."set_user_location_access"(p_user_id uuid, p_location_ids uuid[], p_role membership_role) to "authenticated";
grant EXECUTE on function "public"."set_user_location_access"(p_user_id uuid, p_location_ids uuid[], p_role membership_role) to "service_role";
grant EXECUTE on function "public"."start_review"(p_review_id uuid) to PUBLIC;
grant EXECUTE on function "public"."start_review"(p_review_id uuid) to "anon";
grant EXECUTE on function "public"."start_review"(p_review_id uuid) to "authenticated";
grant EXECUTE on function "public"."start_review"(p_review_id uuid) to "service_role";
grant EXECUTE on function "public"."validate_review_manager_employee"() to PUBLIC;
grant EXECUTE on function "public"."validate_review_manager_employee"() to "anon";
grant EXECUTE on function "public"."validate_review_manager_employee"() to "authenticated";
grant EXECUTE on function "public"."validate_review_manager_employee"() to "service_role";

commit;
