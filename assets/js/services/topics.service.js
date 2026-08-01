import { supabase } from '../config/supabase.js';

export async function listTopicsForCourse(courseId) {
  const { data, error } = await supabase.from('topics').select('*').eq('course_id', courseId).order('display_order');
  if (error) throw error;
  return data;
}

export async function createTopic(payload) {
  const { data, error } = await supabase.from('topics').insert(payload).select().single();
  if (error) throw error;
  return data;
}

export async function updateTopic(id, patch) {
  const { data, error } = await supabase.from('topics').update(patch).eq('id', id).select().single();
  if (error) throw error;
  return data;
}

export async function deleteTopic(id) {
  const { error } = await supabase.from('topics').delete().eq('id', id);
  if (error) throw error;
}

export async function reorderTopics(orderedIds) {
  // orderedIds: array of topic ids in the desired display order
  const updates = orderedIds.map((id, index) =>
    supabase.from('topics').update({ display_order: index }).eq('id', id)
  );
  const results = await Promise.all(updates);
  const failed = results.find((r) => r.error);
  if (failed) throw failed.error;
}
