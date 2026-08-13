-- ============================================================================
-- PassUp.LK LMS — Seed Data
-- ============================================================================
-- Run this ONCE after the migrations, and after your teacher account has
-- signed up normally through the app's signup page (so a matching row
-- already exists in auth.users / public.profiles).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Fixed subject catalog — only these two rows should ever exist.
-- ----------------------------------------------------------------------------
insert into public.subjects (name, slug, description, display_order)
values
  ('O/L ICT', 'ol-ict', 'Ordinary Level Information & Communication Technology', 1),
  ('A/L ICT', 'al-ict', 'Advanced Level Information & Communication Technology', 2)
on conflict (name) do nothing;

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
