create or replace function public.get_review_summary_payload(p_review_id uuid)
returns jsonb
language plpgsql
stable
set search_path to 'public'
as $function$
declare
  r public.reviews;
  base jsonb;
  company_json jsonb;
begin
  select * into r from public.reviews where id=p_review_id;
  if not found then raise exception 'Review not found'; end if;
  if not private.can_access_location(r.company_id,r.location_id) then raise exception 'Access denied'; end if;
  base:=public.get_review_form(p_review_id);
  select jsonb_build_object('id',c.id,'name',c.name,'branding',c.branding) into company_json from public.companies c where c.id=r.company_id;
  return base || jsonb_build_object('company',company_json,'summary_contract_version','CTOD-2PAGE-1.4');
end
$function$;