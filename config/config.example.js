// ============================================================================
// PassUp.LK — Runtime configuration
// ============================================================================
// Copy this file to `config/config.js` (which is gitignored) and fill in
// your Supabase project's URL and PUBLIC anon key.
//
// IMPORTANT: the anon key is safe to expose in frontend code — it is
// designed for this. NEVER put the service_role key here or anywhere in
// frontend code; it bypasses Row Level Security entirely.
//
// In production (Netlify), these values are injected at build time from
// environment variables — see docs/NETLIFY_DEPLOY.md.
// ============================================================================

export const APP_CONFIG = {
  SUPABASE_URL: 'https://YOUR-PROJECT-REF.supabase.co',
  SUPABASE_ANON_KEY: 'YOUR-SUPABASE-ANON-PUBLIC-KEY',

  // Site-wide constants that don't need to live in the database
  SITE_NAME: 'PassUp.LK',
  SITE_TAGLINE: 'Anyone Can Pass',
  SUPPORT_WHATSAPP_LINK: 'https://wa.me/94700000000',
};
