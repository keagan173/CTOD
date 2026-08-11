-- CTOD SANDBOX ONLY. Clears fake operational data but preserves schema,
-- configuration libraries, Auth users, profiles, memberships, and location access.

begin;

do $$
begin
  if not exists (
    select 1
    from ctod_sandbox.environment_guard
    where singleton
      and environment = 'sandbox'
      and production_project_ref <> sandbox_project_ref
  ) then
    raise exception 'Sandbox reset refused: environment guard is missing or invalid';
  end if;
end;
$$;

delete from public.access_invites;
delete from public.manager_invitations;
delete from public.audit_events
where event_type <> 'sandbox.master.created';
delete from public.import_batches;

delete from public.compensation_decisions;
delete from public.coaching_review_links;
delete from public.goals;
delete from public.career_decisions;
delete from public.review_summaries;

-- Finalized answers are normally immutable. Reset is possible only in this
-- guarded sandbox transaction, and reviews are made non-final before removal.
update public.reviews
set status = 'in_progress', finalized_at = null
where status = 'finalized';
delete from public.review_answers;
delete from public.reviews;

delete from public.coaching_moments;
delete from public.succession_records;
delete from public.employment_assignments;
delete from public.employees;
delete from public.attachments;

update ctod_sandbox.environment_guard
set last_reset_at = now()
where singleton;

commit;
