begin;

-- Sandbox migration history version: 20260812045751.

create index if not exists customer_access_holds_held_by_idx
  on private.customer_access_holds(held_by_user_id);
create index if not exists customer_access_holds_membership_fk_idx
  on private.customer_access_holds(membership_id);
create index if not exists customer_access_holds_location_access_fk_idx
  on private.customer_access_holds(location_access_id);
create index if not exists customer_accounts_suspended_by_idx
  on private.customer_accounts(suspended_by_user_id);
create index if not exists customer_health_checked_by_idx
  on private.customer_health_snapshots(checked_by_user_id);
create index if not exists customer_release_actor_idx
  on private.customer_release_history(actor_user_id);

drop policy if exists companies_member_select on public.companies;
drop policy if exists companies_self_member_status_select on public.companies;
create policy companies_member_select
on public.companies
for select
to authenticated
using (
  id in (select private.current_company_ids())
  or exists(
      select 1 from public.company_memberships m
      where m.company_id=companies.id
        and m.user_id=(select auth.uid())
    )
);

commit;
