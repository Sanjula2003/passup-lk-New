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
