# SPDX-License-Identifier: MIT
#Requires -Version 5.1
<#
.SYNOPSIS
    Wyndis v4.0 - Enterprise Security Advisor para Windows
.DESCRIPTION
    Auditor de seguridad Purple Team / Enterprise con simulación de ataque,
    hardening reversible, timeline, confidence scoring, dual-mode reports.
    Licencia MIT | https://github.com/octcenano/wyndis
.EXAMPLE
    .\wyndis.ps1
.EXAMPLE
    .\wyndis.ps1 -Quick -NoPdf
.EXAMPLE
    .\wyndis.ps1 -EnterpriseReport -IncludeTimeline -IncludeConfidence
.EXAMPLE
    .\wyndis.ps1 -Hardening -HardeningDryRun
.EXAMPLE
    .\wyndis.ps1 -Hardening -HardeningAuto -HardeningCategory "Defender,Firewall"
.EXAMPLE
    .\wyndis.ps1 -SecurityAdvisor -SimulateAttack -GenerateRoadmap
.EXAMPLE
    .\wyndis.ps1 -ShowTimeline -CompareAudits
.EXAMPLE
    .\wyndis.ps1 -ExportJson -ExportHistory
#>

[CmdletBinding(DefaultParameterSetName='Audit')]
param(
    # Audit modes
    [Parameter(ParameterSetName='Audit')][switch]$Quick,
    [Parameter(ParameterSetName='Audit')][switch]$Full,
    
    # Output options
    [Parameter(ParameterSetName='Audit')][switch]$NoColor,
    [Parameter(ParameterSetName='Audit')][switch]$NoPdf,
    [Parameter(ParameterSetName='Audit')][string]$ReportPath,
    
    # Enterprise Report v4.0
    [Parameter(ParameterSetName='Audit')][switch]$EnterpriseReport,
    [Parameter(ParameterSetName='Audit')][switch]$ExecutiveOnly,
    [Parameter(ParameterSetName='Audit')][switch]$TechnicalOnly,
    [Parameter(ParameterSetName='Audit')][switch]$IncludeTimeline,
    [Parameter(ParameterSetName='Audit')][switch]$IncludeConfidence,
    [Parameter(ParameterSetName='Audit')][switch]$ExportJson,
    [Parameter(ParameterSetName='Audit')][int]$ConfidenceThreshold = 70,
    
    # Hardening Engine
    [Parameter(ParameterSetName='Hardening')][switch]$Hardening,
    [Parameter(ParameterSetName='Hardening')][switch]$HardeningAuto,
    [Parameter(ParameterSetName='Hardening')][switch]$HardeningDryRun,
    [Parameter(ParameterSetName='Hardening')][string]$HardeningCategory,
    
    # Security Advisor v4.0
    [Parameter(ParameterSetName='Advisor')][switch]$SecurityAdvisor,
    [Parameter(ParameterSetName='Advisor')][switch]$SimulateAttack,
    [Parameter(ParameterSetName='Advisor')][switch]$GenerateRoadmap,
    [Parameter(ParameterSetName='Advisor')][int]$AdvisorConfidenceThreshold = 70,
    
    # History & Timeline
    [Parameter(ParameterSetName='History')][switch]$ShowTimeline,
    [Parameter(ParameterSetName='History')][int]$TimelineDays = 90,
    [Parameter(ParameterSetName='History')][switch]$CompareAudits,
    [Parameter(ParameterSetName='History')][switch]$ExportHistory,
    [Parameter(ParameterSetName='History')][string]$HistoryOutputPath,
    [Parameter(ParameterSetName='History')][int]$HistoryDays = 365,
    
    # Export
    [Parameter(ParameterSetName='Export')][switch]$ExportJson,
    [Parameter(ParameterSetName='Export')][string]$JsonOutputPath
)

$ErrorActionPreference = 'SilentlyContinue'
$Script:WyndisVersion = '4.0.0'
$Script:WyndisStartTime = Get-Date
$Script:Findings = [System.Collections.Generic.List[object]]::new()
$Script:ReportLines = [System.Collections.Generic.List[string]]::new()
$Script:ModulesExecuted = 0
$Script:ConfidenceThreshold = $ConfidenceThreshold

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
        Write-WyndisWarning 'No se ejecuta como Administrador. Muchas comprobaciones serán limitadas.'
        Write-WyndisSuggest 'Ejecuta: clic derecho en PowerShell -> "Ejecutar como administrador"'
    }

    # Parameter set detection
    $psName = $PSCmdlet.ParameterSetName
    
    switch ($psName) {
        'Hardening' {
            Write-WyndisSection 'MODO HARDENING v4.0 (Reversible, Transparente, Seguro)'
            Invoke-WyndisHardening -AutoConfirm:$HardeningAuto -DryRun:$HardeningDryRun -OnlyCategories $(if ($HardeningCategory) { @($HardeningCategory -split ',') })
            return
        }
        
        'Advisor' {
            Write-WyndisSection 'SECURITY ADVISOR v4.0 - Simulación de Ataque Real'
            Invoke-WyndisSecurityAdvisor -SimulateAttack:$SimulateAttack -GenerateRoadmap:$GenerateRoadmap -ConfidenceThreshold $AdvisorConfidenceThreshold
            return
        }
        
        'History' {
            if ($ShowTimeline) {
                Show-WyndisTimeline -Days $TimelineDays
            }
            if ($CompareAudits) {
                Compare-WyndisAudits
            }
            if ($ExportHistory) {
                $path = if ($HistoryOutputPath) { $HistoryOutputPath } else { "$env:USERPROFILE\Desktop\Wyndis-History-$(Get-Date -Format 'yyyyMMdd').json" }
                Export-WyndisHistoryJson -OutputPath $path -Days $HistoryDays
            }
            return
        }
        
        'Export' {
            if ($ExportJson) {
                $path = if ($JsonOutputPath) { $JsonOutputPath } else { "$env:USERPROFILE\Desktop\Wyndis-Export-$(Get-Date -Format 'yyyyMMdd-HHmmss').json" }
                $export = @{
                    Version     = $Script:WyndisVersion
                    Timestamp   = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
                    DurationSec = $Script:AuditDuration
                    Host        = $Script:SystemInfo.ComputerName
                    OS          = $Script:SystemInfo.OSName
                    Kernel      = $Script:SystemInfo.OSVersion
                    User        = "$($Script:SystemInfo.UserName)@$($Script:SystemInfo.Domain)"
                    IsAdmin     = $Script:SystemInfo.IsAdmin
                    Score       = $Script:Score
                    Findings    = $Script:Findings
                    AttackSim   = $global:WyndisAttackSimulation
                    Roadmap     = $global:WyndisRoadmap
                    History     = Load-WyndisHistory -Limit 50
                }
                $export | ConvertTo-Json -Depth 8 | Out-File -FilePath $path -Encoding UTF8
                Write-WyndisOk "JSON exportado: $path"
            }
            return
        }
        
        default {  # Audit
            # Run full audit
            Write-WyndisSection '1. Información del sistema'
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

            Write-WyndisSection '8. Programas de inicio automático'
            Invoke-WyndisStartupAudit

            Write-WyndisSection '9. Auditoría de Red'
            Invoke-WyndisNetworkAudit

            Write-WyndisSection '10. Auditoría de Cifrado'
            Invoke-WyndisEncryptionAudit

            Write-WyndisSection '11. Baseline CIS'
            Invoke-WyndisCISBaseline

            Write-WyndisSection '12. Privacidad y Telemetría'
            Invoke-WyndisPrivacyAudit

            Write-WyndisSection '13. Administración Remota (WinRM)'
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

            Write-WyndisSection '19. Políticas de Grupo'
            Invoke-WyndisGroupPolicyAudit

            Write-WyndisSection '20. Certificados'
            Invoke-WyndisCertificateAudit

            Write-WyndisSection '21. Registros de Eventos'
            Invoke-WyndisEventLogAudit

            Write-WyndisSection '22. Seguridad de PowerShell'
            Invoke-WyndisPowerShellAudit

            Write-WyndisSection '23. Políticas de Auditoría'
            Invoke-WyndisAuditPolicyAudit

            # Purple Team / Enterprise modules
            Write-WyndisSection '24. Attack Path Analysis (Purple Team)'
            Invoke-WyndisAttackPathAudit

            Write-WyndisSection '25. AD CS / Certificate Abuse (ESC1-ESC13)'
            Invoke-WyndisADCS

            Write-WyndisSection '26. LOLBin Detection (Living Off The Land)'
            Invoke-WyndisLOLBinsAudit

            Write-WyndisSection '27. Kerberos Deep Audit (Delegaciones, SPN, RBCD)'
            Invoke-WyndisKerberosAudit

            Write-WyndisSection '28. Persistence Advanced (WMI, COM, IFEO, Shim, AppInit)'
            Invoke-WyndisPersistenceAudit

            if (-not $Quick) {
                Write-WyndisSection '29. Contenedores y Virtualización'
                Invoke-WyndisContainerAudit

                Write-WyndisSection '30. Aplicaciones instaladas'
                Invoke-WyndisApplicationsAudit

                Write-WyndisSection '31. Vida útil del sistema'
                Invoke-WyndisSystemLifeAudit

                Write-WyndisSection '32. Recomendaciones de herramientas'
                Invoke-WyndisToolRecommendations
            }

            Write-WyndisSection 'Resumen y puntuación'
            $score = Get-WyndisScore
            Show-WyndisScore $score

            $elapsed = (Get-Date) - $Script:WyndisStartTime
            $Script:AuditDuration = $elapsed.TotalSeconds.ToString('F1')

            # Save snapshot for history/timeline
            Save-WyndisAuditSnapshot -Score $score

            # Enterprise Report v4.0
            if ($EnterpriseReport) {
                Write-WyndisSection 'GENERANDO INFORME ENTERPRISE v4.0 (Dual-Mode + Timeline + Confidence)'
                Export-WyndisEnterpriseReport -Score $score -ExecutiveOnly:$ExecutiveOnly -TechnicalOnly:$TechnicalOnly `
                    -IncludeTimeline:$IncludeTimeline -IncludeConfidence:$IncludeConfidence -ExportJson:$ExportJson
                return
            }

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
            Write-WyndisInfo "Auditoría completada en $($Script:AuditDuration) segundos."
            Write-WyndisInfo "Módulos ejecutados: $Script:ModulesExecuted | Hallazgos: $($score.Total)"
            Write-WyndisInfo 'Wyndis v4.0 - 100% gratuito bajo licencia MIT.'
            Write-WyndisInfo 'Web: https://github.com/octcenano/wyndis | Contacto: wyndis.help@gmail.com'

            if (-not $NoPdf) {
                Write-Host ''
                Write-WyndisInfo "PDF guardado en el escritorio: Wyndis-Informe-$(Get-Date -Format 'yyyyMMdd-HHmmss').pdf"
                Write-WyndisInfo "También disponible en: $pdf"
            }
        }
    }
}

Start-Wyndis