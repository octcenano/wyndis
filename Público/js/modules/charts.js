export function initCharts() {
  const canvas = document.getElementById('moduleChart');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  if (!ctx) return;

  const modules = [
    { name: 'Firewall', checks: 15, color: '#3b82f6' },
    { name: 'Permisos', checks: 20, color: '#06b6d4' },
    { name: 'Updates', checks: 18, color: '#10b981' },
    { name: 'Defender', checks: 20, color: '#84cc16' },
    { name: 'Red', checks: 25, color: '#f59e0b' },
    { name: 'Cifrado', checks: 20, color: '#f97316' },
    { name: 'CIS', checks: 35, color: '#ef4444' },
    { name: 'Privacidad', checks: 20, color: '#8b5cf6' },
    { name: 'Resto', checks: 147, color: '#64748b' },
  ];

  const total = modules.reduce((s, m) => s + m.checks, 0);
  const dpr = window.devicePixelRatio || 1;
  const w = canvas.parentElement.clientWidth;
  const h = 200;

  canvas.width = w * dpr;
  canvas.height = h * dpr;
  canvas.style.width = `${w}px`;
  canvas.style.height = `${h}px`;
  ctx.scale(dpr, dpr);

  const padding = { top: 20, bottom: 30, left: 80, right: 20 };
  const chartW = w - padding.left - padding.right;
  const chartH = h - padding.top - padding.bottom;
  const barW = chartW / modules.length * 0.7;
  const gap = chartW / modules.length * 0.3;

  const maxChecks = Math.max(...modules.map(m => m.checks));

  ctx.clearRect(0, 0, w, h);

  ctx.fillStyle = '#64748b';
  ctx.font = '10px Inter, system-ui, sans-serif';
  ctx.textAlign = 'right';

  const ySteps = 4;
  for (let i = 0; i <= ySteps; i++) {
    const val = Math.round((maxChecks / ySteps) * i);
    const y = padding.top + chartH - (chartH / ySteps) * i;
    ctx.fillText(val, padding.left - 8, y + 3);
    ctx.strokeStyle = 'rgba(255,255,255,0.04)';
    ctx.beginPath();
    ctx.moveTo(padding.left, y);
    ctx.lineTo(w - padding.right, y);
    ctx.stroke();
  }

  modules.forEach((m, i) => {
    const x = padding.left + i * (chartW / modules.length) + gap / 2;
    const barH = (m.checks / maxChecks) * chartH;
    const y = padding.top + chartH - barH;

    const grad = ctx.createLinearGradient(x, y, x, padding.top + chartH);
    grad.addColorStop(0, m.color);
    grad.addColorStop(1, m.color + '44');
    ctx.fillStyle = grad;

    ctx.beginPath();
    const r = 3;
    ctx.moveTo(x, y + r);
    ctx.lineTo(x, padding.top + chartH);
    ctx.lineTo(x + barW, padding.top + chartH);
    ctx.lineTo(x + barW, y + r);
    ctx.quadraticCurveTo(x + barW, y, x + barW - r, y);
    ctx.lineTo(x + r, y);
    ctx.quadraticCurveTo(x, y, x, y + r);
    ctx.fill();

    ctx.fillStyle = '#64748b';
    ctx.font = '9px Inter, system-ui, sans-serif';
    ctx.textAlign = 'center';
    const label = m.name.length > 6 ? m.name.slice(0, 5) + '..' : m.name;
    ctx.fillText(`${m.checks}`, x + barW / 2, y - 4);
    ctx.fillText(label, x + barW / 2, padding.top + chartH + 16);
  });

  const totalLabel = document.getElementById('totalChecks');
  if (totalLabel) totalLabel.textContent = total;
}
