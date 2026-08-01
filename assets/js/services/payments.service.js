import { supabase } from '../config/supabase.js';

export async function recordPayment({ enrollmentId, amount, method, slipUrl, notes }) {
  const { data, error } = await supabase
    .from('payments')
    .insert({
      enrollment_id: enrollmentId,
      amount,
      method,
      slip_url: slipUrl,
      notes,
      verified_by: (await supabase.auth.getUser()).data.user?.id,
      verified_at: new Date().toISOString(),
    })
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function listPaymentsForEnrollment(enrollmentId) {
  const { data, error } = await supabase.from('payments').select('*').eq('enrollment_id', enrollmentId).order('created_at', { ascending: false });
  if (error) throw error;
  return data;
}

export async function listAllPayments() {
  const { data, error } = await supabase
    .from('payments')
    .select('*, enrollments(course_id, courses(title), profiles!enrollments_student_id_fkey(full_name))')
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data;
}
