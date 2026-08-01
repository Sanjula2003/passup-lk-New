// ============================================================================
// Supabase client — single shared instance for the whole app.
// ============================================================================
// Uses the official Supabase JS client from a CDN (ESM build) so the project
// stays dependency-free (no bundler/build step required to run it).
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';
import { APP_CONFIG } from '/config/config.js';

if (!APP_CONFIG.SUPABASE_URL || APP_CONFIG.SUPABASE_URL.includes('YOUR-PROJECT')) {
  console.warn(
    '[PassUp.LK] Supabase is not configured yet. Copy config/config.example.js to ' +
    'config/config.js and add your project URL + anon key.'
  );
}

export const supabase = createClient(APP_CONFIG.SUPABASE_URL, APP_CONFIG.SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});
