# Wyndis — Componentes

```
wyndis/
├── wyndis.ps1          ← Entry point (invoca todos los módulos)
├── wyndis.bat          ← Launcher (auto-elevación + integridad)
├── lib/
│   ├── Wyndis-Core.ps1        ← Sistema, helpers
│   ├── Wyndis-Display.ps1     ← Salida + PDF
│   ├── Wyndis-Scoring.ps1     ← Puntuación 0-100
│   ├── Wyndis-Firewall.ps1    ← 12 checks
│   ├── Wyndis-Permissions.ps1 ← 10 checks
│   ├── Wyndis-Defender.ps1    ← 15 checks
│   ├── Wyndis-RDP.ps1         ← 8 checks
│   ├── Wyndis-Services.ps1    ← 10 checks
│   ├── Wyndis-Startup.ps1     ← 8 checks
│   ├── Wyndis-Updates.ps1     ← 10 checks
│   ├── Wyndis-Applications.ps1 ← 12 checks
│   ├── Wyndis-SystemLife.ps1  ← 6 checks
│   ├── Wyndis-Tools.ps1       ← 8 checks
│   ├── Wyndis-Network.ps1     ← 25 checks
│   ├── Wyndis-Browser.ps1     ← 20 checks
│   ├── Wyndis-Encryption.ps1  ← 20 checks
│   ├── Wyndis-CISBaseline.ps1 ← 35 checks
│   ├── Wyndis-Privacy.ps1     ← 20 checks
│   ├── Wyndis-WiFi.ps1        ← 15 checks
│   ├── Wyndis-WinRM.ps1       ← 10 checks
│   ├── Wyndis-BluetoothUSB.ps1 ← 10 checks
│   ├── Wyndis-Credentials.ps1 ← 12 checks
│   ├── Wyndis-SecurityCenter.ps1 ← 10 checks
│   ├── Wyndis-GroupPolicy.ps1 ← 15 checks
│   ├── Wyndis-Certificates.ps1 ← 10 checks
│   ├── Wyndis-EventLog.ps1    ← 10 checks
│   ├── Wyndis-PowerShell.ps1  ← 12 checks
│   ├── Wyndis-AuditPolicy.ps1 ← 10 checks
│   └── Wyndis-Container.ps1   ← 8 checks
└── .gitignore
```

## Convenciones

- IDs de checks: `MOD-001`, `MOD-002`...
- Severidad: `Critical` (-5 pts) o `Warning` (-2 pts)
- Categorías en español
- Cada módulo se carga dinámicamente desde `lib/`
