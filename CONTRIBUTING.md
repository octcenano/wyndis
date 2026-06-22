# Contribuyendo a Wyndis

Gracias por tu interés en mejorar Wyndis. Este documento te guía en el proceso.

## Cómo contribuir

1. **Reporta bugs** — abre un [Issue](https://github.com/octcenano/wyndis/issues)
2. **Sugiere features** — usa la plantilla de Feature Request
3. **Envía código** — haz fork y Pull Request

## Pull Requests

- Rama: `main`
- Describe qué cambia y por qué
- Pasa las verificaciones de PowerShell (`Invoke-ScriptAnalyzer`)
- Añade o actualiza checks si corresponde
- Usa el prefijo del módulo: `NET-`, `ENC-`, `CIS-`, etc.

## Añadir un nuevo check de auditoría

Cada check sigue este formato:

```powershell
Add-WyndisFinding -Id "MOD-001" -Category "Categoría" -Name "Descripción clara" -Severity "Critical" | "Warning"
```

Los IDs se asignan secuencialmente por módulo. Verifica `wyndis/lib/` para ver los existentes.

## Código de conducta

Sé respetuoso, constructivo y bienvenido. Este es un proyecto abierto para aprender y mejorar la seguridad en Windows.
