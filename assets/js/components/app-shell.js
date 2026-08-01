// Renders the sidebar (desktop) + bottom nav (mobile) + topbar for the
// authenticated app area (student/* and teacher/*).
import { signOut } from '../services/auth.service.js';
import { initials } from '../utils/formatters.js';

const STUDENT_NAV = [
  { href: '/student/dashboard.html', label: 'Dashboard', icon: '🏠' },
  { href: '/student/browse-courses.html', label: 'All Courses', icon: '🛒' },
  { href: '/student/my-courses.html', label: 'My Courses', icon: '📚' },
  { href: '/student/payment-instructions.html', label: 'Payments', icon: '💳' },
  { href: '/student/profile.html', label: 'Profile', icon: '👤' },
  { href: '/student/settings.html', label: 'Settings', icon: '⚙️' },
  { href: '/index.html', label: 'View Site', icon: '🚪', id: 'logoutBtn' }
];

const TEACHER_NAV = [
  { href: '/teacher/dashboard.html', label: 'Dashboard', icon: '🏠' },
  { href: '/teacher/courses.html', label: 'Courses', icon: '📚' },
  { href: '/teacher/enrollments.html', label: 'Enrollments', icon: '📝' },
  { href: '/teacher/students.html', label: 'Students', icon: '🎓' },
  { href: '/teacher/analytics.html', label: 'Analytics', icon: '📊' },
  { href: '/teacher/settings.html', label: 'Settings', icon: '⚙️' },
  { href: '/index.html', label: 'View Site', icon: '🚪', id: 'logoutBtn' }
];

// Bottom nav only shows the 4 most important items — mobile space is tight.
const STUDENT_BOTTOM = STUDENT_NAV.slice(0, 4);
const TEACHER_BOTTOM = [TEACHER_NAV[0], TEACHER_NAV[1], TEACHER_NAV[2], TEACHER_NAV[3]];

export function renderAppShell({ role, profile, activeHref, pageTitle }) {
  const navItems = role === 'teacher' ? TEACHER_NAV : STUDENT_NAV;
  const bottomItems = role === 'teacher' ? TEACHER_BOTTOM : STUDENT_BOTTOM;
  const dashboardHref = role === 'teacher' ? '/teacher/dashboard.html' : '/student/dashboard.html';

  const navLink = (item) => `
    <a href="${item.href}" class="${activeHref === item.href ? 'active' : ''}">
      <span aria-hidden="true">${item.icon}</span> ${item.label}
    </a>`;

  const bottomLink = (item) => `
    <a href="${item.href}" class="${activeHref === item.href ? 'active' : ''}">
      <span class="icon-dot" aria-hidden="true">${item.icon}</span>
      <span>${item.label}</span>
    </a>`;

  document.body.insertAdjacentHTML('afterbegin', `
    <div class="sidebar-backdrop" id="sidebarBackdrop"></div>
    <div class="app-shell">
      <aside class="app-sidebar" id="appSidebar">
        <a href="${dashboardHref}" class="brand">
          <span class="brand__mark">P</span>
          <span>PassUp<span style="color:var(--color-primary)">.LK</span></span>
        </a>
        <nav class="sidebar-nav" aria-label="${role === 'teacher' ? 'Teacher' : 'Student'} navigation">
          ${navItems.map(navLink).join('')}
        </nav>
        <div class="sidebar-footer">
          Logged in as<br><strong style="color:#fff">${profile.full_name}</strong>
        </div>
      </aside>

      <div class="app-main">
        <header class="app-topbar">
          <div style="display:flex;align-items:center;gap:8px">
            <button class="sidebar-toggle" id="sidebarToggle" aria-label="Open menu" aria-expanded="false" aria-controls="appSidebar">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M3 12h18M3 18h18"/></svg>
            </button>
            <h4 style="margin:0">${pageTitle}</h4>
          </div>
          <div style="display:flex;align-items:center;gap:12px;">
           <!--  
            <span class="badge badge-neutral" style="text-transform:capitalize">${role}</span>
            <div class="avatar-circle" title="${profile.full_name}">${initials(profile.full_name)}</div>
            -->
            <button class="btn btn-ghost btn-sm" id="logoutBtn">Log Out</button>
          </div>
        </header>
        <main class="app-content" id="appContent"></main>
      </div>
    </div>

    <nav class="bottom-nav" aria-label="${role === 'teacher' ? 'Teacher' : 'Student'} navigation">
      ${bottomItems.map(bottomLink).join('')}
    </nav>
  `);

  document.getElementById('logoutBtn').addEventListener('click', async () => {
    await signOut();
    window.location.href = '/login.html';
  });

  const sidebar = document.getElementById('appSidebar');
  const backdrop = document.getElementById('sidebarBackdrop');
  const toggle = document.getElementById('sidebarToggle');

  function closeSidebar() {
    sidebar.classList.remove('mobile-open');
    backdrop.classList.remove('visible');
    toggle.setAttribute('aria-expanded', 'false');
  }
  function openSidebar() {
    sidebar.classList.add('mobile-open');
    backdrop.classList.add('visible');
    toggle.setAttribute('aria-expanded', 'true');
  }

  toggle.addEventListener('click', () => {
    sidebar.classList.contains('mobile-open') ? closeSidebar() : openSidebar();
  });
  backdrop.addEventListener('click', closeSidebar);
  sidebar.querySelectorAll('a').forEach((a) => a.addEventListener('click', closeSidebar));
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape') closeSidebar(); });
  window.addEventListener('resize', () => { if (window.innerWidth >= 900) closeSidebar(); });

  return document.getElementById('appContent');
}