-- CTOD 002 SECURITY DEFINER review registry and hardening

revoke execute on function public.claim_initial_owner() from authenticated;
revoke execute on function public.recalculate_coaching_lifecycle(uuid) from authenticated;
revoke execute on function public.set_coaching_review_link_company() from authenticated;

create table if not exists private.security_definer_rpc_reviews (
  function_signature text primary key,
  review_status text not null check (review_status in ('intentional_user_rpc','internal_only','blocked')),
  authorization_basis text not null,
  reviewed_by_user_id uuid,
  reviewed_at timestamptz not null default now(),
  notes text
);

insert into private.security_definer_rpc_reviews(function_signature,review_status,authorization_basis,notes)
select
  p.proname||'('||replace(pg_get_function_identity_arguments(p.oid),'public.','')||')',
  'intentional_user_rpc',
  case
    when p.proname in ('accept_access_invite','accept_manager_invitation') then 'Authenticated identity is bound to invitation email/token before membership is granted.'
    when p.proname in ('manager_add_employee','manager_deactivate_employee','manager_edit_employee','manager_prepare_review','manager_set_review_schedule','manager_workspace_employees','finalize_review','save_review_career_path','save_review_career_roles') then 'Operation is restricted by private.can_access_location() to the signed-in user and target company/location.'
    else 'Operation verifies an active tenant membership and authorized company role before changing tenant-scoped access.'
  end,
  'Reviewed during CTOD 002 platform security audit.'
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.prosecdef=true and has_function_privilege('authenticated',p.oid,'EXECUTE')
on conflict(function_signature) do update set
  review_status=excluded.review_status,
  authorization_basis=excluded.authorization_basis,
  reviewed_at=now(),
  notes=excluded.notes;

create or replace function public.operator_service_security_review_status(p_actor_user_id uuid)
returns jsonb
language plpgsql
stable
set search_path=''
as $$
declare v_unreviewed jsonb; v_reviewed jsonb; v_unreviewed_count int;
begin
  if not exists(select 1 from private.platform_operators where user_id=p_actor_user_id and active=true and operator_role='platform_admin') then raise exception 'Platform administrator access required'; end if;
  with exposed as (
    select p.proname||'('||replace(pg_get_function_identity_arguments(p.oid),'public.','')||')' as signature
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prosecdef=true and has_function_privilege('authenticated',p.oid,'EXECUTE')
  )
  select count(*),coalesce(jsonb_agg(signature order by signature),'[]'::jsonb)
  into v_unreviewed_count,v_unreviewed
  from exposed e
  where not exists(select 1 from private.security_definer_rpc_reviews r where r.function_signature=e.signature and r.review_status='intentional_user_rpc');
  select coalesce(jsonb_agg(jsonb_build_object('function_signature',r.function_signature,'review_status',r.review_status,'authorization_basis',r.authorization_basis,'reviewed_at',r.reviewed_at) order by r.function_signature),'[]'::jsonb)
  into v_reviewed from private.security_definer_rpc_reviews r where r.review_status='intentional_user_rpc';
  return jsonb_build_object('passed',v_unreviewed_count=0,'unreviewed_count',v_unreviewed_count,'unreviewed',v_unreviewed,'reviewed',v_reviewed);
end $$;

revoke all on function public.operator_service_security_review_status(uuid) from public,anon,authenticated;
grant execute on function public.operator_service_security_review_status(uuid) to service_role;
