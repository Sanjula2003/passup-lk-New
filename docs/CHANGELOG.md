# Changelog

All notable changes to PassUp.LK are documented here.
This project follows [Keep a Changelog](https://keepachangelog.com/) style.

## [1.1.0] — Restore fixed O/L ICT / A/L ICT catalog

### Changed
- Reverted the brief experiment with an open, multi-subject catalog
  (subjects with any name at any level, e.g. Maths, Science, SFT) back to
  the original fixed catalog: exactly `O/L ICT` and `A/L ICT`, enforced by
  a database `CHECK` constraint.
- Teacher → Subjects is edit-only again (description field only) — no
  add/delete subject actions.
- Course browsing (public catalog and student "All Courses") back to a
  single-tier subject filter instead of level+subject.
- Landing page, About page, and auth page copy reverted to ICT-specific
  wording.

## [1.0.0] — Initial Release

### Added
- Public site: landing page, about, courses catalog, course detail/enroll
  page, FAQ, contact, privacy policy, terms of service.
- Authentication: signup with email verification, login, forgot/reset
  password, all via Supabase Auth.
- Student app: dashboard, my courses, protected course player with
  YouTube embeds + PDF notes + progress tracking, profile, settings,
  payment instructions.
- Teacher app: dashboard, subjects, courses (create/edit/publish/delete),
  topic & lesson management within a course, enrollment approval queue,
  student management (search/suspend/reactivate/delete), analytics
  (student counts, popular courses, monthly registrations, revenue).
- Complete Supabase schema: 9 tables, indexes, triggers enforcing the
  single-teacher rule and safe enrollment/role transitions, and Row Level
  Security policies on every table.
- Full documentation set: README, INSTALL, SETUP, SUPABASE_SETUP,
  NETLIFY_DEPLOY, DATABASE, SECURITY.
- Netlify deployment config with security headers and build-time
  credential injection.

### Design
- Yellow / black / white brand theme, mobile-first responsive layout
  (320px–1440px), desktop sidebar + mobile bottom navigation for the app
  areas, accessible focus states, skeleton loading states, toast
  notifications, empty/error states throughout.
