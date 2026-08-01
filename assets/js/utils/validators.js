// Client-side validation helpers. These NEVER replace server-side checks —
// Supabase RLS and NOT NULL/CHECK constraints are the real enforcement layer.
// This module only exists to give the user fast, friendly feedback.

export function isValidEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(value).trim());
}

export function isStrongPassword(value) {
  // Minimum 8 chars, at least one letter and one number.
  return typeof value === 'string' && value.length >= 8 && /[A-Za-z]/.test(value) && /\d/.test(value);
}

export function isNonEmpty(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

export function isYouTubeId(value) {
  return /^[A-Za-z0-9_-]{11}$/.test(String(value).trim());
}

export function isUrl(value) {
  try {
    new URL(value);
    return true;
  } catch {
    return false;
  }
}

export function applyFieldError(inputEl, message) {
  inputEl.classList.add('invalid');
  let hint = inputEl.parentElement.querySelector('.field-error');
  if (!hint) {
    hint = document.createElement('div');
    hint.className = 'field-error';
    inputEl.parentElement.appendChild(hint);
  }
  hint.textContent = message;
}

export function clearFieldError(inputEl) {
  inputEl.classList.remove('invalid');
  const hint = inputEl.parentElement.querySelector('.field-error');
  if (hint) hint.remove();
}
