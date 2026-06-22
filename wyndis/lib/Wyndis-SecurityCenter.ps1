# SPDX-License-Identifier: MIT
# Wyndis - Windows Security Center audit

function Invoke-WyndisSecurityCenterAudit {
    Write-WyndisInfo '--- Auditoria de Seguridad de Windows ---'

    try {
        $secCenter = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction Stop
        $avCount = 0
        foreach ($av in $secCenter) {
            $avName = $av.displayName
            if ($av.productState -band 1) {
                Write-WyndisOk "Antivirus activo: $avName"
                $avCount++
            } else {
                Write-WyndisWarning "Antivirus inactivo: $avName" 'SEC-001'
            }
        }
        if ($avCount -eq 0) {
            Write-WyndisCritical 'NINGUN antivirus activo detectado.' 'SEC-002'
        }
    } catch {
        Write-WyndisWarning 'No se pudo consultar Security Center.' 'SEC-003'
    }

    try {
        $firewallProducts = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName FirewallProduct -ErrorAction Stop
        foreach ($fw in $firewallProducts) {
            Write-WyndisInfo "Firewall detectado: $($fw.displayName)"
        }
    } catch {
        Write-WyndisInfo 'No se pudo listar productos de firewall.'
    }

    try {
        $defPref = Get-MpPreference -ErrorAction SilentlyContinue
        if ($defPref) {
            $props = @(
                @{ Name = 'PUAProtection'; Label = 'Proteccion PUA (apps no deseadas)'; Critical = 1; Id = 'SEC-004' }
                @{ Name = 'CloudBlockLevel'; Label = 'Nivel de bloqueo en la nube'; Warning = 'NotSet'; Id = 'SEC-005' }
                @{ Name = 'CloudTimeout'; Label = 'TimeOut de nube'; Warning = 0; Id = 'SEC-006' }
                @{ Name = 'DisableArchiveScanning'; Label = 'Escaneo de archivos comprimidos'; Critical = 0; Id = 'SEC-007' }
                @{ Name = 'DisableBehaviorMonitoring'; Label = 'Monitor de comportamiento'; Critical = 0; Id = 'SEC-008' }
                @{ Name = 'DisableBlockAtFirstSeen'; Label = 'Bloqueo en primera aparicion'; Critical = 0; Id = 'SEC-009' }
                @{ Name = 'DisableCatchupFullScan'; Label = 'Escaneo completo catch-up'; Warning = 0; Id = 'SEC-010' }
                @{ Name = 'DisableCatchupQuickScan'; Label = 'Escaneo rapido catch-up'; Warning = 0; Id = 'SEC-011' }
                @{ Name = 'DisableEmailScanning'; Label = 'Escaneo de correo'; Warning = 0; Id = 'SEC-012' }
                @{ Name = 'DisableRealtimeMonitoring'; Label = 'Monitor en tiempo real'; Critical = 0; Id = 'SEC-013' }
                @{ Name = 'DisableScanningMappedNetworkDrivesForFullScan'; Label = 'Escaneo de unidades de red'; Warning = 0; Id = 'SEC-014' }
                @{ Name = 'DisableScriptScanning'; Label = 'Escaneo de scripts'; Critical = 0; Id = 'SEC-015' }
            )

            foreach ($prop in $props) {
                $val = $defPref.$($prop.Name)
                if ($val -eq $prop.Critical -and $prop.ContainsKey('Critical')) {
                    Write-WyndisWarning "$($prop.Label) desactivada." $prop.Id
                } elseif ($val -eq $prop.Warning -and $prop.ContainsKey('Warning')) {
                    Write-WyndisWarning "$($prop.Label) en configuracion debil." $prop.Id
                } else {
                    if ($val -eq 1 -or ($val -is [int] -and $val -eq 1)) {
                        Write-WyndisOk "$($prop.Label) activa."
                    }
                }
            }
        }
    } catch {
        Write-WyndisInfo 'No se pudieron revisar preferencias avanzadas de Defender.'
    }

    try {
        $appLocker = Get-Service -Name AppIDSvc -ErrorAction SilentlyContinue
        if ($appLocker -and $appLocker.Status -eq 'Running') {
            Write-WyndisInfo 'AppLocker / AppID service activo (App Control).'
        } else {
            Write-WyndisSuggest 'Considera configurar AppLocker o Windows Defender Application Control.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar AppLocker.'
    }

    try {
        $sandbox = Get-WindowsOptionalFeature -Online -FeatureName 'Containers-DisposableClientVM' -ErrorAction SilentlyContinue
        if ($sandbox -and $sandbox.State -eq 'Enabled') {
            Write-WyndisOk 'Windows Sandbox disponible.'
        } else {
            Write-WyndisSuggest 'Considera activar Windows Sandbox (Windows 10/11 Pro).'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar Windows Sandbox.'
    }

    try {
        $smb1 = Get-WindowsOptionalFeature -Online -FeatureName 'SMB1Protocol' -ErrorAction SilentlyContinue
        if ($smb1 -and $smb1.State -eq 'Enabled') {
            Write-WyndisCritical 'SMB1 Protocol activo - extremadamente inseguro.' 'SEC-016'
            Write-WyndisSuggest 'Desactiva SMB1: Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol'
        } else {
            Write-WyndisOk 'SMB1 Protocol desactivado.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar SMB1 Protocol.'
    }
}
