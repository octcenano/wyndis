# SPDX-License-Identifier: MIT
# Wyndis - Core utilities

function Test-WyndisAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Add-WyndisFinding {
    param(
        [ValidateSet('critical', 'warning', 'info')]
        [string]$Severity,
        [string]$Message,
        [string]$Id = '',
        [string]$Category = 'general'
    )
    $Script:Findings.Add([PSCustomObject]@{
        Severity = $Severity
        Message  = $Message
        Id       = $Id
        Category = $Category
        Time     = Get-Date
    })
}

function Invoke-WyndisSystemInfo {
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem

    Write-WyndisInfo "Equipo: $($cs.Name)"
    Write-WyndisInfo "SO: $($os.Caption) ($($os.Version))"
    Write-WyndisInfo "Arquitectura: $($os.OSArchitecture)"
    Write-WyndisInfo "Ultimo arranque: $($os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm'))"

    $uptime = (Get-Date) - $os.LastBootUpTime
    Write-WyndisInfo "Tiempo activo: $([math]::Floor($uptime.TotalDays)) dias, $($uptime.Hours) horas"

    if ($uptime.TotalDays -gt 30) {
        Write-WyndisWarning 'El sistema lleva mas de 30 dias sin reiniciar.' 'SYS-001'
        Write-WyndisSuggest 'Reinicia periodicamente para aplicar actualizaciones pendientes.'
    } else {
        Write-WyndisOk 'Tiempo de actividad razonable.'
    }

    $logicalCores = 0
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    if ($cpu) { $logicalCores = $cpu.NumberOfLogicalProcessors }
    return @{ Os = $os; Cs = $cs; CpuCores = $logicalCores }
}

function Export-WyndisReport {
    param(
        [string]$Path,
        [hashtable]$Score
    )

    $header = @"
===============================================================================
  WYNDIS - Informe de auditoria
  Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
  Version: $Script:WyndisVersion
  Puntuacion: $($Score.Grade)/100 ($($Score.Label))
  Contacto: wyndis.help@gmail.com
===============================================================================

"@

    $findingsText = ''
    foreach ($f in $Script:Findings) {
        $findingsText += "[$($f.Severity.ToUpper())] [$($f.Category)] $($f.Message)`n"
    }

    $content = $header + ($Script:ReportLines -join "`n") + "`n`n--- HALLAZGOS ---`n`n" + $findingsText
    try {
        $content | Out-File -FilePath $Path -Encoding UTF8
        Write-WyndisOk "Informe guardado en: $Path"
    } catch {
        Write-WyndisWarning "No se pudo guardar el informe: $_"
    }
}
