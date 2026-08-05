-- ============================================================================
-- PassUp.LK LMS — Seed Data
-- ============================================================================
-- Run this ONCE after the migrations, and after your teacher account has
-- signed up normally through the app's signup page (so a matching row
-- already exists in auth.users / public.profiles).
--
-- NOTE: if you already ran an earlier version of this file (before the
-- subjects catalog became open-ended in migration 0006), you do NOT need to
-- re-run this section — your existing O/L ICT / A/L ICT rows were converted
-- automatically. This is only for a brand-new project.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Starter subject catalog — a starting point, not a limit. Add, edit, or
--    remove subjects anytime from Teacher → Subjects; nothing here is fixed.
-- ----------------------------------------------------------------------------
insert into public.subjects (level, name, slug, description, display_order)
values
  ('O/L', 'ICT', 'ol-ict', 'Ordinary Level Information & Communication Technology', 1),
  ('A/L', 'ICT', 'al-ict', 'Advanced Level Information & Communication Technology', 2)
on conflict (level, name) do nothing;

-- ----------------------------------------------------------------------------
-- 2. Default site settings — edit values to match the real teacher/business
--    details before going live.
-- ----------------------------------------------------------------------------
insert into public.settings (key, value)
values
  ('whatsapp_number', '"+94700000000"'),
  ('bank_details', '{"bank": "Sample Bank", "account_name": "PassUp.LK", "account_number": "0000000000", "branch": "Colombo"}'),
  ('cashback_policy', '"If a student completes the full program and still fails, PassUp.LK refunds 100% of the course fee."'),
  ('site_contact_email', '"hello@passup.lk"')
on conflict (key) do nothing;

-- ----------------------------------------------------------------------------
-- 3. Promote the teacher account.
-- ----------------------------------------------------------------------------
-- Every new signup defaults to role = 'student'. To designate the single
-- teacher account, sign up normally through the app with the teacher's real
-- email, then run:
--
--   update public.profiles set role = 'teacher' where email = 'teacher@passup.lk';
--
-- The enforce_single_teacher() trigger (migration 0004) will reject this
-- statement if a teacher account already exists, so it is safe to run only
-- once. This step is intentionally NOT automated here since it depends on
-- an auth.users row that only exists after real signup.
