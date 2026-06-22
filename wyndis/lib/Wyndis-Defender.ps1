# SPDX-License-Identifier: MIT
# Wyndis - Windows Defender (antivirus integrado)

function Invoke-WyndisDefenderAudit {
    try {
        $status = Get-MpComputerStatus -ErrorAction Stop
    } catch {
        Write-WyndisWarning 'No se pudo consultar Windows Defender.' 'DEF-001'
        Write-WyndisSuggest 'Verifica que Windows Defender esté instalado y ejecuta como Administrador.'
        return
    }

    if ($status.AntivirusEnabled) {
        Write-WyndisOk 'Antivirus (Windows Defender) activo.'
    } else {
        Write-WyndisCritical 'Antivirus desactivado.' 'DEF-002'
        Write-WyndisSuggest 'Activa Windows Defender en Seguridad de Windows.'
    }

    if ($status.RealTimeProtectionEnabled) {
        Write-WyndisOk 'Protección en tiempo real activa.'
    } else {
        Write-WyndisCritical 'Protección en tiempo real desactivada.' 'DEF-003'
    }

    if ($status.IoavProtectionEnabled) {
        Write-WyndisOk 'Protección contra descargas y adjuntos activa.'
    } else {
        Write-WyndisWarning 'Protección IOAV desactivada.' 'DEF-004'
    }

    if ($status.BehaviorMonitorEnabled) {
        Write-WyndisOk 'Monitor de comportamiento activo.'
    } else {
        Write-WyndisWarning 'Monitor de comportamiento desactivado.' 'DEF-005'
    }

    if ($status.IsTamperProtected) {
        Write-WyndisOk 'Protección contra manipulación (Tamper Protection) activa.'
    } else {
        Write-WyndisWarning 'Tamper Protection desactivada.' 'DEF-006'
        Write-WyndisSuggest 'Actívala en Seguridad de Windows -> Protección contra virus.'
    }

    if ($status.AMServiceEnabled) {
        Write-WyndisOk 'Servicio antimalware en ejecución.'
    } else {
        Write-WyndisCritical 'Servicio antimalware detenido.' 'DEF-007'
    }

    # Firmas
    if ($status.AntivirusSignatureAge -le 3) {
        Write-WyndisOk "Firmas actualizadas (antigüedad: $($status.AntivirusSignatureAge) días)."
    } elseif ($status.AntivirusSignatureAge -le 7) {
        Write-WyndisWarning "Firmas con $($status.AntivirusSignatureAge) días de antigüedad." 'DEF-008'
    } else {
        Write-WyndisCritical "Firmas muy desactualizadas ($($status.AntivirusSignatureAge) días)." 'DEF-009'
        Write-WyndisSuggest 'Actualiza firmas: Update-MpSignature'
    }

    Write-WyndisInfo "Último escaneo rápido: $($status.QuickScanStartTime)"
    Write-WyndisInfo "Último escaneo completo: $($status.FullScanStartTime)"

    $daysSinceFull = if ($status.FullScanEndTime) {
        ((Get-Date) - $status.FullScanEndTime).Days
    } else { 999 }

    if ($daysSinceFull -gt 30) {
        Write-WyndisWarning 'No se ha realizado un escaneo completo en más de 30 días.' 'DEF-010'
        Write-WyndisSuggest 'Ejecuta un escaneo completo: Start-MpScan -ScanType FullScan'
    }

    # Otro antivirus instalado (puede desactivar Defender)
    try {
        $avProducts = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction Stop
        foreach ($av in $avProducts) {
            $avName = $av.displayName
            if ($avName -notmatch 'Windows Defender|Microsoft Defender') {
                Write-WyndisInfo "Otro antivirus detectado: $avName"
                if (-not $status.AntivirusEnabled) {
                    Write-WyndisWarning 'Defender desactivado, posiblemente por otro antivirus.' 'DEF-011'
                }
            }
        }
    } catch {
        Write-WyndisInfo 'No se pudo listar productos antivirus de SecurityCenter2.'
    }

    # Exclusiones peligrosas
    try {
        $prefs = Get-MpPreference -ErrorAction Stop
        $exclusions = @($prefs.ExclusionPath) + @($prefs.ExclusionExtension) + @($prefs.ExclusionProcess)
        $exclusions = $exclusions | Where-Object { $_ }

        if ($exclusions.Count -gt 0) {
            Write-WyndisInfo "Exclusiones de Defender: $($exclusions.Count)"
            foreach ($ex in $exclusions | Select-Object -First 5) {
                Write-WyndisInfo "  - $ex"
                if ($ex -match '^(C:\\|C:/)' -and $ex -notmatch '\\Windows\\|\\Program Files') {
                    Write-WyndisWarning "Exclusión amplia detectada: $ex" 'DEF-012'
                }
            }
        } else {
            Write-WyndisOk 'Sin exclusiones configuradas en Defender.'
        }
    } catch {
        Write-WyndisInfo 'No se pudieron revisar exclusiones de Defender.'
    }
}
