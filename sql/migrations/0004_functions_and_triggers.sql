-- ============================================================================
-- PassUp.LK LMS — Migration 0004: Functions & Triggers
-- ============================================================================

-- ----------------------------------------------------------------------------
-- updated_at maintenance
-- ----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists trg_subjects_updated_at on public.subjects;
create trigger trg_subjects_updated_at
  before update on public.subjects
  for each row execute function public.set_updated_at();

drop trigger if exists trg_courses_updated_at on public.courses;
create trigger trg_courses_updated_at
  before update on public.courses
  for each row execute function public.set_updated_at();

drop trigger if exists trg_topics_updated_at on public.topics;
create trigger trg_topics_updated_at
  before update on public.topics
  for each row execute function public.set_updated_at();

drop trigger if exists trg_lessons_updated_at on public.lessons;
create trigger trg_lessons_updated_at
  before update on public.lessons
  for each row execute function public.set_updated_at();

drop trigger if exists trg_enrollments_updated_at on public.enrollments;
create trigger trg_enrollments_updated_at
  before update on public.enrollments
  for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- is_teacher() — RLS helper.
-- security definer so it can read public.profiles without being blocked by
-- that table's own RLS policies (which would otherwise cause recursion).
-- ----------------------------------------------------------------------------
create or replace function public.is_teacher()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'teacher'
  );
$$;

-- ----------------------------------------------------------------------------
-- is_enrolled_and_approved(course_id) — RLS helper for lesson visibility.
-- ----------------------------------------------------------------------------
create or replace function public.is_enrolled_and_approved(p_course_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.enrollments
    where student_id = auth.uid()
      and course_id = p_course_id
      and status = 'approved'
  );
$$;

-- ----------------------------------------------------------------------------
-- handle_new_user() — auto-creates a profiles row whenever a new user signs
-- up via Supabase Auth. Full name is pulled from the signup metadata the
-- frontend sends (raw_user_meta_data->>'full_name'). Every new signup is a
-- student; the single teacher account is promoted manually (see seed.sql).
-- ----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.email,
    'student'
  );
  return new;
end;
$$;

drop trigger if exists trg_on_auth_user_created on auth.users;
create trigger trg_on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ----------------------------------------------------------------------------
-- enforce_single_teacher() — guarantees the "exactly ONE teacher" rule at the
-- database level, not just in application code.
-- ----------------------------------------------------------------------------
create or replace function public.enforce_single_teacher()
returns trigger
language plpgsql
as $$
begin
  if new.role = 'teacher' then
    if exists (
      select 1 from public.profiles
      where role = 'teacher' and id <> new.id
    ) then
      raise exception 'PassUp.LK allows exactly one teacher account. A teacher already exists.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_enforce_single_teacher on public.profiles;
create trigger trg_enforce_single_teacher
  before insert or update of role on public.profiles
  for each row execute function public.enforce_single_teacher();

-- ----------------------------------------------------------------------------
-- prevent_self_role_escalation() — a student updating their own profile row
-- (e.g. changing their name) must not be able to also change role or status.
-- Only the teacher (via a service-role/teacher-authenticated update) may.
-- ----------------------------------------------------------------------------
create or replace function public.prevent_self_role_escalation()
returns trigger
language plpgsql
as $$
begin
  if not public.is_teacher() then
    if new.role <> old.role or new.status <> old.status then
      raise exception 'Only the teacher can change role or status.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_prevent_self_role_escalation on public.profiles;
create trigger trg_prevent_self_role_escalation
  before update on public.profiles
  for each row execute function public.prevent_self_role_escalation();

-- ----------------------------------------------------------------------------
-- set_enrollment_approval_fields() — stamps approved_by/approved_at whenever
-- the teacher flips an enrollment to 'approved', and clears them if it's
-- ever moved back out of 'approved'.
-- ----------------------------------------------------------------------------
create or replace function public.set_enrollment_approval_fields()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'approved' and old.status is distinct from 'approved' then
    new.approved_by = auth.uid();
    new.approved_at = now();
  elsif new.status <> 'approved' then
    new.approved_by = null;
    new.approved_at = null;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_enrollment_approval on public.enrollments;
create trigger trg_enrollment_approval
  before update on public.enrollments
  for each row execute function public.set_enrollment_approval_fields();

-- ----------------------------------------------------------------------------
-- Student-created enrollment requests must always start as 'pending' and
-- must be owned by the inserting user — prevents a student from inserting
-- an enrollment for someone else or pre-approving themselves.
-- ----------------------------------------------------------------------------
create or replace function public.enforce_pending_enrollment_on_insert()
returns trigger
language plpgsql
as $$
begin
  if not public.is_teacher() then
    new.status = 'pending';
    if new.student_id <> auth.uid() then
      raise exception 'Students may only enroll themselves.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_enforce_pending_enrollment on public.enrollments;
create trigger trg_enforce_pending_enrollment
  before insert on public.enrollments
  for each row execute function public.enforce_pending_enrollment_on_insert();
