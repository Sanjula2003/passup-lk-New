export function formatCurrencyLKR(amount) {
  const value = Number(amount ?? 0);
  return new Intl.NumberFormat('en-LK', { style: 'currency', currency: 'LKR', maximumFractionDigits: 0 }).format(value);
}

export function formatDate(dateStr) {
  if (!dateStr) return '—';
  return new Intl.DateTimeFormat('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(dateStr));
}

export function formatDateTime(dateStr) {
  if (!dateStr) return '—';
  return new Intl.DateTimeFormat('en-GB', {
    day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit',
  }).format(new Date(dateStr));
}

export function initials(name = '') {
  return name.trim().split(/\s+/).slice(0, 2).map((w) => w[0]?.toUpperCase() ?? '').join('');
}

export function statusBadgeClass(status) {
  switch (status) {
    case 'approved': case 'active': case 'completed': return 'badge-success';
    case 'pending': return 'badge-warning';
    case 'rejected': case 'suspended': return 'badge-danger';
    default: return 'badge-neutral';
  }
}
