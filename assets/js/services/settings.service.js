import { supabase } from '../config/supabase.js';

export async function getSetting(key, fallback = null) {
  const { data, error } = await supabase.from('settings').select('value').eq('key', key).maybeSingle();
  if (error) throw error;
  return data ? data.value : fallback;
}

export async function getAllSettings() {
  const { data, error } = await supabase.from('settings').select('*');
  if (error) throw error;
  return Object.fromEntries(data.map((row) => [row.key, row.value]));
}

// Teacher-only (RLS enforced)
export async function upsertSetting(key, value) {
  const { data, error } = await supabase.from('settings').upsert({ key, value, updated_at: new Date().toISOString() }).select().single();
  if (error) throw error;
  return data;
}
