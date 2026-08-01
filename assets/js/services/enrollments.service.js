import { supabase } from '../config/supabase.js';

// --- Student actions --------------------------------------------------------
export async function requestEnrollment({ studentId, courseId, paymentReference }) {
  const { data, error } = await supabase
    .from('enrollments')
    .insert({ student_id: studentId, course_id: courseId, payment_reference: paymentReference })
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function attachPaymentSlip(enrollmentId, slipUrl) {
  const { data, error } = await supabase
    .from('enrollments')
    .update({ payment_slip_url: slipUrl })
    .eq('id', enrollmentId)
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function listMyEnrollments(studentId) {
  const { data, error } = await supabase
    .from('enrollments')
    .select('*, courses(*, subjects(name, slug))')
    .eq('student_id', studentId)
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data;
}

export async function getMyEnrollmentForCourse(studentId, courseId) {
  const { data, error } = await supabase
    .from('enrollments')
    .select('*')
    .eq('student_id', studentId)
    .eq('course_id', courseId)
    .maybeSingle();
  if (error) throw error;
  return data;
}

// --- Teacher actions ---------------------------------------------------------
export async function listAllEnrollments({ status = null } = {}) {
  let query = supabase
    .from('enrollments')
    .select('*, profiles!enrollments_student_id_fkey(full_name, email), courses(title)')
    .order('created_at', { ascending: false });
  if (status) query = query.eq('status', status);
  const { data, error } = await query;
  if (error) throw error;
  return data;
}

export async function approveEnrollment(id) {
  const { data, error } = await supabase.from('enrollments').update({ status: 'approved' }).eq('id', id).select().single();
  if (error) throw error;
  return data;
}

export async function rejectEnrollment(id, reason = '') {
  const { data, error } = await supabase
    .from('enrollments')
    .update({ status: 'rejected', rejection_reason: reason })
    .eq('id', id)
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function suspendEnrollment(id) {
  const { data, error } = await supabase.from('enrollments').update({ status: 'suspended' }).eq('id', id).select().single();
  if (error) throw error;
  return data;
}
