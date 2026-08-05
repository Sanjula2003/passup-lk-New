-- ============================================================================
-- PassUp.LK LMS — Migration 0006: Open subject catalog (multi-subject pivot)
-- ============================================================================
-- Original design locked subjects to exactly 'O/L ICT' / 'A/L ICT' (and
-- later 'SFT') as single combined strings. The new mission is broader:
-- increase GCE O/L and A/L pass rates across many subjects (Maths, Science,
-- ICT, SFT, etc). This migration splits "O/L ICT" into two real fields —
-- level ('O/L' or 'A/L') and name (just the subject) — and removes the
-- closed whitelist so the teacher can add any subject, at either level, at
-- any time from the Subjects page.
--
-- Written defensively (IF EXISTS / IF NOT EXISTS everywhere) so it's safe
-- to run regardless of which earlier migrations you already applied.
-- ============================================================================

alter table public.subjects add column if not exists level text;

-- Backfill level from the old combined names, only where not already set.
update public.subjects set level = 'O/L' where level is null and name ilike 'O/L%';
update public.subjects set level = 'A/L' where level is null and name ilike 'A/L%';
-- SFT was added with a plain name (no O/L/A/L prefix) — per your plan this
-- is an A/L subject. Edit it from Teacher → Subjects afterward if that's wrong.
update public.subjects set level = 'A/L' where level is null and name = 'SFT';
-- Safety net: anything still unset (shouldn't happen) defaults to O/L so the
-- NOT NULL constraint below doesn't fail; fix manually afterward if needed.
update public.subjects set level = 'O/L' where level is null;

-- Drop the old closed whitelist — subjects are open-ended from here on.
alter table public.subjects drop constraint if exists subjects_name_check;

-- Drop the old unique(name)-only constraint before renaming — the same
-- subject name can now exist at both levels (e.g. "ICT" at O/L and A/L).
alter table public.subjects drop constraint if exists subjects_name_key;

-- Strip the level prefix that used to be baked into the name.
update public.subjects
set name = trim(regexp_replace(name, '^(O/L|A/L)\s*', ''))
where name ~ '^(O/L|A/L)\s*';
-- e.g. 'O/L ICT' -> 'ICT', 'A/L ICT' -> 'ICT', 'SFT' unchanged.

alter table public.subjects alter column level set not null;
alter table public.subjects drop constraint if exists subjects_level_check;
alter table public.subjects add constraint subjects_level_check check (level in ('O/L', 'A/L'));

-- Replace the uniqueness rule: unique per (level, name), not name alone.
alter table public.subjects drop constraint if exists subjects_level_name_key;
alter table public.subjects add constraint subjects_level_name_key unique (level, name);

create index if not exists idx_subjects_level on public.subjects(level);
