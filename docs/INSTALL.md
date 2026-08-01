# Install & Run Locally

PassUp.LK has **no build step** — it's plain HTML/CSS/JS. You only need a
static file server, because ES Modules and `fetch()` don't work reliably
from `file://` URLs.

## Prerequisites

- Any static file server. The simplest options:
  - Python 3 (usually pre-installed): `python3 -m http.server`
  - Node's `http-server` or `serve` package
  - The VS Code "Live Server" extension

## Steps

1. Clone or download the project.
2. Copy the config template and fill in your Supabase credentials
   (see [`SUPABASE_SETUP.md`](./SUPABASE_SETUP.md) if you haven't created a
   project yet):
   ```bash
   cp config/config.example.js config/config.js
   ```
   Edit `config/config.js` and set `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
3. Serve the project root:
   ```bash
   # Option A — Python
   python3 -m http.server 5500

   # Option B — Node (npx, no install needed)
   npx serve . -l 5500
   ```
4. Open `http://localhost:5500/index.html` in your browser.

## Notes

- `config/config.js` is gitignored — never commit real Supabase keys.
- The site is a **multi-page app**: every `.html` file is its own entry
  point. There's no client-side router to configure.
- Because there's no build step, any code edit is visible on a simple
  browser refresh.
