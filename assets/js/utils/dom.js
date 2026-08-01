// Small DOM helpers used across every page script.

export const qs = (sel, root = document) => root.querySelector(sel);
export const qsa = (sel, root = document) => Array.from(root.querySelectorAll(sel));

export function el(tag, attrs = {}, children = []) {
  const node = document.createElement(tag);
  for (const [key, value] of Object.entries(attrs)) {
    if (key === 'class') node.className = value;
    else if (key === 'html') node.innerHTML = value;
    else if (key.startsWith('on') && typeof value === 'function') {
      node.addEventListener(key.slice(2).toLowerCase(), value);
    } else if (value !== null && value !== undefined) {
      node.setAttribute(key, value);
    }
  }
  for (const child of [].concat(children)) {
    if (child === null || child === undefined) continue;
    node.append(child instanceof Node ? child : document.createTextNode(String(child)));
  }
  return node;
}

export function escapeHTML(str = '') {
  return String(str)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

export function setLoading(container, isLoading, skeletonHTML = '<div class="skeleton" style="height:120px"></div>') {
  if (isLoading) container.innerHTML = skeletonHTML;
}

export function renderEmptyState(container, { icon = '📭', title = 'Nothing here yet', message = '' } = {}) {
  container.innerHTML = `
    <div class="state-panel">
      <div class="state-panel__icon" aria-hidden="true">${icon}</div>
      <h3>${escapeHTML(title)}</h3>
      <p>${escapeHTML(message)}</p>
    </div>`;
}

export function renderErrorState(container, message = 'Something went wrong. Please try again.') {
  container.innerHTML = `
    <div class="state-panel">
      <div class="state-panel__icon" aria-hidden="true">⚠️</div>
      <h3>Couldn't load this</h3>
      <p>${escapeHTML(message)}</p>
    </div>`;
}
