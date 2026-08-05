import { supabase } from '../config/supabase.js';

export async function listPublishedCourses({ subjectSlug = null, level = null } = {}) {
  let query = supabase
    .from('courses')
    .select('*, subjects!inner(id, name, slug, level)')
    .eq('is_published', true)
    .order('display_order');
  if (subjectSlug) query = query.eq('subjects.slug', subjectSlug);
  if (level) query = query.eq('subjects.level', level);
  const { data, error } = await query;
  if (error) throw error;
  return data;
}

export async function getCourseBySlug(slug) {
  const { data, error } = await supabase
    .from('courses')
    .select('*, subjects(id, name, slug, level)')
    .eq('slug', slug)
    .single();
  if (error) throw error;
  return data;
}

export async function getCourseWithCurriculum(courseId) {
  const { data, error } = await supabase
    .from('courses')
    .select('*, topics(*, lessons(*))')
    .eq('id', courseId)
    .order('display_order', { referencedTable: 'topics' })
    .order('display_order', { referencedTable: 'topics.lessons' })
    .single();
  if (error) throw error;
  return data;
}

export async function getPublicCurriculum(courseId) {
  // Calls the get_public_curriculum() Postgres function (migration 0006) —
  // returns only safe preview data (titles, ordering) for published
  // lessons, with no enrollment required. Never returns video/pdf links.
  const { data, error } = await supabase.rpc('get_public_curriculum', { p_course_id: courseId });
  if (error) throw error;

  // Group the flat rows into { id, title, display_order, lessons: [...] } —
  // the same shape course.html already expects from getCourseWithCurriculum.
  const topicsMap = new Map();
  for (const row of data) {
    if (!topicsMap.has(row.topic_id)) {
      topicsMap.set(row.topic_id, { id: row.topic_id, title: row.topic_title, display_order: row.topic_order, lessons: [] });
    }
    topicsMap.get(row.topic_id).lessons.push({ id: row.lesson_id, title: row.lesson_title, display_order: row.lesson_order });
  }
  return Array.from(topicsMap.values()).sort((a, b) => a.display_order - b.display_order);
}

// --- Teacher panel (all courses, including drafts) --------------------------
export async function listAllCoursesForTeacher() {
  const { data, error } = await supabase
    .from('courses')
    .select('*, subjects(name, level), topics(count)')
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data;
}

export async function createCourse(payload) {
  const { data, error } = await supabase.from('courses').insert(payload).select().single();
  if (error) throw error;
  return data;
}

export async function updateCourse(id, patch) {
  const { data, error } = await supabase.from('courses').update(patch).eq('id', id).select().single();
  if (error) throw error;
  return data;
}

export async function deleteCourse(id) {
  const { error } = await supabase.from('courses').delete().eq('id', id);
  if (error) throw error;
}