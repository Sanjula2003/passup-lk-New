# PassUp.LK — Learning Management System

**Anyone Can Pass.**

A premium, mobile-first Learning Management System built for Sri Lankan O/L
and A/L ICT students, backed by a 100% cashback guarantee.

## Stack

| Layer          | Technology                                   |
|-----------------|-----------------------------------------------|
| Frontend        | HTML5, CSS3, Vanilla JavaScript (ES Modules)  |
| Backend         | Supabase (Auth, Postgres, Storage)            |
| Hosting         | Netlify                                        |
| Version control | Git + GitHub                                   |

No build step, no bundler, no framework — every page is plain HTML that
imports ES modules directly. This keeps the codebase approachable for a
solo teacher/developer to maintain long-term.

## Structure

```
/                     Public pages (landing, courses, auth, legal)
/student/             Student app (dashboard, course player, profile…)
/teacher/             Teacher app (course management, enrollments, analytics…)
/assets/css/          Design tokens, components, layout, per-page styles
/assets/js/config/    Supabase client bootstrap
/assets/js/services/  One module per database table — all Supabase queries live here
/assets/js/utils/     DOM helpers, validators, formatters, route guards
/assets/js/components/ Reusable UI: header, footer, app shell, cards, modals
/config/              Runtime config (config.example.js → config.js, gitignored)
/sql/                 Database schema, RLS policies, seed data
/docs/                This documentation set
```

## Roles

There are exactly two roles:

- **Teacher** — exactly one account. Manages subjects, courses, topics,
  lessons, enrollments, and students.
- **Student** — unlimited accounts. Browses courses, enrolls, and learns.

## Getting Started

1. [`INSTALL.md`](./INSTALL.md) — run the project locally
2. [`SUPABASE_SETUP.md`](./SUPABASE_SETUP.md) — set up your Supabase project, run migrations, promote the teacher account
3. [`NETLIFY_DEPLOY.md`](./NETLIFY_DEPLOY.md) — deploy to production on your custom domain
4. [`DATABASE.md`](./DATABASE.md) — schema reference
5. [`SECURITY.md`](./SECURITY.md) — security model and RLS reasoning

## The Guarantee

> "If anyone fails even after following our program, we'll return 100%
> cashback."

This is a business promise, not a software feature — but the platform
supports it by giving the teacher full visibility into every student's
progress and completion status via the Analytics dashboard.
