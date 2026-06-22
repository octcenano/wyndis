# SPDX-License-Identifier: MIT
# Wyndis - Advanced audit policy checks

function Invoke-WyndisAuditPolicyAudit {
    Write-WyndisInfo '--- Auditoria de Politicas de Auditoria Avanzadas ---'

    $categories = @(
        'System',
        'Logon/Logoff',
        'Object Access',
        'Privilege Use',
        'Detailed Tracking',
        'Policy Change',
        'Account Management',
        'DS Access',
        'Account Logon'
    )

    try {
        $auditpol = auditpol /get /category:* 2>$null
        if (-not $auditpol) {
            Write-WyndisInfo 'No se pudo ejecutar auditpol (requiere admin).'
            return
        }

        foreach ($cat in $categories) {
            $match = $auditpol | Select-String -Pattern $cat -SimpleMatch | Select-Object -First 1
            if ($match) {
                $parts = ($match -split '\s{2,}') | Where-Object { $_ -ne '' }
                if ($parts.Count -ge 2) {
                    $status = $parts[-1].Trim()
                    $enabledSettings = @('Success and Failure', 'Success', 'Failure')
                    if ($enabledSettings -contains $status) {
                        Write-WyndisOk "Auditoria '$cat': $status"
                    } elseif ($status -eq 'No Auditing') {
                        Write-WyndisWarning "Auditoria '$cat': No Auditing - no se registran eventos." 'ADT-001'
                    }
                }
            }
        }
    } catch {
        Write-WyndisInfo 'No se pudieron leer politicas de auditoria avanzadas.'
    }

    try {
        $sacls = Get-Acl -Path 'HKLM:\SECURITY' -ErrorAction SilentlyContinue
        if ($sacls) {
            $sddl = $sacls.Sddl
            if ($sddl -match 'S:.*AUDIT') {
                Write-WyndisOk 'SACLs configurados en el registro.'
            } else {
                Write-WyndisSuggest 'Considera configurar SACLs en el registro para auditoria avanzada.'
            }
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar SACLs del registro.'
    }

    try {
        $processAudit = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit' -Name 'ProcessCreationIncludeCmdLine_Enabled' -ErrorAction SilentlyContinue
        if ($processAudit -and $processAudit.ProcessCreationIncludeCmdLine_Enabled -eq 1) {
            Write-WyndisOk 'Linea de comandos en eventos de creacion de procesos activa (4688).'
        } else {
            Write-WyndisWarning 'Linea de comandos NO incluida en eventos 4688.' 'ADT-002'
            Write-WyndisSuggest 'Activa: auditpol /set /subcategory:"Process Creation" /include:cmdline'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar inclusion de cmdline en eventos.'
    }
}
