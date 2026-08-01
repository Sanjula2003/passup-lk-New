# Project Setup Overview

This is the high-level checklist. Each step links to its detailed guide.

1. **Clone the project.**
2. **Create a Supabase project** and run the migrations — see
   [`SUPABASE_SETUP.md`](./SUPABASE_SETUP.md).
3. **Configure local credentials**:
   ```bash
   cp config/config.example.js config/config.js
   # edit config/config.js with your Supabase URL + anon key
   ```
4. **Run locally** — see [`INSTALL.md`](./INSTALL.md).
5. **Create the teacher account** by signing up once through the UI, then
   promoting it via SQL (`SUPABASE_SETUP.md`, step 5).
6. **Add real subjects' course content** from the Teacher panel:
   Courses → New Course → Manage Content → add Topics → add Lessons
   (YouTube video ID + optional PDF link per lesson) → Publish.
7. **Set payment details** in Teacher → Settings (WhatsApp number, bank
   account, cashback policy text) — these populate the public Payment
   Instructions page students see after enrolling.
8. **Deploy to Netlify** — see [`NETLIFY_DEPLOY.md`](./NETLIFY_DEPLOY.md).

## Day-to-day teacher workflow

```
New course  →  Add topics  →  Add lessons  →  Publish course
Student enrolls  →  sends WhatsApp payment slip  →  Teacher approves in Enrollments
Student watches lessons, tracks progress, downloads PDFs
```
