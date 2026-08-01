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
