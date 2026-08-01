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
