// Global toast notification system. A single <div class="toast-region"> is
// created lazily and reused for the lifetime of the page.

let region = null;

function getRegion() {
  if (!region) {
    region = document.createElement('div');
    region.className = 'toast-region';
    region.setAttribute('role', 'status');
    region.setAttribute('aria-live', 'polite');
    document.body.appendChild(region);
  }
  return region;
}

export function showToast(message, { type = 'info', duration = 4000 } = {}) {
  const node = document.createElement('div');
  node.className = `toast toast-${type}`;
  node.textContent = message;
  getRegion().appendChild(node);
  setTimeout(() => {
    node.style.opacity = '0';
    node.style.transition = 'opacity 200ms ease';
    setTimeout(() => node.remove(), 220);
  }, duration);
}

export const toastSuccess = (msg, opts) => showToast(msg, { ...opts, type: 'success' });
export const toastError = (msg, opts) => showToast(msg, { ...opts, type: 'danger' });
export const toastInfo = (msg, opts) => showToast(msg, { ...opts, type: 'info' });
