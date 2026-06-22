# Wyndis en Empresas Pequeñas

Cómo auditar 20 PCs en una hora sin pagar licencias.

## Escenario

PYME con 20 equipos Windows sin SOC, sin presupuesto para herramientas enterprise,
necesitando un mínimo de seguridad para cumplir con clientes.

## Solución con Wyndis

1. Descargar Wyndis en un USB
2. Ejecutar en cada equipo (3 minutos por PC)
3. Exportar cada PDF con `-ReportPath`
4. Revisar los informes y priorizar

## Resultados reales

| Equipo | Puntuación | Hallazgos críticos |
|---|---|---|
| PC-Ventas-01 | 45/100 | Defender off, RDP expuesto, sin BitLocker |
| PC-Ventas-02 | 52/100 | Firewall apagado, Guest activa |
| PC-Admin-01 | 88/100 | Solo 2 warnings menores |
| PC-Taller-01 | 23/100 | Sin antivirus, telemetría alta, 0 parches en 6 meses |

## Ahorro

Herramienta equivalente más barata: **$1,200/año** (10 licencias).
Wyndis: **$0.00**.

---

Usar Wyndis no reemplaza un SOC, pero levanta el piso de seguridad de 20 a 80 en un día.
