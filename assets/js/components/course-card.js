import { formatCurrencyLKR } from '../utils/formatters.js';
import { escapeHTML } from '../utils/dom.js';

export function courseCardHTML(course, { ctaLabel = 'View Course', ctaHref = null } = {}) {
  const href = ctaHref ?? `/course.html?slug=${encodeURIComponent(course.slug)}`;
  const subjectName = course.subjects?.name ?? '';
  return `
    <article class="card card-hover course-card">
      <a href="${href}" class="course-card__thumb" aria-hidden="true">
        ${course.thumbnail_url
          ? `<img src="${escapeHTML(course.thumbnail_url)}" alt="" style="width:100%;height:100%;object-fit:cover" />`
          : `<span>${escapeHTML(subjectName || 'Course')}</span>`}
      </a>
      <div class="course-card__body">
        ${subjectName ? `<span class="badge badge-neutral">${escapeHTML(subjectName)}</span>` : ''}
        <h4 class="course-card__title">${escapeHTML(course.title)}</h4>
        <p class="course-card__meta">${escapeHTML(course.description ?? '').slice(0, 90)}${(course.description ?? '').length > 90 ? '…' : ''}</p>
        <div class="course-card__footer">
          <span class="course-card__price">${formatCurrencyLKR(course.price)}</span>
          <a href="${href}" class="btn btn-primary btn-sm">${ctaLabel}</a>
        </div>
      </div>
    </article>`;
}
