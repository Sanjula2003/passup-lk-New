# Deploy to Netlify

## 1. Push to GitHub

```bash
git init
git add .
git commit -m "Initial PassUp.LK LMS"
git branch -M main
git remote add origin https://github.com/<your-org>/passup-lk.git
git push -u origin main
```

## 2. Create the Netlify site

1. [app.netlify.com](https://app.netlify.com) → **Add new site → Import an
   existing project**.
2. Connect your GitHub repo.
3. Build settings:
   - **Build command**: leave as defined in `netlify.toml` (it generates
     `config/config.js` from environment variables at build time).
   - **Publish directory**: `.` (the repo root — also set in
     `netlify.toml`).

## 3. Set environment variables

In **Site configuration → Environment variables**, add:

| Key                      | Value                                         |
|---------------------------|-----------------------------------------------|
| `SUPABASE_URL`             | Your Supabase project URL                     |
| `SUPABASE_ANON_KEY`        | Your Supabase anon/public API key             |
| `SUPPORT_WHATSAPP_LINK`    | e.g. `https://wa.me/94700000000`              |

**Never set `SUPABASE_SERVICE_ROLE_KEY` here** — it's not needed by this
frontend and must never be shipped to a browser.

The build command in `netlify.toml` writes these into `config/config.js`
during the build, so you never commit real credentials to Git.

## 4. Deploy

Trigger a deploy (push to `main`, or **Trigger deploy** in the Netlify UI).
Netlify will run the build command and publish the site.

## 5. Connect your custom domain (passup.lk)

1. **Domain management → Add a domain** → enter `passup.lk`.
2. At your domain registrar, either:
   - Point nameservers to Netlify DNS (recommended, simplest), or
   - Add the A/ALIAS and CNAME records Netlify shows you if keeping your
     current DNS provider.
3. Netlify automatically provisions a free HTTPS certificate (Let's
   Encrypt) once DNS propagates — usually within a few minutes to a few
   hours.
4. Confirm **Force HTTPS** is enabled under **Domain management → HTTPS**.

## 6. Update Supabase redirect URLs

Back in Supabase → **Authentication → URL Configuration**, add
`https://passup.lk/*` to the allowed redirect URLs (see
`SUPABASE_SETUP.md` step 3) — otherwise email verification and password
reset links will fail in production.

## 7. Verify production

- [ ] Visit `https://passup.lk` — loads over HTTPS with a valid certificate
- [ ] Sign up with a real email — verification email arrives and its link
      redirects back to `https://passup.lk/login.html?verified=1`
- [ ] Log in as the teacher — lands on `/teacher/dashboard.html`
- [ ] Log in as a student — lands on `/student/dashboard.html`
- [ ] Security headers present — check via
      [securityheaders.com](https://securityheaders.com)
