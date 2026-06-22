# Guía: Post-Instalación Segura de Windows con Wyndis

Acabas de instalar Windows. Antes de instalar nada más, ejecuta Wyndis para tener una línea base.

## Paso 1: Instalar Windows

Cualquier versión: Windows 10 22H2 o Windows 11 24H2.

## Paso 2: Wyndis auditoría base

```powershell
irm wyndis-download-ce9eb.web.app/install.ps1 | iex
```

Una instalación limpia de Windows 11 suele dar **60-70/100**:
- Firewall activo (bien)
- Defender activo (bien)
- Sin BitLocker (mal — depende del hardware)
- Telemetría completa (mal)
- Cortana activa (mal)
- Publicidad en el SO (mal)

## Paso 3: Correcciones recomendadas

Basado en los hallazgos de Wyndis:

| Check | Acción |
|---|---|
| BitLocker | `Enable-BitLocker -MountPoint C: -UsedSpaceOnly -SkipHardwareTest` |
| Telemetría | `reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection /v AllowTelemetry /t REG_DWORD /d 1` |
| Cortana | GPO: Computer Config > Admin Templates > Windows Components > Search |
| Publicidad | Settings > Personalization > Start > "Show suggestions occasionally" = Off |

## Paso 4: Re-auditar

```powershell
.\wyndis.ps1 -ReportPath "C:\Users\$env:USERNAME\Desktop\post-hardening.pdf"
```

Objetivo: **90+/100**.

---

Esta guía es parte de la documentación de Wyndis.
