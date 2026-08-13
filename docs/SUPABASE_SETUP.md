# Supabase Setup

## 1. Create a project

1. Go to [supabase.com](https://supabase.com) and create a new project.
2. Note your **Project URL** and **anon/public API key** (Project Settings →
   API). You'll need these for `config/config.js` and your Netlify
   environment variables.
3. **Never copy the `service_role` key into frontend code or config files.**
   It bypasses Row Level Security entirely.

## 2. Run the database migrations

In the Supabase Dashboard, open **SQL Editor** and run the files in
`/sql/migrations/` **in order**:

```
0001_extensions_and_types.sql
0002_tables.sql
0003_indexes.sql
0004_functions_and_triggers.sql
0005_rls_policies.sql
0006_subject_catalog_rework.sql
0007_public_curriculum_preview.sql
0008_restore_fixed_ol_al_ict_catalog.sql
```

Or paste the entire contents of `/sql/schema_full.sql` in one go — it's the
same files concatenated in order. Every migration is written defensively
(`IF EXISTS`/`IF NOT EXISTS`/`CREATE OR REPLACE`), so re-running the whole
file is safe even if some of it already ran in an earlier session.

**If this is an existing project** that already has data (i.e. you're not
setting up from scratch), you only need to run the migrations you haven't
run yet — most likely just `0008_restore_fixed_ol_al_ict_catalog.sql` on its
own. It has a built-in safety check: it refuses to run (with a clear error,
no data loss) if any subject other than O/L ICT / A/L ICT still exists.

## 3. Configure Auth

1. **Authentication → Providers** — Email should be enabled by default.
2. **Authentication → Email Templates** — customize the "Confirm signup" and
   "Reset password" templates if you'd like PassUp.LK branding (optional).
3. **Authentication → URL Configuration** — set:
   - **Site URL**: your production URL (e.g. `https://passup.lk`)
   - **Redirect URLs**: add both your local dev URL
     (`http://localhost:5500/*`) and production URL (`https://passup.lk/*`)
     so the email verification and password reset links work in both
     environments.
4. Confirm **"Confirm email"** is turned ON under Authentication → Settings
   — the spec requires email verification before login.

## 4. Seed the fixed subject catalog

Still in the SQL Editor, run `/sql/seed.sql`. This inserts:
- The two fixed subjects: `O/L ICT` and `A/L ICT`
- Default site settings (WhatsApp number, bank details, cashback policy
  text) — placeholder values you should edit afterward from the Teacher
  Settings page, or directly in the `settings` table.

## 5. Create and promote the teacher account

There is no "sign up as teacher" option by design — every signup defaults
to `role = 'student'`. To designate the one teacher account:

1. Sign up normally through `/signup.html` with the real teacher's email.
2. Verify the email (click the link Supabase sends).
3. Back in the SQL Editor, run:
   ```sql
   update public.profiles set role = 'teacher' where email = 'teacher@passup.lk';
   ```
4. Log in — you'll land on `/teacher/dashboard.html`.

A database trigger (`enforce_single_teacher`) blocks this statement if a
teacher account already exists, so it's safe to keep as a one-time step.

## 6. (Optional) Storage bucket for thumbnails

If you want to upload course thumbnail images rather than linking external
URLs, create a public Storage bucket named `course-thumbnails` under
**Storage** in the dashboard, and set its access policy to public read.
The current UI expects a plain URL in `courses.thumbnail_url`, so any
public image URL (including a Supabase Storage public URL) works as-is.

## 7. Sanity check

Run this in the SQL Editor to confirm everything's in place:

```sql
select count(*) as subjects from public.subjects;         -- expect 2
select count(*) as teachers from public.profiles where role = 'teacher'; -- expect 1 (after step 5)
select tablename from pg_tables where schemaname = 'public'; -- expect 9 tables
```
