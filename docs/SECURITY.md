# Security Model

## The core principle

**The frontend is never trusted.** Every authorization decision — who can
read or write which row — is enforced by PostgreSQL Row Level Security
policies in Supabase, not by JavaScript in the browser. Client-side route
guards (`assets/js/utils/guards.js`) exist purely for UX (redirecting a
logged-out visitor to `/login.html`); a malicious user bypassing them
entirely would still be blocked by RLS on every table.

See `/sql/migrations/0005_rls_policies.sql` and `/docs/DATABASE.md` for the
full policy set.

## Authentication

- Supabase Auth handles password hashing, session issuance, and refresh
  tokens — none of that is implemented in this codebase.
- Email verification is required before login (enforced in Supabase
  Auth settings — see `SUPABASE_SETUP.md`).
- Sessions persist via Supabase's own secure storage mechanism
  (`persistSession: true` in `assets/js/config/supabase.js`) and refresh
  automatically.
- Passwords are validated client-side for UX (min 8 characters, a letter
  and a number) but the real minimum-strength enforcement is Supabase
  Auth's own password policy — increase it in the dashboard if you want a
  stricter rule.

## Authorization

- Two roles only: `teacher` (exactly one, enforced by a database trigger)
  and `student`.
- A student can never promote themselves — role/status changes on their
  own `profiles` row are blocked by the `prevent_self_role_escalation`
  trigger regardless of what the frontend sends.
- Lesson content (the actual paid product) is gated at the database level:
  a `lessons` row is only readable by a student if it's published **and**
  they hold an `approved` enrollment in its parent course. This means even
  a compromised or modified frontend cannot leak lesson content to
  unauthorized users.

## Secrets

- Only the Supabase **anon/public** key ever appears in frontend code —
  by design, this key is safe to expose and is meaningless without RLS
  policies granting access.
- The **service_role** key is never used anywhere in this project. If you
  ever need server-side privileged operations (e.g. fully deleting an
  `auth.users` row, which the frontend cannot do), implement it as a
  Supabase Edge Function that holds the service_role key server-side —
  never in a static site.
- `config/config.js` (containing your real project URL + anon key) is
  gitignored; only `config/config.example.js` (placeholders) is committed.

## Transport & headers

`_headers` (read by Netlify) sets, on every response:
- `Content-Security-Policy` — restricts script/style/frame sources to
  Supabase, jsDelivr (for the Supabase client), Google Fonts, and
  YouTube's privacy-enhanced embed domain.
- `X-Frame-Options: SAMEORIGIN` — prevents the site being framed elsewhere
  (clickjacking protection).
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Strict-Transport-Security` — forces HTTPS for a year, including
  subdomains.

## Input handling

- All user-generated text rendered into the DOM goes through
  `escapeHTML()` (`assets/js/utils/dom.js`) to prevent stored/reflected
  XSS from names, descriptions, etc.
- All database queries use the Supabase client's parameterized query
  builder — there is no raw SQL string concatenation anywhere in the
  frontend, eliminating SQL injection risk from user input.

## Video protection — an honest limitation

Lessons embed **unlisted YouTube videos** via `youtube-nocookie.com` with
minimal branding, `rel=0`, `disablekb=1` (no keyboard shortcuts), and
`iv_load_policy=3` (no annotation cards). The player area also blocks
right-click and drag events, and a small invisible overlay sits over the
embed's video title (top strip) — its one remaining live link to
youtube.com — so a casual click doesn't carry the student off the
platform. The bottom-right corner (YouTube logo) is deliberately left
unblocked because it overlaps the fullscreen button; blocking clicks
there disabled fullscreen along with the logo link. Actual playback
controls (play/pause, seek, volume, fullscreen) are untouched.

**This is not real DRM.** A sufficiently motivated user can still capture
YouTube video content through screen recording or browser developer
tools — no embed-based protection scheme can prevent this, and PassUp.LK
does not claim otherwise. The Terms of Service (`terms.html`) prohibits
redistribution as the enforcement mechanism for this limitation, backed by
the ability to suspend an account.

## Known follow-ups for a production launch

- Add rate limiting on the Supabase project (Auth → Rate Limits) to
  reduce signup/login abuse.
- Consider Supabase's CAPTCHA integration on signup if bot signups become
  an issue.
- Rotate the anon key if it's ever accidentally committed with real
  production values before this `.gitignore` was in place.
