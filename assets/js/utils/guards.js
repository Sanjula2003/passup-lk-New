// Route guards for the app shell pages (student/*, teacher/*).
//
// IMPORTANT: these guards only control the client-side UI (hiding a page
// and redirecting). They are a UX convenience, NOT the security boundary —
// the real authorization is enforced by Supabase Row Level Security on
// every table (see /sql/migrations/0005_rls_policies.sql). Even if someone
// bypassed this guard entirely, the database would refuse any query or
// write they're not allowed to perform.

import { supabase } from '../config/supabase.js';

/**
 * Resolves the current session + profile, or redirects to /login.html.
 * Call at the top of every student/* and teacher/* page script.
 */
export async function requireAuth() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) {
    window.location.href = '/login.html?redirect=' + encodeURIComponent(window.location.pathname);
    return null;
  }
  const { data: profile, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', session.user.id)
    .single();

  if (error || !profile) {
    window.location.href = '/login.html';
    return null;
  }
  if (profile.status === 'suspended') {
    await supabase.auth.signOut();
    window.location.href = '/login.html?suspended=1';
    return null;
  }
  return { session, profile };
}

/** Call on teacher/* pages only. Redirects students to their dashboard. */
export async function requireTeacher() {
  const result = await requireAuth();
  if (!result) return null;
  if (result.profile.role !== 'teacher') {
    window.location.href = '/student/dashboard.html';
    return null;
  }
  return result;
}

/** Call on student/* pages only. Redirects the teacher to their dashboard. */
export async function requireStudent() {
  const result = await requireAuth();
  if (!result) return null;
  if (result.profile.role !== 'student') {
    window.location.href = '/teacher/dashboard.html';
    return null;
  }
  return result;
}

/** For public auth pages (login/signup) — bounce an already-logged-in user home. */
export async function redirectIfAuthenticated() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return;
  const { data: profile } = await supabase.from('profiles').select('role').eq('id', session.user.id).single();
  window.location.href = profile?.role === 'teacher' ? '/teacher/dashboard.html' : '/student/dashboard.html';
}
