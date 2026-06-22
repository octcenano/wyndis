export function initTerminal() {
  const simRunBtn = document.getElementById('simRunAudit');
  if (simRunBtn) {
    simRunBtn.addEventListener('click', runSimulatedAudit);
  }
}

function runSimulatedAudit() {
  const output = document.getElementById('terminalOutput');
  if (!output) return;

  const lines = [
    { text: 'Wyndis v2.0 - Auditor de seguridad profesional', class: '' },
    { text: 'Licencia MIT | 27 modulos | 300+ checks', class: '' },
    { text: '', class: '' },
    { text: '== 1. Informacion del sistema ==', class: '' },
    { text: '  [ INFO ] Equipo: DESKTOP-ABC123', class: '' },
    { text: '  [ INFO ] SO: Windows 11 Pro (10.0.22631)', class: '' },
    { text: '  [ OK ] Tiempo de actividad razonable.', class: 'ok' },
    { text: '', class: '' },
    { text: '== 2. Firewall de Windows ==', class: '' },
    { text: '  [ OK ] Perfil Domain: activo', class: 'ok' },
    { text: '  [ OK ] Perfil Private: activo', class: 'ok' },
    { text: '  [ OK ] Perfil Public: activo', class: 'ok' },
    { text: '  [ INFO ] Puertos en escucha: 18', class: '' },
    { text: '', class: '' },
    { text: '== 9. Auditoria de Red ==', class: '' },
    { text: '  [ OK ] SMBv1 deshabilitado.', class: 'ok' },
    { text: '  [ WARN ] Puerto 445 (SMB) escuchando', class: 'warn' },
    { text: '  [ SUGG ] Activa DNS-over-HTTPS en navegador.', class: 'sugg' },
    { text: '', class: '' },
    { text: '== 10. Auditoria de Cifrado ==', class: '' },
    { text: '  [ OK ] TPM detectado y habilitado.', class: 'ok' },
    { text: '  [ CRIT ] BitLocker NO activo en C:', class: 'crit' },
    { text: '', class: '' },
    { text: '== Resumen y puntuacion ==', class: '' },
    { text: '  ==============================================', class: '' },
    { text: '    PUNTUACION DE SEGURIDAD: 78 / 100', class: '' },
    { text: '    (Bueno)', class: '' },
    { text: '  ==============================================', class: '' },
    { text: '  [ WARN ] Se encontraron 10 advertencia(s).', class: 'warn' },
    { text: '', class: '' },
    { text: '  PDF generado: Wyndis-Informe-2026-06-22.pdf', class: '' },
    { text: '  Auditoria completada en 14.2 segundos.', class: '' },
    { text: '  Web: wyndis-download-ce9eb.web.app', class: '' },
  ];

  output.innerHTML = '';
  let i = 0;

  function typeLine() {
    if (i >= lines.length) {
      const cursor = document.createElement('div');
      cursor.className = 'typing-cursor';
      cursor.style.color = '#94a3b8';
      cursor.textContent = ' ';
      output.appendChild(cursor);
      return;
    }

    const line = lines[i];
    const div = document.createElement('div');
    if (line.class) div.className = line.class;
    div.textContent = line.text;

    if (line.text.startsWith('  [ OK ]')) div.style.color = '#34d399';
    else if (line.text.startsWith('  [ WARN ]')) div.style.color = '#fbbf24';
    else if (line.text.startsWith('  [ CRIT ]')) div.style.color = '#f87171';
    else if (line.text.startsWith('  [ SUGG ]')) div.style.color = '#22d3ee';
    else if (line.text.startsWith('  [ INFO ]')) div.style.color = '#94a3b8';
    else if (line.text.includes('PUNTUACION')) div.style.color = '#60a5fa';
    else if (line.text.includes('Excelente')) div.style.color = '#34d399';
    else if (line.text.includes('Bueno')) div.style.color = '#60a5fa';

    output.appendChild(div);
    output.scrollTop = output.scrollHeight;
    i++;
    setTimeout(typeLine, line.text ? 40 + Math.random() * 60 : 200);
  }

  typeLine();
}
