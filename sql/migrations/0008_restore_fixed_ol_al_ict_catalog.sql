-- ============================================================================
-- PassUp.LK LMS — Migration 0008: Restore fixed O/L ICT / A/L ICT catalog
-- ============================================================================
-- Reverses migration 0006 (which opened the subject catalog to any name at
-- any level, and split "O/L ICT" into level='O/L' + name='ICT'). Back to
-- the original spec: subjects are exactly 'O/L ICT' and 'A/L ICT' as
-- single combined names, nothing else, ever.
--
-- SAFETY CHECK: if you added any other subject while the catalog was open
-- (e.g. SFT, or anything else), this migration refuses to run rather than
-- silently deleting it or its courses/enrollments/payments. Delete or
-- reassign that subject's courses first (Teacher → Courses → Delete, or
-- change their subject), then re-run this migration.
--
-- Written defensively (IF EXISTS everywhere) so it's also safe to run on a
-- fresh install where migration 0006 never actually ran.
-- ============================================================================

do $$
declare
  extra_count int;
  extra_names text;
begin
  -- After 0006, the ORIGINAL "O/L ICT" / "A/L ICT" rows now have
  -- name = 'ICT' with level = 'O/L' / 'A/L' respectively. Anything that
  -- isn't one of those two (level, name) combinations is an addition made
  -- while the catalog was open, and must be cleared out manually first.
  select count(*), string_agg(name || ' (' || coalesce(level, 'no level') || ')', ', ')
  into extra_count, extra_names
  from public.subjects
  where not (
    (level = 'O/L' and name = 'ICT') or
    (level = 'A/L' and name = 'ICT') or
    -- also tolerate a fresh install / already-restored row shaped like the target state
    name in ('O/L ICT', 'A/L ICT')
  );

  if extra_count > 0 then
    raise exception 'Cannot restore the fixed catalog: % other subject(s) still exist: %. Delete their courses (Teacher → Courses) and the subject itself (Teacher → Subjects) first, then re-run this migration.', extra_count, extra_names;
  end if;
end $$;

-- Recombine the level prefix back into the name before the level column
-- goes away, e.g. level='O/L', name='ICT' -> name='O/L ICT'.
update public.subjects set name = 'O/L ICT' where level = 'O/L' and name = 'ICT';
update public.subjects set name = 'A/L ICT' where level = 'A/L' and name = 'ICT';

-- Drop the (level, name) uniqueness rule and the level column itself.
alter table public.subjects drop constraint if exists subjects_level_name_key;
alter table public.subjects drop constraint if exists subjects_level_check;
alter table public.subjects drop column if exists level;

-- Restore the original single-field uniqueness + whitelist.
alter table public.subjects drop constraint if exists subjects_name_key;
alter table public.subjects drop constraint if exists subjects_name_check;
alter table public.subjects add constraint subjects_name_key unique (name);
alter table public.subjects add constraint subjects_name_check check (name in ('O/L ICT', 'A/L ICT'));

drop index if exists idx_subjects_level;
