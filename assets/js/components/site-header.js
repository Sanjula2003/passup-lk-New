// Public site header, injected into <div id="site-header"></div> on every
// public page. Renders differently depending on auth state.
import { supabase } from '../config/supabase.js';

const NAV_ITEMS = [
  { href: '/index.html', label: 'Home' },
  { href: '/courses.html', label: 'Courses' },
  { href: '/about.html', label: 'About' },
  { href: '/faq.html', label: 'FAQ' },
  { href: '/contact.html', label: 'Contact' },
];

export async function renderSiteHeader(mountEl, activeHref = '') {
  const { data: { session } } = await supabase.auth.getSession();
  let dashboardHref = '/login.html';
  if (session) {
    const { data: profile } = await supabase.from('profiles').select('role').eq('id', session.user.id).single();
    dashboardHref = profile?.role === 'teacher' ? '/teacher/dashboard.html' : '/student/dashboard.html';
  }

  const linkHTML = (href, label) =>
    `<a href="${href}" class="${activeHref === href ? 'active' : ''}">${label}</a>`;

  mountEl.innerHTML = `
    <header class="site-header">
      <div class="container site-header__row">
        <a href="/index.html" class="brand">
          <span class="brand__mark">P</span>
          <span>PassUp<span style="color:var(--color-primary-dark)">.LK</span></span>
        </a>
        <nav class="nav-links" aria-label="Primary">
          ${NAV_ITEMS.map((i) => linkHTML(i.href, i.label)).join('')}
        </nav>
        <div class="header-actions">
          ${session
            ? `<a href="${dashboardHref}" class="btn btn-dark btn-sm">Dashboard</a>`
            : `<a href="/login.html" class="btn btn-ghost btn-sm">Log In</a>
               <a href="/signup.html" class="btn btn-primary btn-sm">Sign Up</a>`
          }
          <button class="nav-toggle" id="navToggle" aria-label="Toggle menu" aria-expanded="false">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M3 12h18M3 18h18"/></svg>
          </button>
        </div>
      </div>
      <div class="container">
        <div class="mobile-menu" id="mobileMenu">
          ${NAV_ITEMS.map((i) => linkHTML(i.href, i.label)).join('')}
          ${session
            ? `<a href="${dashboardHref}">Dashboard</a>`
            : `<a href="/login.html">Log In</a><a href="/signup.html">Sign Up</a>`
          }
        </div>
      </div>
    </header>`;

  const toggle = mountEl.querySelector('#navToggle');
  const menu = mountEl.querySelector('#mobileMenu');
  toggle.addEventListener('click', () => {
    const isOpen = menu.classList.toggle('open');
    toggle.setAttribute('aria-expanded', String(isOpen));
  });
}
