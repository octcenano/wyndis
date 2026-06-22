export function initTheme() {
  const toggle = document.getElementById('themeToggle');
  if (!toggle) return;

  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  const stored = localStorage.getItem('wyndis-theme');

  if (stored === 'light') {
    document.documentElement.setAttribute('data-theme', 'light');
  }

  toggle.addEventListener('click', () => {
    const isDark = document.documentElement.getAttribute('data-theme') !== 'light';
    if (isDark) {
      document.documentElement.setAttribute('data-theme', 'light');
      localStorage.setItem('wyndis-theme', 'light');
    } else {
      document.documentElement.removeAttribute('data-theme');
      localStorage.setItem('wyndis-theme', 'dark');
    }
  });
}
