import { supabase } from '../config/supabase.js';

export async function listLessonsForTopic(topicId) {
  const { data, error } = await supabase.from('lessons').select('*').eq('topic_id', topicId).order('display_order');
  if (error) throw error;
  return data;
}

export async function getLesson(id) {
  const { data, error } = await supabase.from('lessons').select('*').eq('id', id).single();
  if (error) throw error;
  return data;
}

export async function createLesson(payload) {
  const { data, error } = await supabase.from('lessons').insert(payload).select().single();
  if (error) throw error;
  return data;
}

export async function updateLesson(id, patch) {
  const { data, error } = await supabase.from('lessons').update(patch).eq('id', id).select().single();
  if (error) throw error;
  return data;
}

export async function deleteLesson(id) {
  const { error } = await supabase.from('lessons').delete().eq('id', id);
  if (error) throw error;
}

export async function reorderLessons(orderedIds) {
  const updates = orderedIds.map((id, index) =>
    supabase.from('lessons').update({ display_order: index }).eq('id', id)
  );
  const results = await Promise.all(updates);
  const failed = results.find((r) => r.error);
  if (failed) throw failed.error;
}
