# SPDX-License-Identifier: MIT
# Wyndis - Event log configuration audit

function Invoke-WyndisEventLogAudit {
    Write-WyndisInfo '--- Auditoria de Registros de Eventos ---'

    $logNames = @(
        @{ Name = 'Application'; MaxSize = 20MB }
        @{ Name = 'System'; MaxSize = 20MB }
        @{ Name = 'Security'; MaxSize = 80MB }
        @{ Name = 'Windows PowerShell'; MaxSize = 15MB }
        @{ Name = 'Microsoft-Windows-PowerShell/Operational'; MaxSize = 15MB }
        @{ Name = 'Microsoft-Windows-Windows Firewall With Advanced Security/Firewall'; MaxSize = 10MB }
    )

    foreach ($log in $logNames) {
        try {
            $logInfo = Get-WmiObject -Class Win32_NTEventlogFile -Filter "LogFileName='$($log.Name)'" -ErrorAction Stop
            $currentSize = $logInfo.FileSize
            $maxSize = $log.MaxSize
            $currentMB = [math]::Round($currentSize / 1MB, 1)
            $maxMB = [math]::Round($maxSize / 1MB, 1)

            if ($currentSize -gt 0) {
                Write-WyndisInfo "Log '$($log.Name)': ${currentMB}MB usado (max: ${maxMB}MB)"
            }

            if ($log.Name -eq 'Security' -and $currentSize -lt 80MB) {
                Write-WyndisWarning "Log de seguridad menor de 80MB - puede no retener suficientes eventos." 'EVT-001'
                Write-WyndisSuggest "Aumenta el log de seguridad: wevtutil sl Security /ms:209715200"
            }
        } catch {
            Write-WyndisInfo "No se pudo verificar log '$($log.Name)'."
        }
    }

    try {
        $logConfigs = @(
            @{ Name = 'Application'; Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application' }
            @{ Name = 'System'; Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\System' }
            @{ Name = 'Security'; Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Security' }
        )

        foreach ($lc in $logConfigs) {
            try {
                $reg = Get-ItemProperty -Path $lc.Path -ErrorAction Stop
                $retention = $reg.Retention
                $maxSizeBytes = $reg.MaxSize
                if ($reg -and $reg.Retention -eq '0') {
                    Write-WyndisWarning "Log '$($lc.Name)': retencion configurada para sobrescribir eventos." 'EVT-002'
                }
            } catch {}
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar configuracion de retencion de logs.'
    }

    try {
        $auditPolicies = auditpol /get /category:* 2>$null
        if ($auditPolicies) {
            $criticalPolicies = @(
                'Logon/Logoff',
                'Account Logon',
                'Account Management',
                'Detailed Tracking',
                'DS Access',
                'Object Access',
                'Policy Change',
                'Privilege Use',
                'System'
            )

            foreach ($cp in $criticalPolicies) {
                $match = $auditPolicies | Select-String $cp
                if ($match) {
                    if ($match -match 'Success|Failure|Success and Failure') {
                        Write-WyndisOk "Auditoria activa: $cp"
                    } else {
                        Write-WyndisWarning "Auditoria NO activa: $cp" 'EVT-003'
                    }
                }
            }
            Write-WyndisSuggest 'Revisa politicas de auditoria: auditpol /get /category:*'
        }
    } catch {
        Write-WyndisInfo 'No se pudieron verificar politicas de auditoria avanzadas.'
    }
}
