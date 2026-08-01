import { supabase } from '../config/supabase.js';

export async function getProgressForCourse(studentId, lessonIds) {
  if (!lessonIds.length) return [];
  const { data, error } = await supabase
    .from('lesson_progress')
    .select('*')
    .eq('student_id', studentId)
    .in('lesson_id', lessonIds);
  if (error) throw error;
  return data;
}

export async function markLessonComplete(studentId, lessonId) {
  const { data, error } = await supabase
    .from('lesson_progress')
    .upsert(
      { student_id: studentId, lesson_id: lessonId, is_completed: true, completed_at: new Date().toISOString(), last_watched_at: new Date().toISOString() },
      { onConflict: 'student_id,lesson_id' }
    )
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function touchLessonWatched(studentId, lessonId) {
  const { error } = await supabase
    .from('lesson_progress')
    .upsert(
      { student_id: studentId, lesson_id: lessonId, last_watched_at: new Date().toISOString() },
      { onConflict: 'student_id,lesson_id', ignoreDuplicates: false }
    );
  if (error) throw error;
}

export function computeCoursePercent(lessons, progressRows) {
  if (!lessons.length) return 0;
  const doneSet = new Set(progressRows.filter((p) => p.is_completed).map((p) => p.lesson_id));
  const done = lessons.filter((l) => doneSet.has(l.id)).length;
  return Math.round((done / lessons.length) * 100);
}
