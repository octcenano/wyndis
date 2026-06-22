# SPDX-License-Identifier: MIT
#Requires -Version 5.1
<#
.SYNOPSIS
    Wyndis v2.0 - Auditor de seguridad profesional para Windows
.DESCRIPTION
    Herramienta gratuita de auditoria con 300+ puntos de verificacion.
    Genera informe PDF profesional con graficos.
    Licencia MIT | wyndis-download-ce9eb.web.app
.EXAMPLE
    .\wyndis.ps1
.EXAMPLE
    .\wyndis.ps1 -Quick -NoPdf
.EXAMPLE
    .\wyndis.ps1 -Full
#>

[CmdletBinding()]
param(
    [switch]$Quick,
    [switch]$NoColor,
    [switch]$NoPdf,
    [switch]$Full,
    [string]$ReportPath
)

$ErrorActionPreference = 'SilentlyContinue'
$Script:WyndisVersion = '2.0.0'
$Script:WyndisStartTime = Get-Date
$Script:Findings = [System.Collections.Generic.List[object]]::new()
$Script:ReportLines = [System.Collections.Generic.List[string]]::new()
$Script:ModulesExecuted = 0

$LibPath = Join-Path $PSScriptRoot 'lib'
Get-ChildItem -Path $LibPath -Filter '*.ps1' | Sort-Object Name | ForEach-Object {
    . $_.FullName
    $Script:ModulesExecuted++
}

function Start-Wyndis {
    Clear-Host
    Show-WyndisBanner

    $isAdmin = Test-WyndisAdmin
    if (-not $isAdmin) {
        Write-WyndisWarning 'No se ejecuta como Administrador. Muchas comprobaciones seran limitadas.'
        Write-WyndisSuggest 'Ejecuta: clic derecho en PowerShell -> "Ejecutar como administrador"'
    }

    Write-WyndisSection '1. Informacion del sistema'
    Invoke-WyndisSystemInfo

    Write-WyndisSection '2. Firewall de Windows'
    Invoke-WyndisFirewallAudit

    Write-WyndisSection '3. Permisos y cuentas de usuario'
    Invoke-WyndisPermissionsAudit

    Write-WyndisSection '4. Windows Update'
    Invoke-WyndisUpdateAudit

    Write-WyndisSection '5. Antivirus (Windows Defender)'
    Invoke-WyndisDefenderAudit

    Write-WyndisSection '6. Escritorio remoto (RDP)'
    Invoke-WyndisRdpAudit

    Write-WyndisSection '7. Servicios peligrosos'
    Invoke-WyndisServicesAudit

    Write-WyndisSection '8. Programas de inicio automatico'
    Invoke-WyndisStartupAudit

    Write-WyndisSection '9. Auditoria de Red'
    Invoke-WyndisNetworkAudit

    Write-WyndisSection '10. Auditoria de Cifrado'
    Invoke-WyndisEncryptionAudit

    Write-WyndisSection '11. Baseline CIS'
    Invoke-WyndisCISBaseline

    Write-WyndisSection '12. Privacidad y Telemetria'
    Invoke-WyndisPrivacyAudit

    Write-WyndisSection '13. Administracion Remota (WinRM)'
    Invoke-WyndisWinRMAudit

    Write-WyndisSection '14. Bluetooth y USB'
    Invoke-WyndisBluetoothUsbAudit

    Write-WyndisSection '15. Credenciales'
    Invoke-WyndisCredentialsAudit

    Write-WyndisSection '16. Centro de Seguridad'
    Invoke-WyndisSecurityCenterAudit

    Write-WyndisSection '17. Navegadores'
    Invoke-WyndisBrowserAudit

    Write-WyndisSection '18. Redes WiFi'
    Invoke-WyndisWiFiAudit

    Write-WyndisSection '19. Politicas de Grupo'
    Invoke-WyndisGroupPolicyAudit

    Write-WyndisSection '20. Certificados'
    Invoke-WyndisCertificateAudit

    Write-WyndisSection '21. Registros de Eventos'
    Invoke-WyndisEventLogAudit

    Write-WyndisSection '22. Seguridad de PowerShell'
    Invoke-WyndisPowerShellAudit

    Write-WyndisSection '23. Politicas de Auditoria'
    Invoke-WyndisAuditPolicyAudit

    if (-not $Quick) {
        Write-WyndisSection '24. Contenedores y Virtualizacion'
        Invoke-WyndisContainerAudit

        Write-WyndisSection '25. Aplicaciones instaladas'
        Invoke-WyndisApplicationsAudit

        Write-WyndisSection '26. Vida util del sistema'
        Invoke-WyndisSystemLifeAudit

        Write-WyndisSection '27. Recomendaciones de herramientas'
        Invoke-WyndisToolRecommendations
    }

    Write-WyndisSection 'Resumen y puntuacion'
    $score = Get-WyndisScore
    Show-WyndisScore $score

    $elapsed = (Get-Date) - $Script:WyndisStartTime
    $Script:AuditDuration = $elapsed.TotalSeconds.ToString('F1')

    if ($ReportPath) {
        Export-WyndisReport -Path $ReportPath -Score $score
    }

    if (-not $NoPdf) {
        Write-WyndisInfo 'Generando informe PDF...'
        $pdf = Export-WyndisPdfReport -Score $score
        if ($pdf) {
            Write-WyndisOk "PDF generado: $pdf"
        }
    }

    Write-Host ''
    Write-WyndisInfo "Auditoria completada en $($Script:AuditDuration) segundos."
    Write-WyndisInfo "Modulos ejecutados: $Script:ModulesExecuted | Hallazgos: $($score.Total)"
    Write-WyndisInfo 'Wyndis es 100% gratuito bajo licencia MIT.'
    Write-WyndisInfo 'Web: wyndis-download-ce9eb.web.app | Contacto: wyndis.help@gmail.com'

    if (-not $NoPdf) {
        Write-Host ''
        Write-WyndisInfo "PDF guardado en el escritorio: Wyndis-Informe-$timestamp.pdf"
        Write-WyndisInfo "Tambien disponible en: $pdf"
    }
}

Start-Wyndis
