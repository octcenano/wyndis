<p align="center">
  <img src="https://img.shields.io/github/v/release/octcenano/wyndis?style=flat-square&label=versión&color=3b82f6" alt="Versión">
  <img src="https://img.shields.io/github/license/octcenano/wyndis?style=flat-square&label=licencia&color=10b981" alt="Licencia">
  <img src="https://img.shields.io/github/stars/octcenano/wyndis?style=flat-square&label=estrellas" alt="Estrellas">
  <img src="https://img.shields.io/badge/Windows-10%20|%2011-2563eb?style=flat-square&logo=windows" alt="Windows">
  <img src="https://img.shields.io/badge/checks-320%2B-f59e0b?style=flat-square" alt="Checks">
  <img src="https://img.shields.io/badge/licencia-MIT-10b981?style=flat-square" alt="MIT">
</p>

<br>

<div align="center">
  <h1>🛡️ Wyndis</h1>
  <p><strong>Auditor de seguridad profesional para Windows</strong><br>
  300+ puntos de verificación · Informe PDF con gráficos · 100% gratuito · Código abierto</p>

  <p>
    <a href="https://wyndis-download-ce9eb.web.app">🌐 Web oficial</a> ·
    <a href="#instalación">📦 Instalación</a> ·
    <a href="#módulos">📋 Módulos</a> ·
    <a href="#roadmap">🗺️ Roadmap</a> ·
    <a href="https://discord.gg/wyndis">💬 Discord</a>
  </p>
</div>

<br>

https://github.com/user-attachments/assets/example

---

## ✨ ¿Por qué Wyndis?

| Característica | Wyndis | Lynis (Windows) | MBSA | Security Compliance Toolkit |
|---|---|---|---|---|
| **Precio** | Gratis | Gratis | Gratis | Gratis |
| **Licencia** | MIT | GPLv3 | MS-EULA | MS-EULA |
| **Checks** | 320+ | ~50 (Windows) | ~100 | ~200 |
| **Informe PDF** | ✅ Con gráficos | ❌ | ❌ | ❌ |
| **Simulador online** | ✅ | ❌ | ❌ | ❌ |
| **Offline 100%** | ✅ | ✅ | ✅ | ✅ |
| **Sin telemetría** | ✅ | ✅ | ❌ | ❌ |
| **Instalación 1 clic** | ✅ | ❌ | ❌ | ❌ |
| **Verificación SHA-256** | ✅ | ❌ | ❌ | ❌ |
| **Service Worker (offline web)** | ✅ | ❌ | ❌ | ❌ |
| **Actualizado 2026** | ✅ | Parcial | Discontinuado | Parcial |

---

## 📥 Instalación

### Opción 1: Un solo comando (recomendada)

```powershell
irm wyndis-download-ce9eb.web.app/install.ps1 | iex
```

El instalador:
1. Verifica SHA-256 del paquete
2. Te pide confirmación explícita
3. Registra todo en `%ProgramData%\Wyndis\install.log`
4. Crea acceso directo en el escritorio

### Opción 2: Preview (ver antes de ejecutar)

```powershell
irm wyndis-download-ce9eb.web.app/install.ps1 -OutFile install.ps1; ./install.ps1 -Preview
```

### Opción 3: Manual

1. Descarga [wyndis.ps1](https://wyndis-download-ce9eb.web.app) de la web
2. Verifica el hash SHA-256 (compará con `checksums.txt`)
3. Ejecuta como Administrador:
   ```powershell
   powershell -ExecutionPolicy RemoteSigned -File .\wyndis.ps1
   ```

---

## 🚀 Uso

```powershell
# Auditoría completa (recomendado)
.\wyndis.ps1

# Auditoría rápida (sin aplicaciones ni system life)
.\wyndis.ps1 -Quick

# Sin colores
.\wyndis.ps1 -NoColor

# Guardar reporte en ruta específica
.\wyndis.ps1 -ReportPath "C:\Users\tu\Desktop\reporte.pdf"
```

O simplemente haz doble clic en **`wyndis.bat`** (se auto-eleva y verifica integridad).

---

## 📊 Puntuación

Wyndis puntúa tu sistema en una escala **0–100**:

- **90–100** 🟢 Excelente — Configuración segura
- **70–89** 🟡 Buena — Mejoras menores recomendadas
- **40–69** 🟠 Aceptable — Riesgos que merecen atención
- **10–39** 🔴 Necesita mejoras — Varios hallazgos críticos
- **0–9** ⚫ Crítico — Acción inmediata requerida

Cada hallazgo crítico resta 5 puntos; cada advertencia resta 2 puntos.

---

## 📋 Módulos (27 en total)

| Módulo | Checks | Descripción |
|---|---|---|
| **Firewall** | 12 | Perfiles, reglas, puertos abiertos |
| **Permisos** | 10 | Cuentas locales, UAC, SAM |
| **Defender** | 15 | Estado, firmas, PUA, tamper |
| **RDP** | 8 | Conexiones, NLA, puerto |
| **Servicios** | 10 | Servicios innecesarios expuestos |
| **Startup** | 8 | Programas de inicio automático |
| **Updates** | 10 | Parches, EOL, reinicios pendientes |
| **Aplicaciones** | 12 | Software obsoleto, bloatware |
| **SystemLife** | 6 | Uptime, almacenamiento, batería |
| **Tools** | 8 | Sysinternals, herramientas de seguridad |
| **Network** | 25 | Puertos, conexiones, DNS, proxy |
| **Browser** | 20 | Chrome/Edge/Firefox config |
| **Encryption** | 20 | BitLocker, TPM, Secure Boot |
| **CIS Baseline** | 35 | Benchmarks CIS nivel 1 y 2 |
| **Privacy** | 20 | Telemetría, Cortana, ubicación |
| **WiFi** | 15 | Redes, perfiles, contraseñas |
| **WinRM** | 10 | PSRemoting, listeners |
| **BluetoothUSB** | 10 | Dispositivos, defensas |
| **Credentials** | 12 | LSA, credenciales almacenadas |
| **SecurityCenter** | 10 | WSC, notificaciones |
| **GroupPolicy** | 15 | GPOs de seguridad |
| **Certificates** | 10 | Certificados raíz, expirados |
| **EventLog** | 10 | Tamaño, auditoría |
| **PowerShell** | 12 | Logging, AMSI, ConstrainedLanguage |
| **AuditPolicy** | 10 | Políticas de auditoría |
| **Container** | 8 | Docker, WSL, Hyper-V |
| **Scoring** | — | Motor de puntuación 0–100 |

---

## 🗺️ Roadmap

| Versión | Novedades | Estado |
|---|---|---|
| v2.0 | Web profesional, PDF con gráficos, 27 módulos, 320+ checks | ✅ Publicado |
| v2.1 | Chocolatey + Winget, GitHub Actions, pruebas automáticas | 🔜 En desarrollo |
| v2.2 | Interfaz GUI nativa (WinForms), programación de auditorías | 📋 Planificado |
| v2.3 | Plugin system, checks personalizados por el usuario | 📋 Planificado |
| v3.0 | Versión Linux (bash), dashboard web embebido | 🚀 Futuro |

[Ver milestones completos](https://github.com/octcenano/wyndis/milestones)

---

## 🤝 Contribuir

Toda contribución es bienvenida:

- 🐛 [Reporta bugs](https://github.com/octcenano/wyndis/issues/new?template=bug_report.md)
- 💡 [Sugiere features](https://github.com/octcenano/wyndis/issues/new?template=feature_request.md)
- 🔧 [Añade un check](https://github.com/octcenano/wyndis/blob/main/CONTRIBUTING.md)
- 💬 [Únete al Discord](https://discord.gg/wyndis)

Lee [`CONTRIBUTING.md`](CONTRIBUTING.md) para empezar.

---

## 🔒 Seguridad

- [Política de seguridad](SECURITY.md)
- [Security.txt](https://wyndis-download-ce9eb.web.app/.well-known/security.txt)
- [Checksums oficiales](https://wyndis-download-ce9eb.web.app/checksums.txt)
- [Licencia MIT](LICENSE)

Wyndis **no recopila datos personales**. Todo el análisis se ejecuta localmente en tu máquina. Sin telemetría, sin rastreo, sin anuncios.

---

<p align="center">
  <sub>Hecho con ❤️ para la comunidad de seguridad en Windows · MIT License · 2026</sub>
  <br>
  <a href="mailto:wyndis.help@gmail.com">wyndis.help@gmail.com</a>
</p>
