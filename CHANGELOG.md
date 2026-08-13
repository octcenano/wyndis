# Changelog

## [4.0.0] — Enterprise / Purple Team Security Advisor
> **Nota**: el código fuente ya está en v4.0.0 (`$Script:WyndisVersion = '4.0.0'`), pero el último tag/release publicado era v2.0.0. Este changelog recoge el estado real del código.

### Añadido (v4.0)
- Simulación de ataque real mapeada a MITRE ATT&CK.
- Auditoría AD CS completa (ESC1-ESC13) + PetitPotam + Certifried.
- Detección de 40+ **LOLBins** en PATH/Tasks/Services/WMI.
- **Kerberos Deep**: SPN, delegaciones, RBCD, crypto.
- **Persistencia**: WMI, COM Hijacking, IFEO, Shim DB.
- **Hardening Engine reversible** (Test/Action/Rollback).
- **Informe Enterprise Dual-Mode** (Ejecutivo + Técnico).
- **Confidence Scoring** y **Timeline & Historial**.
- **Export JSON** para SIEM/SOAR.

## [2.0.0]
- Auditor de seguridad para Windows (versión previa publicada).
