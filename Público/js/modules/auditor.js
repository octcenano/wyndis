export function initAuditor() {
  const simItems = document.querySelectorAll('.sim-item');
  simItems.forEach(item => {
    const checkbox = item.querySelector('input[type="checkbox"]');
    checkbox?.addEventListener('change', () => {
      item.classList.toggle('active', checkbox.checked);
      recalculateScore();
    });
    item.addEventListener('click', (e) => {
      if (e.target !== checkbox) {
        checkbox.checked = !checkbox.checked;
        item.classList.toggle('active', checkbox.checked);
        recalculateScore();
      }
    });
  });

  recalculateScore();
}

function recalculateScore() {
  const simItems = document.querySelectorAll('.sim-item');
  const critPts = { 'crit': 5, 'warn': 2 };
  let deductions = 0;
  let critCount = 0;
  let warnCount = 0;

  simItems.forEach(item => {
    const checkbox = item.querySelector('input[type="checkbox"]');
    if (!checkbox?.checked) return;

    const badge = item.querySelector('.sim-item-points');
    const type = badge?.classList.contains('crit') ? 'crit' : 'warn';
    deductions += critPts[type];
    if (type === 'crit') critCount++;
    else warnCount++;
  });

  let score = Math.max(0, 100 - deductions);
  score = parseFloat(score.toFixed(1));

  const scoreEl = document.getElementById('simScore');
  const labelEl = document.getElementById('simLabel');
  const descEl = document.getElementById('simDesc');
  const barEl = document.getElementById('simBar');

  if (scoreEl) scoreEl.innerHTML = `${score} <span class="total">/ 100</span>`;
  if (barEl) barEl.style.width = `${score}%`;

  const grade = getGrade(score);
  if (labelEl) {
    labelEl.textContent = grade.label;
    labelEl.style.color = grade.color;
  }
  if (descEl) descEl.textContent = grade.desc;
}

function getGrade(score) {
  if (score >= 90) return { label: 'Excelente', color: '#10b981', desc: 'Configuracion de seguridad optima.' };
  if (score >= 75) return { label: 'Bueno', color: '#3b82f6', desc: 'Cumple la mayoria de las medidas basicas.' };
  if (score >= 50) return { label: 'Regular', color: '#f59e0b', desc: 'Se recomiendan mejoras importantes.' };
  if (score >= 25) return { label: 'Malo', color: '#f97316', desc: 'Riesgos activos de seguridad.' };
  return { label: 'Critico', color: '#ef4444', desc: 'Fallos severos - accion urgente requerida.' };
}
