<p align="center">
  <img src="https://img.shields.io/github/v/release/octcenano/wyndis?style=flat-square&label=versi%C3%B3n&color=3b82f6" alt="Versión">
  <img src="https://img.shields.io/github/license/octcenano/wyndis?style=flat-square&label=licencia&color=10b981" alt="Licencia">
  <img src="https://img.shields.io/github/stars/octcenano/wyndis?style=flat-square&label=estrellas" alt="Estrellas">
  <img src="https://img.shields.io/badge/Windows-10%20%7C%2011-2563eb?style=flat-square&logo=windows" alt="Windows">
  <img src="https://img.shields.io/badge/Linux-mint%20%7C%20ubuntu%20%7C%20debian-10b981?style=flat-square&logo=linux" alt="Linux">
  <img src="https://img.shields.io/badge/checks-345%2B-f59e0b?style=flat-square" alt="Checks">
  <img src="https://img.shields.io/badge/licencia-MIT-10b981?style=flat-square" alt="MIT">
  <img src="https://img.shields.io/badge/v4.0-enterprise%20%7C%20purple%20team-8b5cf6?style=flat-square" alt="v4.0">
</p>

<br>

<div align="center">
  <h1>🛡️ Wyndis v4.0</h1>
  <p><strong>Security Advisor para Windows y Linux — Purple Team / Enterprise Ready</strong><br>
  345+ checks · Simulación de ataque real (MITRE ATT&CK) · Hardening reversible · Timeline & Historial<br>
  Dual-mode PDF (Ejecutivo + Técnico) · Confidence scoring · Export JSON · 100% Open Source MIT</p>

  <p>
    <a href="https://github.com/octcenano/wyndis/releases/latest">📥 Descargar</a> ·
    <a href="#instalación">📦 Instalación</a> ·
    <a href="#módulos">📋 Módulos</a> ·
    <a href="#roadmap">🗺️ Roadmap</a> ·
    <a href="https://github.com/octcenano/wyndis/discussions">💬 Comunidad</a>
  </p>
</div>

---

## 🎯 ¿Por qué Wyndis v4.0?

Diseñado para **equipos de seguridad internos, pentesters, sysadmins y CISOs** que necesitan:

| Necesidad real | Cómo lo resuelve Wyndis v4.0 |
|---|---|
| **"¿Por dónde entraría un atacante HOY en mi red?"** | Simulación de ataque real mapeada a MITRE ATT&CK (Initial Access → Persistence → PrivEsc → Lateral Movement → Credential Access → Exfiltration) |
| **"¿Este LOLBin lo están usando contra mí?"** | Detección de 40+ LOLBins en PATH, Scheduled Tasks, Services, WMI Consumers + firmas verificadas |
| **"¿Mis delegaciones Kerberos son seguras?"** | Auditoría completa: Unconstrained/Constrained/RBCD, SPN scanning, AS-REP Roasting, Kerberoasting, PAC validation, AES vs RC4 |
| **"¿Mis plantillas AD CS son vulnerables?"** | **ESC1-ESC13** completos + PetitPotam + Certifried + Shadow Credentials (0 herramientas cubren esto bien) |
| **"¿Tengo persistencia WMI/COM/IFEO/Shim?"** | Detección de WMI Event Subscriptions, COM Hijacking (HKCU), IFEO Debugger, AppInit_DLLs, Shim Database (SDB), Services no firmados |
| **"¿El hardening rompe mi app de contabilidad?"** | **Engine seguro/reversible**: 40+ fixes con Test/Action/Rollback, Dry-run, Auto-confirm, Categoría selectiva, Log JSON, Rollback automático |
| **"¿Cómo explico esto al CISO en 2 minutos?"** | **PDF Dual-Mode**: Executive (score, charts, top 5 risks) + Technical (comandos, paths, MITRE, CVE, tiempo estimado, confidence) |
| **"¿Qué ha cambiado desde la última auditoría?"** | **Timeline & Historial**: Cuándo apareció cada hallazgo, comparación automática, trend analysis, export JSON para SIEM/SOAR |
| **"¿Cuánto tardaré en arreglar esto?"** | Tiempo estimado de remediación por hallazgo (horas/días), dependencias, roadmap priorizado por fases (0-30d, 30-90d, 90+d) |
| **"¿Confío en este hallazgo?"** | **Confidence scoring** (0-100%): <70% = "⚠ VERIFICAR MANUALMENTE" automático en reporte y consola |

---

## 📊 Comparativa honesta

| Característica | Wyndis v4.0 | Lynis | MBSA | MS Security Compliance Toolkit | BloodHound |
|---|---|---|---|---|---|
| **Precio** | Gratis | Gratis | Gratis | Gratis | Gratis |
| **Licencia** | MIT | GPLv3 | MS-EULA | MS-EULA | GPLv3 |
| **Checks Windows** | 345+ | ~50-80 | ~100 | ~200 | N/A (graph) |
| **Attack Simulation (MITRE)** | ✅ Completa | ❌ | ❌ | ❌ | Parcial |
| **AD CS ESC1-ESC13** | ✅ Completo | ❌ | ❌ | ❌ | ❌ |
| **LOLBin Detection** | ✅ 40+ | Parcial | ❌ | ❌ | ❌ |
| **Kerberos Deep** | ✅ (SPN, Delegation, RBCD, PAC, Crypto) | ❌ | ❌ | ❌ | ❌ |
| **Persistence (WMI/COM/IFEO/SDB)** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Hardening Reversible** | ✅ (Test/Action/Rollback) | ❌ | ❌ | ❌ | N/A |
| **PDF Dual-Mode (Exec+Tech)** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Timeline & History** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Confidence Scoring** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Remediation Time Est.** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Export JSON (SIEM/SOAR)** | ✅ | Parcial | ❌ | ❌ | ✅ |
| **Linux Support** | ✅ (bash nativo) | ✅ | ❌ | ❌ | ❌ |
| **Offline 100%** | ✅ | ✅ | ✅ | ✅ | ❌ (requiere ingestor) |
| **Sin telemetría** | ✅ | ✅ | ❌ | ❌ | ✅ |

> **Nota**: Wyndis no sustituye un EDR, SIEM o BloodHound. **Complementa** cubriendo los gaps que esas herramientas no auditan (AD CS, LOLBins, Persistence avanzada, Kerberos crypto, hardening reversible).

---

## 📥 Instalación

### Windows (Recomendado - Un comando)

```powershell
# Instalador verifica SHA-256, pide confirmación, logea todo, crea acceso directo
irm https://wyndis-download-ce9eb.web.app/install.ps1 | iex

# Preview mode (ver qué hará sin ejecutar)
irm https://wyndis-download-ce9eb.web.app/install.ps1 -OutFile install.ps1; ./install.ps1 -Preview

# Manual
# 1. Descarga wyndis.ps1 + wyndis.bat + lib/ de GitHub Releases
# 2. Verifica SHA-256 contra checksums.txt
# 3. Ejecuta como Admin: powershell -ExecutionPolicy RemoteSigned -File .\wyndis.ps1
```

### Linux (Bash nativo - v4.0)

```bash
# Descargar
curl -sSL https://github.com/octcenano/wyndis/releases/latest/download/wyndis.sh -o wyndis.sh
chmod +x wyndis.sh

# Verificar integridad (SHA-256 en checksums.txt)
sha256sum -c checksums.txt

# Ejecutar
sudo ./wyndis.sh                    # Auditoría completa
sudo ./wyndis.sh --hardening --hardening-dry-run    # Hardening simulado
sudo ./wyndis.sh --hardening --hardening-auto       # Hardening automático
sudo ./wyndis.sh --enterprise-report --include-timeline --include-confidence  # Informe dual
sudo ./wyndis.sh --security-advisor --simulate-attack --generate-roadmap      # Security Advisor
sudo ./wyndis.sh --show-timeline --compare-audits   # Timeline & comparación
```

### Chocolatey / Winget (Próximamente v4.0)

```powershell
choco install wyndis --version 4.0.0
winget install octcenano.wyndis
```

---

## 🚀 Uso rápido

```powershell
# Auditoría completa (recomendado)
.\wyndis.ps1

# Auditoría rápida (sin contenedores, apps, system life)
.\wyndis.ps1 -Quick

# Informe Enterprise v4.0 (Dual-Mode PDF + Timeline + Confidence + JSON)
.\wyndis.ps1 -EnterpriseReport -IncludeTimeline -IncludeConfidence -ExportJson

# Solo modo ejecutivo (para dirección/CISO)
.\wyndis.ps1 -EnterpriseReport -ExecutiveOnly

# Solo modo técnico (para analistas)
.\wyndis.ps1 -EnterpriseReport -TechnicalOnly

# Security Advisor: Simulación de ataque + Roadmap
.\wyndis.ps1 -SecurityAdvisor -SimulateAttack -GenerateRoadmap

# Hardening Engine v4.0
.\wyndis.ps1 -Hardening -HardeningDryRun                    # Simular (seguro)
.\wyndis.ps1 -Hardening -HardeningAuto                      # Aplicar con confirmación
.\wyndis.ps1 -Hardening -HardeningAuto -HardeningCategory "Defender,Firewall,UAC"  # Solo categorías

# Timeline & Historial
.\wyndis.ps1 -ShowTimeline                    # Últimos 90 días
.\wyndis.ps1 -ShowTimeline -TimelineDays 30  # Últimos 30 días
.\wyndis.ps1 -CompareAudits                   # Comparar última vs anterior
.\wyndis.ps1 -ExportHistory -HistoryDays 365  # Exportar historial JSON

# Exportar todo a JSON (para SIEM/SOAR)
.\wyndis.ps1 -ExportJson
```

---

## 📋 Módulos v4.0 (345+ checks)

### Core (Siempre)
| Módulo | Checks | Qué audita |
|---|---|---|
| **SystemInfo** | 1 | Hardware, OS, uptime, admin status |
| **Firewall** | 12 | Perfiles, reglas, puertos riesgosos, logging, SMBv1 |
| **Permissions** | 10 | Cuentas built-in, UAC, password policy, AdminSDHolder |
| **Updates** | 10 | WU service, auto-updates, pending, reboot, EOL, drivers |
| **Defender** | 15 | Real-time, Cloud, Tamper, PUA, Network Protection, CFA, ASR, signatures |
| **RDP** | 8 | Servicio, fDenyTSConnections, NLA, puerto, NLA, SecurityLayer |
| **Services** | 10 | Spooler, RemoteRegistry, LLDP, UPnP, SSDP, Fax, Telnet, TFTP, credenciales, firmas |
| **Startup** | 8 | Run keys, tareas programadas, startup folder, servicios auto, WMI subscriptions, Winlogon |
| **Network** | 25 | Interfaces, IPs, puertos, conexiones sospechosas, SMB signing, LLMNR, NBT-NS, WPAD, IPv6, Teredo, shares, hosts, IIS |
| **Encryption** | 20 | TPM, Secure Boot, BitLocker (C:, fijos, removibles), crypto methods, protectors, auto-unlock, VBS/HVCI/DMA, pagefile, hibernation, crash dumps |
| **CISBaseline** | 35 | Audit policy, LSA protection, WDigest, Null sessions, LM hash, shutdown, smartcard, cached logons, Kerberos, SMB signing, LDAP signing, RPC |
| **Privacy** | 20 | Telemetry, Cortana, Location, Advertising ID, Inking/Typing, Activity History, Background apps, WiFi Sense, Error reporting, CEIP |
| **WiFi** | 15 | Perfiles, contraseñas en claro, auto-connect, WiFi Sense, Hotspot 2.0, security type, MAC randomization, WPS, band preference |
| **WinRM** | 10 | Servicio, listeners HTTP/HTTPS, auth (Basic/Kerberos/Negotiate/Cert/credSSP), AllowUnencrypted, TrustedHosts, MaxConcurrent, Certificados |
| **Bluetooth/USB** | 10 | Servicios, discoverability, paired devices, USBSTOR, device class restrictions, unsigned drivers, selective suspend, dispositivos actuales |
| **Credentials** | 12 | Credential Guard, RunAsPPL, WDigest, AutoAdminLogon, Credential Manager, WiFi passwords, Unconstrained delegation, SPN accounts, PasswordNeverExpires, Reversible encryption, LSA Secrets |
| **SecurityCenter** | 10 | WSC service, AV/FW/AS registrados, notificaciones, overrides, UAC notifications, IE zones, SmartScreen, WER, CEIP |
| **GroupPolicy** | 15 | gpresult, Default Domain/DC Policy, password/lockout/kerberos/audit/user rights/scripts/software/folder redirect/wireless |
| **Certificates** | 10 | Root/CA/My stores, expirados, weak algos (SHA1/MD5), key size <2048, self-signed en trusted, code signing, server auth, autoenroll, CRL/OCSP |
| **EventLog** | 10 | Tamaños (Security/System/Application), retention, audit policy subcategories (Logon, Object Access, Policy Change, Privilege Use, Process Tracking, DS Access, Account Logon, Account Mgmt, System Events, Detailed Tracking) |
| **PowerShell** | 12 | Versión, PS2.0 engine, Script Block Logging, Module Logging, Transcription, AMSI, ConstrainedLanguage, Profiles, ExecutionPolicy, PSGallery, History |
| **AuditPolicy** | 10 | Subcategorías críticas (Logon, Logoff, Account Lockout, File System, Registry, Process Creation, Credential Validation, Kerberos, User/Computer/Security Group Mgmt, Other) |
| **Container** | 8 | Docker daemon.json (userns-remap, no-new-privs, live-restore, log rotation), contenedores running/root, WSL1/2, Hyper-V VMs, VBS, kubectl |

### Purple Team / Enterprise (Exclusivos v4.0)
| Módulo | Checks | Qué detecta (único en Wyndis) |
|---|---|---|
| **AttackPath** | 8 | AdminSDHolder, GPO delegation, Shadow Admins, Trusts, Unconstrained/RBCD/DCSync, LAPS, Certifried |
| **ADCS** | 13 | **ESC1-ESC13** + PetitPotam + Certifried + Shadow Credentials + Web Enrollment NTLM Relay |
| **LOLBins** | 40+ | 40+ binarios en PATH/Tasks/Services/WMI, firmas verificadas, ubicaciones anómalas, MITRE tags |
| **Kerberos** | 15 | SPN/Kerberoasting, AS-REP Roasting, Unconstrained/Constrained/RBCD, RC4 vs AES, PAC, Ticket lifetime, gMSA, FAST |
| **Persistence** | 10 | WMI Event Subscriptions, COM Hijacking (HKCU), Scheduled Tasks, IFEO Debugger, AppInit_DLLs, Shim Database (SDB), Servicios no firmados, Winlogon Userinit/Shell |

### Herramientas & Utilidades
| Módulo | Checks |
|---|---|
| **Tools** | 8 | Sysinternals, RSAT, PowerShell 7+, Windows Terminal, VS Code/Notepad++, Wireshark, 7-Zip, HWiNFO, Sysmon |
| **Applications** | 12 | Software obsoleto (Java, Flash, Silverlight, QuickTime, Python 2, Node <16, VS 2015-, Office 2016-), bloatware OEM, store apps, drivers GPU >1yr, unsigned publishers, remote access tools |
| **SystemLife** | 6 | Uptime >30d, disk space <10%/20%, battery health, temperature, OS install age |
| **Hardening** | 40+ | Engine con Test/Action/Rollback, Dry-run, Auto-confirm, Categorías, Log JSON, Rollback automático |

---

## 🎯 Security Advisor v4.0 — Simulación de Ataque Real

```powershell
.\wyndis.ps1 -SecurityAdvisor -SimulateAttack -GenerateRoadmap
```

**Fases mapeadas a MITRE ATT&CK:**

| Fase | Técnicas detectadas (ejemplos) |
|---|---|
| **Initial Access** | T1190 (RDP/VPN expuesto), T1078.003 (Kerberoasting/AS-REP), T1550.003 (Delegation), T1649 (AD CS ESC1-13), T1190 (PetitPotam/Certifried) |
| **Persistence** | T1546.003 (WMI), T1546.015 (COM Hijack), T1546.012 (IFEO), T1546.010 (AppInit), T1546.011 (SDB) |
| **Privilege Escalation** | T1550.003 (Unconstrained Delegation → DA), T1649 (ESC1 → DA via cert), T1550.003 (RBCD) |
| **Lateral Movement** | T1021.004 (WinRM), T1021.006 (DCOM), T1021.002 (SMB/Pass-the-Hash) |
| **Credential Access** | T1003.001 (LSASS dump), T1558.003/004 (Kerberoasting/AS-REP) |
| **Defense Evasion** | T1218 (LOLBins: certutil, mshta, msbuild, regsvr32...), T1562.001 (Audit off) |
| **Discovery** | T1087/T1069/T1018/T1482 (AD Recon / BloodHound) |
| **Exfiltration** | T1041/T1048/T1567 (certutil/bitsadmin/Invoke-WebRequest/curl/tar) |

**Salida incluye por técnica:**
- Prerrequisitos, Impacto, Likelihood, **Confidence %**, Time to Exploit
- Detección (Event IDs, Sysmon, Defender ATP)
- Mitigación concreta con comandos
- Referencias MITRE, CVE, blogs
- **⚠ "VERIFICAR MANUALMENTE" si Confidence < 70%**

---

## 🛡️ Hardening Engine v4.0 — Seguro, Reversible, Transparente

```powershell
# Simular (DRY-RUN) - zero risk
.\wyndis.ps1 -Hardening -HardeningDryRun

# Aplicar con confirmación interactiva
.\wyndis.ps1 -Hardening -HardeningAuto

# Solo categorías específicas
.\wyndis.ps1 -Hardening -HardeningAuto -HardeningCategory "Defender,Firewall,UAC,Credentials"
```

**40+ Fixes con:** `Test` (¿ya aplicado?) → `Action` (aplicar) → `Rollback` (revertir) → `Risk` (Low/Medium) → `Reboot` flag → `Confidence`

| Categoría | Fixes clave |
|---|---|
| **Firewall** | Perfiles on, default inbound block, logging, risky ports |
| **Defender** | Real-time, Cloud, Tamper, PUA, CFA, Network Protection, Script scanning, Behavior monitoring |
| **UAC** | EnableLUA=1, ConsentPromptBehaviorAdmin=5, SecureDesktop=1, ConsentPromptBehaviorUser=3 |
| **RDP** | fDenyTSConnections=1, NLA=1, SecurityLayer=2 |
| **Services** | Spooler, RemoteRegistry, LLDP, UPnP, SSDP, Fax, Telnet deshabilitados |
| **Network** | SMBv1 off, SMB signing, LLMNR off, NBT-NS off, WPAD off, IPv6/Teredo/6to4/ISATAP off |
| **Updates** | AUOptions=4 (auto download+install), no reboot pending |
| **PowerShell** | Script Block Logging, Module Logging, Transcription, AMSI, Disable PS2.0, ExecutionPolicy=RemoteSigned |
| **Privacy** | AllowTelemetry=1 (Basic), Cortana=0, ConnectedSearch=0, Location=0, Ad ID=0, TailoredExperiences=0, ActivityHistory=0, BackgroundApps=0, WiFi Sense=0, WER=0, CEIP=0 |
| **Encryption** | ClearPageFileAtShutdown=1, Credential Guard (VBS), HVCI, RunAsPPL, WDigest=0, LSA Protection |
| **Kernel** | SynAttackProtect=2, Disable IPv6 if unused |
| **Audit Policy** | 15 subcategorías críticas en Success+Failure |
| **LSA** | RunAsPPL, WDigest=0, LSA Protection |
| **Credentials** | Unconstrained Delegation off, Constrained→RBCD, gMSA migration |

**Rollback automático:** Guarda estado previo → si verificación falla → revierte → logea en JSON.

---

## 📄 Informe Enterprise v4.0 — Dual Mode

```powershell
# Completo (Ejecutivo + Técnico + Timeline + Confidence + JSON)
.\wyndis.ps1 -EnterpriseReport -IncludeTimeline -IncludeConfidence -ExportJson

# Solo Ejecutivo (para CISO/Dirección - 2 páginas)
.\wyndis.ps1 -EnterpriseReport -ExecutiveOnly

# Solo Técnico (para analistas - detalle completo)
.\wyndis.ps1 -EnterpriseReport -TechnicalOnly
```

### Modo Ejecutivo (1-2 páginas)
- **Security Score** grande con grade (🟢/🟡/🟠/🔴/⚫)
- **Priority Matrix SVG** (Impact × Likelihood, burbujas = Risk Score, Top 10)
- **Top 5 riesgos críticos** con impacto negocio
- **Executive Summary** bullet points para CISO
- **Trend** (últimas N auditorías)

### Modo Técnico (Detalle completo)
- **Priority Matrix** con tabla Top 10 (ID, Name, Category, Severity, Impact, Likelihood, Risk Score)
- **Por categoría**: Tabla con ID, Hallazgo, Severidad, **Confidence%**, **Tiempo est. (h/d)**, **MITRE ATT&CK**, **CVE**
- **Simple** (qué, por qué) + **Advanced** (detalle, remediación comando a comando, MITRE, CVE, referencia)
- **Timeline** comparativa (últimas N auditorías)
- **Attack Simulation** mapeado a MITRE con confidence, time-to-exploit, detection, mitigation
- **Roadmap** priorizado 3 fases (0-30d, 30-90d, 90+d) con horas/días, dependencias, reducción riesgo

### Confidence Scoring
- Cada hallazgo tiene `Confidence` (0-100%)
- **≥90%**: Verde ✓
- **70-89%**: Amarillo ⚠
- **<70%**: Rojo ⚠ **"VERIFICAR MANUALMENTE"** en consola y reporte
- Configurable: `-ConfidenceThreshold 80`

### Export JSON (SIEM/SOAR)
```json
{
  "version": "4.0.0",
  "timestamp": "2026-07-11T14:30:00Z",
  "host": "DESKTOP-ABC123",
  "score": {"score": 78, "total": 12, "critical": 3, "warning": 9},
  "findings": [...],
  "attackSimulation": [...],
  "roadmap": [...],
  "history": [...],
  "matrixData": [...]
}
```

---

## 📈 Timeline & Historial

```powershell
# Ver tendencia (últimos 90 días por defecto)
.\wyndis.ps1 -ShowTimeline

# Últimos 30 días
.\wyndis.ps1 -ShowTimeline -TimelineDays 30

# Comparar última vs anterior automáticamente
.\wyndis.ps1 -CompareAudits

# Exportar historial completo a JSON
.\wyndis.ps1 -ExportHistory -HistoryDays 365
```

**Timeline muestra:**
- ASCII chart con score, trend (↑/↓/→), hallazgos, duración
- Estadísticas: auditorías en período, score promedio, max/min, tendencia general
- **Comparación**: Score diff, nuevos/corregidos/persistentes, tendencia por categoría
- **Almacenamiento**: `$env:ProgramData\Wyndis\History\audit-YYYYMMDD-HHMMSS.json` (máx 50 entradas, ACL solo Admins/SYSTEM)

---

## 🗺️ Roadmap v4.x

| Versión | Enfoque | Estado |
|---|---|---|
| **v4.0** | Attack Simulation, AD CS ESC1-13, LOLBins, Kerberos Deep, Persistence, Hardening Reversible, Dual-Mode Report, Timeline, Confidence, JSON Export | ✅ **Esta release** |
| **v4.1** | BloodHound ingestor nativo, Azure AD / Entra ID checks, Intune/MDM drift detection, Conditional Access gaps, JEA roles | 🔜 En desarrollo |
| **v4.2** | GUI nativa (WinForms), Programación de auditorías, Alerting (webhook/email/Teams), Multi-host orchestration | 📋 Planificado |
| **v4.3** | Plugin system (checks custom PowerShell), Community rule pack, MITRE ATT&CK Navigator export | 📋 Planificado |
| **v5.0** | Linux agent completo (bash + Python), Embedded dashboard web, Fleet management API | 🚀 Futuro |

---

## 🤝 Contribuir

```bash
# 1. Fork & clone
# 2. Añade tu check en wyndis/lib/Wyndis-<NuevaCategoria>.ps1
#    Siguiendo el patrón: Add-WyndisFinding -Id "CAT-XXX" -Category "Categoria" -Name "Descripción" -Severity "Critical|Warning" -Details "..." -Remediation "comando" -Reference "MITRE TXXXX" -Confidence 90 -EstimatedHours 2 -MITRE "T1XXX" -CVE "CVE-XXXX-XXXX"
# 3. Test: .\wyndis.ps1 -Quick
# 4. PR a main
```

**Convenciones:**
- IDs: `CAT-XXX` (CAT = prefijo categoría: FW, PER, DEF, RDP, SVC, STA, NET, ENC, CIS, PRV, WIF, WRM, BTU, CRE, WSC, BRO, WIF, GP, CRT, EVT, PSH, AUD, CON, TOO, APP, SYS, KER, ATK, ADCS, LOL, PER)
- Severity: `Critical` (-5 pts) o `Warning` (-2 pts)
- Confidence: 0-100 (realista, no inflar)
- EstimatedHours: tiempo real de remediación
- MITRE ATT&CK: formato `TXXXX.XXX`
- CVE: formato `CVE-YYYY-NNNNN` si aplica

---

## 📄 Licencia

**MIT License** — Úsalo, modifícalo, distríbuelo, incluso comercialmente.  
Solo conserva el copyright y licencia.

```
MIT License
Copyright (c) 2026 Wyndis Contributors
Permission is hereby granted, free of charge, to any person obtaining a copy...
```

---

## 🔒 Seguridad

- **Sin telemetría** — Todo corre localmente
- **SHA-256 verificable** — Installer y releases firmados
- **Security Policy** — [SECURITY.md](SECURITY.md)
- **Reportar vuln** — wyndis.help@gmail.com (NO issues públicos)
- **Respuesta esperada** — 48h ack, 7 días parche según severidad

---

## 🙏 Agradecimientos

A la comunidad de seguridad que comparte conocimiento abierto:
- **SpecterOps** (Certified, BloodHound, AD CS research)
- **LOLBAS Project** (Living Off The Land Binaries)
- **HarmJ0y, Will Schroeder, Lee Christensen** (Kerberos, Delegation, AD CS)
- **MITRE ATT&CK** framework
- **Microsoft** por documentar internals y hardening guides

---

<div align="center">
  <sub>Hecho con ❤️ para la comunidad de seguridad · MIT License · 2026</sub>
  <br>
  <a href="mailto:wyndis.help@gmail.com">wyndis.help@gmail.com</a>
  <br>
  <a href="https://github.com/octcenano/wyndis">github.com/octcenano/wyndis</a>
  <br>
  <a href="https://discord.gg/wyndis">Discord Community</a>
</div>