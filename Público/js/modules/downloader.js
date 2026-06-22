export function initDownloader() {
  const downloadBtn = document.getElementById('downloadBtn');
  const downloadBatBtn = document.getElementById('downloadBatBtn');
  const verifyBtn = document.getElementById('verifyBtn');

  downloadBtn?.addEventListener('click', downloadWyndisScript);
  downloadBatBtn?.addEventListener('click', downloadWyndisBat);
  verifyBtn?.addEventListener('click', handleFileVerify);
}

function downloadFile(content, filename) {
  const blob = new Blob([content], { type: 'text/plain;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  setTimeout(() => URL.revokeObjectURL(url), 10000);
}

async function handleFileVerify() {
  const statusEl = document.getElementById('verifyStatus');
  const hashEl = document.getElementById('verifyHash');

  statusEl.innerHTML = 'Seleccionando archivo...';
  statusEl.className = '';

  const input = document.createElement('input');
  input.type = 'file';
  input.accept = '.ps1,.zip';

  input.onchange = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    statusEl.innerHTML = 'Calculando hash SHA-256...';
    const buffer = await file.arrayBuffer();
    const hashBuffer = await crypto.subtle.digest('SHA-256', buffer);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    const expectedHash = document.getElementById('expectedHash')?.textContent?.trim() || '';

    hashEl.textContent = hashHex;

    if (hashHex.toLowerCase() === expectedHash.toLowerCase()) {
      statusEl.innerHTML = 'VERIFICADO - El archivo es oficial y no ha sido modificado.';
      statusEl.className = 'hash-verify-badge';
      statusEl.style.cssText = 'background:rgba(16,185,129,0.12);border-color:#10b981;color:#34d399;display:inline-flex;';
    } else {
      statusEl.innerHTML = 'ERROR - El archivo NO coincide con el hash oficial.';
      statusEl.className = '';
      statusEl.style.cssText = 'background:rgba(239,68,68,0.12);border-color:#ef4444;color:#f87171;display:inline-flex;';
    }
  };

  input.click();
}

function downloadWyndisScript() {
  window.open('https://github.com/octcenano/wyndis.git', '_blank');
}

function downloadWyndisBat() {
  window.open('https://github.com/octcenano/wyndis.git', '_blank');
}
