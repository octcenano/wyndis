import { initDownloader } from './modules/downloader.js';
import { initAuditor } from './modules/auditor.js';
import { initCharts } from './modules/charts.js';
import { initTerminal } from './modules/terminal.js';
import { initTheme } from './modules/theme.js';

document.addEventListener('DOMContentLoaded', () => {
  initDownloader();
  initAuditor();
  initCharts();
  initTerminal();
  initTheme();

  document.querySelectorAll('.copy-btn').forEach(btn => {
    btn.addEventListener('click', function() {
      const codeBlock = this.closest('.code-block');
      const textEl = codeBlock?.querySelector('.code-text');
      if (!textEl) return;

      const text = textEl.textContent.trim();
      navigator.clipboard.writeText(text).then(() => {
        this.textContent = 'Copiado';
        this.classList.add('copied');
        setTimeout(() => {
          this.textContent = 'Copiar';
          this.classList.remove('copied');
        }, 2000);
      });
    });
  });

  const counters = document.querySelectorAll('.stat-number');
  counters.forEach(counter => {
    const target = parseInt(counter.getAttribute('data-target') || counter.textContent.replace(/[^0-9]/g, ''));
    if (!target) return;
    counter.textContent = '0';
    const step = Math.ceil(target / 30);
    let current = 0;
    const interval = setInterval(() => {
      current += step;
      if (current >= target) {
        current = target;
        clearInterval(interval);
      }
      counter.textContent = current + (counter.getAttribute('data-suffix') || '');
    }, 50);
  });
});
