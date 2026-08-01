// Lightweight analytics computed client-side from a handful of aggregate
// queries. Fine at this scale (single teacher, one institution); if this
// ever needs to scale further, move these into Postgres views/RPCs.
import { supabase } from '../config/supabase.js';

export async function getDashboardStats() {
  const [{ count: totalStudents }, { count: activeStudents }, { count: pendingEnrollments }, { count: totalCourses }, { data: payments }] = await Promise.all([
    supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'student'),
    supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'student').eq('status', 'active'),
    supabase.from('enrollments').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
    supabase.from('courses').select('id', { count: 'exact', head: true }),
    supabase.from('payments').select('amount'),
  ]);

  const revenue = (payments ?? []).reduce((sum, p) => sum + Number(p.amount || 0), 0);

  return { totalStudents: totalStudents ?? 0, activeStudents: activeStudents ?? 0, pendingEnrollments: pendingEnrollments ?? 0, totalCourses: totalCourses ?? 0, revenue };
}

export async function getPopularCourses(limit = 5) {
  const { data, error } = await supabase
    .from('enrollments')
    .select('course_id, courses(title)')
    .eq('status', 'approved');
  if (error) throw error;
  const counts = new Map();
  for (const row of data) {
    const key = row.course_id;
    const title = row.courses?.title ?? 'Untitled';
    counts.set(key, { title, count: (counts.get(key)?.count ?? 0) + 1 });
  }
  return Array.from(counts.values()).sort((a, b) => b.count - a.count).slice(0, limit);
}

export async function getMonthlyRegistrations(months = 6) {
  const since = new Date();
  since.setMonth(since.getMonth() - months);
  const { data, error } = await supabase
    .from('profiles')
    .select('created_at')
    .eq('role', 'student')
    .gte('created_at', since.toISOString());
  if (error) throw error;

  const buckets = {};
  for (const row of data) {
    const d = new Date(row.created_at);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
    buckets[key] = (buckets[key] ?? 0) + 1;
  }
  return buckets;
}
