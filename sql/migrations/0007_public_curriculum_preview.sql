-- ============================================================================
-- PassUp.LK LMS — Migration 0007: Public curriculum preview
-- ============================================================================
-- NOTE: if get_public_curriculum() already exists in your database from an
-- earlier chat session, this is safe to re-run — it's just missing from
-- your local sql/migrations folder until now, so a fresh install would
-- otherwise be missing it.
--
-- Problem: the public course detail page (course.html) needs to show the
-- curriculum outline — topic names and lesson counts/titles — to anyone
-- browsing, even before they enroll, so they can see what they'd be buying.
-- But the `lessons` RLS policy correctly requires an APPROVED enrollment to
-- read a lesson row at all, since that row also contains youtube_video_id
-- and pdf_url — the actual paid content.
--
-- Solution: a security-definer function that returns ONLY safe preview
-- columns (ids, titles, ordering) for published lessons, with no
-- enrollment check. It never exposes youtube_video_id or pdf_url, so it's
-- safe to expose to anonymous visitors — the real content stays gated by
-- the existing lessons_select RLS policy for anyone querying the table
-- directly (e.g. the course player).
-- ============================================================================

create or replace function public.get_public_curriculum(p_course_id uuid)
returns table (
  topic_id      uuid,
  topic_title   text,
  topic_order   int,
  lesson_id     uuid,
  lesson_title  text,
  lesson_order  int
)
language sql
stable
security definer
set search_path = public
as $$
  select
    t.id, t.title, t.display_order,
    l.id, l.title, l.display_order
  from public.topics t
  join public.lessons l on l.topic_id = t.id
  where t.course_id = p_course_id
    and l.is_published = true
  order by t.display_order, l.display_order;
$$;

-- Callable by anyone, including anonymous (anon) visitors — that's the
-- whole point of this function. It only ever returns published-lesson
-- preview data, never the gated youtube_video_id/pdf_url columns.
grant execute on function public.get_public_curriculum(uuid) to anon, authenticated;
