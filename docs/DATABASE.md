# PassUp.LK — Database Schema

This document describes the Supabase/PostgreSQL schema in `/sql`. Run the files
in `sql/migrations/` in numeric order (or import `sql/schema_full.sql` in one
shot), then run `sql/seed.sql`.

## Entity hierarchy

```
subjects (level: O/L or A/L, name: Maths/Science/ICT/... — open catalog)
  └── courses
        └── topics
              └── lessons
```

## Tables

| Table              | Purpose                                                                 |
|---------------------|--------------------------------------------------------------------------|
| `profiles`          | One row per user (1:1 with `auth.users`). `role` is `teacher` or `student`. Exactly one `teacher` row is allowed, enforced by trigger. |
| `subjects`          | Open catalog. Each row has a `level` (`O/L` or `A/L`) and a `name` (e.g. `Maths`, `ICT`). Unique per `(level, name)` — the same subject name can exist at both levels. Managed from Teacher → Subjects; no code change needed to add one. |
| `courses`           | Belongs to a subject. `is_published` controls public visibility.        |
| `topics`            | Belongs to a course. Groups lessons.                                    |
| `lessons`           | Belongs to a topic. Stores the YouTube video id (not full URL) and a PDF link. |
| `enrollments`       | A student's request to join a course. Starts `pending`, teacher moves it to `approved`/`rejected`/`suspended` after manually verifying a WhatsApp payment slip. |
| `payments`          | Verification ledger tied to an enrollment (amount, method, who verified it, when). |
| `lesson_progress`   | Per-student, per-lesson completion tracking — powers course progress % and the "completed" indicator. |
| `settings`          | Key/value store for site-wide config the teacher can edit: WhatsApp number, bank details, cashback policy text. |

## Enforced rules (at the database level, not just the frontend)

- **Exactly one teacher.** `enforce_single_teacher()` raises an exception if a
  second `profiles.role = 'teacher'` row is attempted.
- **No self-promotion.** A student updating their own profile cannot change
  their own `role` or `status` — only a teacher-authenticated request can
  (`prevent_self_role_escalation()`).
- **Enrollment requests can't be self-approved.** Students inserting an
  enrollment always get forced to `status = 'pending'`
  (`enforce_pending_enrollment_on_insert()`); only the teacher can move it to
  `approved`/`rejected`/`suspended`.
- **Lesson content is gated.** A student can `SELECT` a lesson only if it's
  published *and* they hold an `approved` enrollment for its parent course.
  Unpublished courses/lessons are visible only to the teacher.

## Row Level Security

RLS is enabled on every table — see `sql/migrations/0005_rls_policies.sql`.
Two `security definer` helper functions avoid RLS recursion when a policy
needs to check the caller's own role:

- `public.is_teacher()` — true if `auth.uid()` belongs to the teacher.
- `public.is_enrolled_and_approved(course_id)` — true if `auth.uid()` has an
  approved enrollment in that course.

**The frontend must always use the Supabase anon/publishable key.** The
service role key bypasses RLS entirely and must never be shipped to the
browser or committed to the repo.

## Promoting the teacher account

There is no signup flag for "I am the teacher" — by design, every signup is a
student. After the real teacher signs up once through the normal signup
flow, run:

```sql
update public.profiles set role = 'teacher' where email = 'teacher@passup.lk';
```

The single-teacher trigger will reject this if a teacher already exists, so
it's safe to keep this line in `seed.sql` as documentation without it running
automatically.
