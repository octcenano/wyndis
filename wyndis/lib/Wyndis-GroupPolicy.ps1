# SPDX-License-Identifier: MIT
# Wyndis - Group Policy audit

function Invoke-WyndisGroupPolicyAudit {
    Write-WyndisInfo '--- Auditoria de Politicas de Grupo ---'

    $gpoPaths = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'; Name = 'Windows Update Auto Update' }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'; Name = 'Terminal Services Policy' }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name = 'Windows Update Policy' }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkConnections'; Name = 'Network Connections Policy' }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'; Name = 'Script Block Logging' }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers'; Name = 'Software Restriction Policies' }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer'; Name = 'Windows Installer Policy' }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog'; Name = 'Event Log Policy' }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation'; Name = 'Credential Delegation Policy' }
    )

    $gpoFound = 0
    foreach ($g in $gpoPaths) {
        try {
            $result = Get-ItemProperty -Path $g.Path -ErrorAction Stop
            if ($result) {
                $gpoFound++
                Write-WyndisInfo "GPO detectada: $($g.Name)"
            }
        } catch {}
    }

    if ($gpoFound -eq 0) {
        Write-WyndisInfo 'No se detectaron politicas de grupo avanzadas (entorno domestico tipico).'
    } else {
        Write-WyndisInfo "Total politicas de grupo detectadas: $gpoFound"
    }

    try {
        $psLogging = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -Name 'EnableScriptBlockLogging' -ErrorAction SilentlyContinue
        if ($psLogging -and $psLogging.EnableScriptBlockLogging -eq 1) {
            Write-WyndisOk 'Script Block Logging de PowerShell activo (deteccion de ataques).'
        } else {
            Write-WyndisWarning 'Script Block Logging de PowerShell NO activo.' 'GPO-001'
            Write-WyndisSuggest 'Activa Script Block Logging via GPO para detectar ataques PowerShell.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar PowerShell logging GPO.'
    }

    try {
        $transcript = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription' -Name 'EnableTranscripting' -ErrorAction SilentlyContinue
        if ($transcript -and $transcript.EnableTranscripting -eq 1) {
            Write-WyndisOk 'PowerShell Transcription activo.'
        } else {
            Write-WyndisSuggest 'Considera activar PowerShell Transcription para auditoria.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar PowerShell transcription.'
    }

    try {
        $rdpNla = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'UserAuthentication' -ErrorAction SilentlyContinue
        if ($rdpNla -and $rdpNla.UserAuthentication -eq 0) {
            Write-WyndisCritical 'GPO: RDP sin NLA forzado por politica.' 'GPO-002'
        }
    } catch {}
}
