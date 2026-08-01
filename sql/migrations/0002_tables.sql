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
