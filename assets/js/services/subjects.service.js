import { supabase } from '../config/supabase.js';

export async function listSubjects() {
  const { data, error } = await supabase.from('subjects').select('*').order('display_order');
  if (error) throw error;
  return data;
}

export async function getSubjectBySlug(slug) {
  const { data, error } = await supabase.from('subjects').select('*').eq('slug', slug).single();
  if (error) throw error;
  return data;
}

// --- Teacher-only writes (blocked by RLS for non-teachers) -----------------
export async function updateSubject(id, patch) {
  const { data, error } = await supabase.from('subjects').update(patch).eq('id', id).select().single();
  if (error) throw error;
  return data;
}
