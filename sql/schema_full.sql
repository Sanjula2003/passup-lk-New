-- ============================================================================
-- PassUp.LK LMS — Migration 0001: Extensions & Custom Types
-- ============================================================================
-- Run this first. Safe to re-run (idempotent) on a fresh Supabase project.
-- ============================================================================

-- gen_random_uuid() for primary keys
create extension if not exists "pgcrypto";

-- ----------------------------------------------------------------------------
-- Enumerated types
-- ----------------------------------------------------------------------------

-- Exactly two roles exist in this system: 'teacher' (singular) and 'student'.
do $$
begin
  if not exists (select 1 from pg_type where typname = 'user_role') then
    create type public.user_role as enum ('teacher', 'student');
  end if;
end$$;

-- Lifecycle of a student's enrollment request into a course.
do $$
begin
  if not exists (select 1 from pg_type where typname = 'enrollment_status') then
    create type public.enrollment_status as enum ('pending', 'approved', 'rejected', 'suspended');
  end if;
end$$;

-- Account status — teacher can suspend a student without deleting their data.
do $$
begin
  if not exists (select 1 from pg_type where typname = 'account_status') then
    create type public.account_status as enum ('active', 'suspended');
  end if;
end$$;
-- ============================================================================
-- PassUp.LK LMS — Migration 0002: Core Tables
-- ============================================================================
-- Hierarchy: Subject -> Course -> Topic -> Lesson
-- Roles: profiles.role = 'teacher' (exactly one) | 'student' (unlimited)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- profiles
-- One row per authenticated user. 1:1 with auth.users, created automatically
-- by the handle_new_user() trigger defined in migration 0004.
-- ----------------------------------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  full_name    text not null,
  email        text not null unique,
  role         public.user_role not null default 'student',
  status       public.account_status not null default 'active',
  avatar_url   text,
  phone        text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

comment on table public.profiles is 'One row per user. Exactly one row may have role = teacher (enforced by trigger).';

-- ----------------------------------------------------------------------------
-- subjects
-- Fixed catalog: only O/L ICT and A/L ICT ever exist.
-- ----------------------------------------------------------------------------
create table if not exists public.subjects (
  id             uuid primary key default gen_random_uuid(),
  name           text not null unique check (name in ('O/L ICT', 'A/L ICT')),
  slug           text not null unique,
  description    text,
  icon_url       text,
  display_order  int not null default 0,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- courses
-- ----------------------------------------------------------------------------
create table if not exists public.courses (
  id             uuid primary key default gen_random_uuid(),
  subject_id     uuid not null references public.subjects(id) on delete cascade,
  title          text not null,
  slug           text not null unique,
  description    text,
  thumbnail_url  text,
  price          numeric(10,2) not null default 0 check (price >= 0),
  is_published   boolean not null default false,
  display_order  int not null default 0,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- topics
-- ----------------------------------------------------------------------------
create table if not exists public.topics (
  id             uuid primary key default gen_random_uuid(),
  course_id      uuid not null references public.courses(id) on delete cascade,
  title          text not null,
  description    text,
  display_order  int not null default 0,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- lessons
-- youtube_video_id stores ONLY the 11-char YouTube video id (not a full URL)
-- so the frontend can build the embed URL consistently and swap embed params
-- (e.g. modestbranding, rel=0) in one place.
-- ----------------------------------------------------------------------------
create table if not exists public.lessons (
  id                uuid primary key default gen_random_uuid(),
  topic_id          uuid not null references public.topics(id) on delete cascade,
  title             text not null,
  description       text,
  youtube_video_id  text not null,
  pdf_url           text,
  display_order     int not null default 0,
  is_published      boolean not null default false,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- enrollments
-- Created by a student (status starts 'pending'), moved to 'approved' or
-- 'rejected' only by the teacher after manually verifying a WhatsApp payment
-- slip. One enrollment row per (student, course) pair.
-- ----------------------------------------------------------------------------
create table if not exists public.enrollments (
  id                 uuid primary key default gen_random_uuid(),
  student_id         uuid not null references public.profiles(id) on delete cascade,
  course_id          uuid not null references public.courses(id) on delete cascade,
  status             public.enrollment_status not null default 'pending',
  payment_slip_url   text,
  payment_reference  text,
  rejection_reason   text,
  approved_by        uuid references public.profiles(id) on delete set null,
  approved_at        timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  unique (student_id, course_id)
);

-- ----------------------------------------------------------------------------
-- payments
-- Ledger of manually-verified payments, tied to an enrollment. Kept separate
-- from enrollments so a course can (later) support multiple payments
-- (e.g. installments) without a schema change.
-- ----------------------------------------------------------------------------
create table if not exists public.payments (
  id             uuid primary key default gen_random_uuid(),
  enrollment_id  uuid not null references public.enrollments(id) on delete cascade,
  amount         numeric(10,2) not null check (amount >= 0),
  method         text not null default 'bank_transfer',
  slip_url       text,
  notes          text,
  verified_by    uuid references public.profiles(id) on delete set null,
  verified_at    timestamptz,
  created_at     timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- lesson_progress
-- Per-student completion tracking, used to compute course progress % and
-- drive the "Completed" indicator in the course player.
-- ----------------------------------------------------------------------------
create table if not exists public.lesson_progress (
  id                 uuid primary key default gen_random_uuid(),
  student_id         uuid not null references public.profiles(id) on delete cascade,
  lesson_id          uuid not null references public.lessons(id) on delete cascade,
  is_completed       boolean not null default false,
  completed_at       timestamptz,
  last_watched_at    timestamptz not null default now(),
  unique (student_id, lesson_id)
);

-- ----------------------------------------------------------------------------
-- settings
-- Simple key/value store for site-wide, teacher-editable configuration:
-- WhatsApp number for payment slips, bank account details, cashback policy
-- text, etc. Value is jsonb so each key can hold a scalar or structured value.
-- ----------------------------------------------------------------------------
create table if not exists public.settings (
  key         text primary key,
  value       jsonb not null,
  updated_at  timestamptz not null default now()
);
-- ============================================================================
-- PassUp.LK LMS — Migration 0003: Indexes
-- ============================================================================

-- profiles
create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_profiles_status on public.profiles(status);

-- subjects
create index if not exists idx_subjects_slug on public.subjects(slug);

-- courses
create index if not exists idx_courses_subject_id on public.courses(subject_id);
create index if not exists idx_courses_slug on public.courses(slug);
create index if not exists idx_courses_is_published on public.courses(is_published);

-- topics
create index if not exists idx_topics_course_id on public.topics(course_id);
create index if not exists idx_topics_display_order on public.topics(course_id, display_order);

-- lessons
create index if not exists idx_lessons_topic_id on public.lessons(topic_id);
create index if not exists idx_lessons_display_order on public.lessons(topic_id, display_order);
create index if not exists idx_lessons_is_published on public.lessons(is_published);

-- enrollments
create index if not exists idx_enrollments_student_id on public.enrollments(student_id);
create index if not exists idx_enrollments_course_id on public.enrollments(course_id);
create index if not exists idx_enrollments_status on public.enrollments(status);

-- payments
create index if not exists idx_payments_enrollment_id on public.payments(enrollment_id);

-- lesson_progress
create index if not exists idx_lesson_progress_student_id on public.lesson_progress(student_id);
create index if not exists idx_lesson_progress_lesson_id on public.lesson_progress(lesson_id);
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
-- ============================================================================
-- PassUp.LK LMS — Migration 0005: Row Level Security
-- ============================================================================
-- Every table has RLS enabled with NO default access. Frontend must never
-- rely on client-side role checks alone — these policies are the real
-- authorization boundary. The Supabase service_role key (which bypasses
-- RLS) must NEVER be used in frontend code.
-- ============================================================================

alter table public.profiles        enable row level security;
alter table public.subjects        enable row level security;
alter table public.courses         enable row level security;
alter table public.topics          enable row level security;
alter table public.lessons         enable row level security;
alter table public.enrollments     enable row level security;
alter table public.payments        enable row level security;
alter table public.lesson_progress enable row level security;
alter table public.settings        enable row level security;

-- ----------------------------------------------------------------------------
-- profiles
-- ----------------------------------------------------------------------------
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select"
  on public.profiles for select
  using ( auth.uid() = id or public.is_teacher() );

drop policy if exists "profiles_update" on public.profiles;
create policy "profiles_update"
  on public.profiles for update
  using ( auth.uid() = id or public.is_teacher() )
  with check ( auth.uid() = id or public.is_teacher() );
  -- role/status escalation is blocked by trg_prevent_self_role_escalation

drop policy if exists "profiles_delete" on public.profiles;
create policy "profiles_delete"
  on public.profiles for delete
  using ( public.is_teacher() );

-- Note: no INSERT policy — rows are created only by handle_new_user(),
-- which runs as security definer and bypasses RLS.

-- ----------------------------------------------------------------------------
-- subjects — fixed catalog, publicly readable, teacher-managed
-- ----------------------------------------------------------------------------
drop policy if exists "subjects_select" on public.subjects;
create policy "subjects_select"
  on public.subjects for select
  using ( true );

drop policy if exists "subjects_write" on public.subjects;
create policy "subjects_write"
  on public.subjects for all
  using ( public.is_teacher() )
  with check ( public.is_teacher() );

-- ----------------------------------------------------------------------------
-- courses — published courses are public (landing page, course catalog);
-- unpublished (draft) courses are visible only to the teacher.
-- ----------------------------------------------------------------------------
drop policy if exists "courses_select" on public.courses;
create policy "courses_select"
  on public.courses for select
  using ( is_published = true or public.is_teacher() );

drop policy if exists "courses_write" on public.courses;
create policy "courses_write"
  on public.courses for all
  using ( public.is_teacher() )
  with check ( public.is_teacher() );

-- ----------------------------------------------------------------------------
-- topics — visible if the parent course is visible
-- ----------------------------------------------------------------------------
drop policy if exists "topics_select" on public.topics;
create policy "topics_select"
  on public.topics for select
  using (
    public.is_teacher()
    or exists (
      select 1 from public.courses c
      where c.id = topics.course_id and c.is_published = true
    )
  );

drop policy if exists "topics_write" on public.topics;
create policy "topics_write"
  on public.topics for all
  using ( public.is_teacher() )
  with check ( public.is_teacher() );

-- ----------------------------------------------------------------------------
-- lessons — the actual paid content. A student can only see a lesson if:
--   1. the lesson itself is published, AND
--   2. they have an APPROVED enrollment in the course that owns it.
-- The teacher can always see everything (published or not).
-- ----------------------------------------------------------------------------
drop policy if exists "lessons_select" on public.lessons;
create policy "lessons_select"
  on public.lessons for select
  using (
    public.is_teacher()
    or (
      is_published = true
      and exists (
        select 1
        from public.topics t
        join public.courses c on c.id = t.course_id
        where t.id = lessons.topic_id
          and public.is_enrolled_and_approved(c.id)
      )
    )
  );

drop policy if exists "lessons_write" on public.lessons;
create policy "lessons_write"
  on public.lessons for all
  using ( public.is_teacher() )
  with check ( public.is_teacher() );

-- ----------------------------------------------------------------------------
-- enrollments
-- ----------------------------------------------------------------------------
drop policy if exists "enrollments_select" on public.enrollments;
create policy "enrollments_select"
  on public.enrollments for select
  using ( student_id = auth.uid() or public.is_teacher() );

-- A student may create their own pending enrollment request.
drop policy if exists "enrollments_insert" on public.enrollments;
create policy "enrollments_insert"
  on public.enrollments for insert
  with check ( student_id = auth.uid() or public.is_teacher() );

-- A student may only edit their own request (e.g. attach a payment slip)
-- while it is still pending. Once it's approved/rejected/suspended, only
-- the teacher can change it.
drop policy if exists "enrollments_update" on public.enrollments;
create policy "enrollments_update"
  on public.enrollments for update
  using (
    public.is_teacher()
    or (student_id = auth.uid() and status = 'pending')
  )
  with check (
    public.is_teacher()
    or (student_id = auth.uid() and status = 'pending')
  );

drop policy if exists "enrollments_delete" on public.enrollments;
create policy "enrollments_delete"
  on public.enrollments for delete
  using ( public.is_teacher() );

-- ----------------------------------------------------------------------------
-- payments — verification ledger, written by the teacher, readable by the
-- owning student for their own payment history.
-- ----------------------------------------------------------------------------
drop policy if exists "payments_select" on public.payments;
create policy "payments_select"
  on public.payments for select
  using (
    public.is_teacher()
    or exists (
      select 1 from public.enrollments e
      where e.id = payments.enrollment_id and e.student_id = auth.uid()
    )
  );

drop policy if exists "payments_write" on public.payments;
create policy "payments_write"
  on public.payments for all
  using ( public.is_teacher() )
  with check ( public.is_teacher() );

-- ----------------------------------------------------------------------------
-- lesson_progress — a student manages only their own progress; the teacher
-- can read everyone's for analytics but does not need to write it.
-- ----------------------------------------------------------------------------
drop policy if exists "lesson_progress_select" on public.lesson_progress;
create policy "lesson_progress_select"
  on public.lesson_progress for select
  using ( student_id = auth.uid() or public.is_teacher() );

drop policy if exists "lesson_progress_insert" on public.lesson_progress;
create policy "lesson_progress_insert"
  on public.lesson_progress for insert
  with check ( student_id = auth.uid() );

drop policy if exists "lesson_progress_update" on public.lesson_progress;
create policy "lesson_progress_update"
  on public.lesson_progress for update
  using ( student_id = auth.uid() )
  with check ( student_id = auth.uid() );

-- ----------------------------------------------------------------------------
-- settings — public info (WhatsApp number, bank details, cashback terms)
-- needed by unauthenticated visitors on the Payment Instructions / FAQ
-- pages; only the teacher can change it.
-- ----------------------------------------------------------------------------
drop policy if exists "settings_select" on public.settings;
create policy "settings_select"
  on public.settings for select
  using ( true );

drop policy if exists "settings_write" on public.settings;
create policy "settings_write"
  on public.settings for all
  using ( public.is_teacher() )
  with check ( public.is_teacher() );
-- Run seed.sql separately AFTER the teacher has signed up through the app.
