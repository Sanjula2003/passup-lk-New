import { supabase } from '../config/supabase.js';

export async function listSubjects() {
  const { data, error } = await supabase.from('subjects').select('*').order('level').order('display_order').order('name');
  if (error) throw error;
  return data;
}

export async function listSubjectsByLevel(level) {
  const { data, error } = await supabase.from('subjects').select('*').eq('level', level).order('display_order').order('name');
  if (error) throw error;
  return data;
}

export async function getSubjectBySlug(slug) {
  const { data, error } = await supabase.from('subjects').select('*').eq('slug', slug).single();
  if (error) throw error;
  return data;
}

// --- Teacher-only writes (blocked by RLS for non-teachers) -----------------
export async function createSubject(payload) {
  const { data, error } = await supabase.from('subjects').insert(payload).select().single();
  if (error) throw error;
  return data;
}

export async function updateSubject(id, patch) {
  const { data, error } = await supabase.from('subjects').update(patch).eq('id', id).select().single();
  if (error) throw error;
  return data;
}

export async function deleteSubject(id) {
  const { error } = await supabase.from('subjects').delete().eq('id', id);
  if (error) throw error;
}
