# Wyndis vs Otras Herramientas de Auditoría

## Comparativa Detallada

| Aspecto | Wyndis | Lynis | MBSA | MS Security Compliance |
|---|---|---|---|---|
| Última actualización | 2026 | 2025 | 2019 | 2024 |
| Checks Windows | 320+ | ~50-80 | ~100 | ~200 |
| Informe PDF | Sí, con gráficos | No | No | No |
| Simulador online | Sí | No | No | No |
| Verificación SHA-256 | Sí | No | No | No |
| Sin telemetría | Sí | Sí | No | No |
| Offline | Sí | Sí | Sí | Sí |
| Instalación 1 clic | Sí (irm \| iex) | No | No | No |
| Service Worker | Sí | No | No | No |
| Licencia | MIT | GPLv3 | MS-EULA | MS-EULA |
| Tamaño | ~300 KB | ~2 MB | ~5 MB | ~50 MB |

## ¿Por qué no usar solo Windows Defender?

Defender es excelente para malware, pero NO audita:
- Configuración de red (SMB1, puertos abiertos)
- Políticas de grupo de seguridad
- Cifrado (BitLocker, TPM)
- Navegadores (Chrome/Edge/Firefox)
- Privacidad (telemetría, Cortana)
- Certificados raíz
- Y 280+ cosas más que Wyndis sí cubre.

## ¿Por qué no usar solo Lynis?

Lynis es originalmente para Linux. Su soporte Windows:
- Solo cubre ~50 checks
- No genera PDF
- No tiene web ni comunidad en español
- Interfaz 100% terminal

---

Wyndis complementa cualquier herramienta existente. No reemplaza un EDR, pero sí asegura que la base esté firme.
