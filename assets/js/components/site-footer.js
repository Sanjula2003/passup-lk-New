export function renderSiteFooter(mountEl) {
  const year = new Date().getFullYear();
  mountEl.innerHTML = `
    <footer class="site-footer">
      <div class="container">
        <div class="footer-grid">
          <div>
            <div class="brand" style="color:#fff;margin-bottom:12px;">
              <span class="brand__mark">P</span>
              <span>PassUp<span style="color:var(--color-primary)">.LK</span></span>
            </div>
            <p>Premium learning for O/L and A/L ICT students in Sri Lanka. Anyone Can Pass.</p>
          </div>
          <div>
            <h4>Explore</h4>
            <div class="footer-links">
              <a href="/courses.html">Courses</a>
              <a href="/about.html">About Us</a>
              <a href="/faq.html">FAQ</a>
              <a href="/contact.html">Contact</a>
            </div>
          </div>
          <div>
            <h4>Account</h4>
            <div class="footer-links">
              <a href="/login.html">Log In</a>
              <a href="/signup.html">Sign Up</a>
              <a href="/forgot-password.html">Forgot Password</a>
            </div>
          </div>
          <div>
            <h4>Legal</h4>
            <div class="footer-links">
              <a href="/privacy.html">Privacy Policy</a>
              <a href="/terms.html">Terms of Service</a>
            </div>
          </div>
        </div>
        <div class="footer-bottom">
          <span>© ${year} PassUp.LK. All rights reserved.</span>
          <span>Made for Sri Lankan ICT students 🇱🇰</span>
        </div>
      </div>
    </footer>`;
}
