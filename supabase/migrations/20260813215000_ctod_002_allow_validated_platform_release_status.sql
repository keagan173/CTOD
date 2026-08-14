-- CTOD 002 only
-- Allow the Platform Release pipeline to persist the validated state before approval.

alter table private.platform_releases
  drop constraint if exists platform_releases_status_check;

alter table private.platform_releases
  add constraint platform_releases_status_check
  check (status = any (array[
    'candidate'::text,
    'validated'::text,
    'available'::text,
    'retired'::text
  ]));
