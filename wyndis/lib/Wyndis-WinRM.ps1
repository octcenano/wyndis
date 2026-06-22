# SPDX-License-Identifier: MIT
# Wyndis - Windows Remote Management audit

function Invoke-WyndisWinRMAudit {
    Write-WyndisInfo '--- Auditoria de Administracion Remota (WinRM) ---'

    try {
        $winrm = Get-Service -Name WinRM -ErrorAction SilentlyContinue
        if ($winrm) {
            if ($winrm.Status -eq 'Running') {
                Write-WyndisWarning 'WinRM (Remote Management) en ejecucion.' 'WRM-001'
                Write-WyndisSuggest 'Si no usas administracion remota, deten WinRM: Stop-Service WinRM -Force'
                try {
                    $winrmConfig = Get-Item WSMan:\localhost\Service\AllowUnencrypted -ErrorAction SilentlyContinue
                    if ($winrmConfig -and $winrmConfig.Value -eq 'true') {
                        Write-WyndisCritical 'WinRM permite trafico sin cifrar.' 'WRM-002'
                    }
                } catch {}
                try {
                    $httpsOnly = Get-Item WSMan:\localhost\Service\AllowUnencrypted -ErrorAction SilentlyContinue
                    if ($httpsOnly -and $httpsOnly.Value -eq 'false') {
                        Write-WyndisOk 'WinRM requiere cifrado (HTTPS).'
                    }
                } catch {}
            } else {
                Write-WyndisOk 'WinRM detenido.'
            }
            if ($winrm.StartType -eq 'Automatic') {
                Write-WyndisWarning 'WinRM configurado para inicio automatico.' 'WRM-003'
            }
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar WinRM.'
    }

    try {
        $psRemoting = Get-Item 'WSMan:\localhost\Client\TrustedHosts' -ErrorAction SilentlyContinue
        if ($psRemoting -and $psRemoting.Value -ne '') {
            Write-WyndisCritical "PowerShell Remoting: hosts confiables configurados: $($psRemoting.Value)" 'WRM-004'
            Write-WyndisSuggest 'Revisa los hosts confiables de PSRemoting - riesgo si no es entorno controlado.'
        } else {
            Write-WyndisOk 'PowerShell Remoting sin hosts confiables configurados.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar PSRemoting.'
    }

    try {
        $reg = Get-Service -Name RemoteRegistry -ErrorAction SilentlyContinue
        if ($reg -and $reg.Status -eq 'Running') {
            Write-WyndisCritical 'Remote Registry en ejecucion - permite modificar registro remotamente.' 'WRM-005'
            Write-WyndisSuggest 'Deten RemoteRegistry: Stop-Service RemoteRegistry -Force'
        } else {
            Write-WyndisOk 'Remote Registry detenido.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar Remote Registry.'
    }

    try {
        $secLogon = Get-Service -Name seclogon -ErrorAction SilentlyContinue
        if ($secLogon -and $secLogon.Status -eq 'Running') {
            Write-WyndisInfo 'Secondary Logon en ejecucion (necesario para "Ejecutar como...").'
        }
    } catch {}
}
