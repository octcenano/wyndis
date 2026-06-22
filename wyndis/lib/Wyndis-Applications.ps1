# SPDX-License-Identifier: MIT
# Wyndis - Installed applications audit

function Invoke-WyndisApplicationsAudit {
    $apps = [System.Collections.Generic.List[object]]::new()

    # Registro 64-bit y 32-bit
    $regPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    foreach ($regPath in $regPaths) {
        try {
            Get-ItemProperty $regPath -ErrorAction Stop |
                Where-Object { $_.DisplayName } |
                ForEach-Object {
                    $apps.Add([PSCustomObject]@{
                        Name    = $_.DisplayName
                        Version = $_.DisplayVersion
                        Publisher = $_.Publisher
                        InstallDate = $_.InstallDate
                    })
                }
        } catch { }
    }

    $uniqueApps = $apps | Sort-Object Name -Unique
    Write-WyndisInfo "Aplicaciones instaladas detectadas: $($uniqueApps.Count)"

    # Software potencialmente innecesario o de riesgo
    $riskySoftware = @{
        'TeamViewer'        = 'Herramienta de acceso remoto - asegura contraseñas fuertes'
        'AnyDesk'           = 'Acceso remoto - revisa configuración'
        'uTorrent'          = 'Cliente P2P - riesgo de malware'
        'BitTorrent'        = 'Cliente P2P - riesgo de malware'
        'CCleaner'          = 'Revisar versión - historial de incidentes'
        'Adobe Flash'       = 'Flash está obsoleto y es vulnerable'
        'Java 6'            = 'Java antiguo - actualizar o eliminar'
        'Java 7'            = 'Java antiguo - actualizar o eliminar'
        'Wireshark'         = 'Sniffer de red - solo si es necesario'
        'Npcap'             = 'Captura de paquetes - revisar necesidad'
        'OpenVPN'           = 'VPN - verificar configuración'
        'VirtualBox'        = 'Virtualización - mantener actualizado'
        'VMware'            = 'Virtualización - mantener actualizado'
    }

    $foundRisky = 0
    foreach ($app in $uniqueApps) {
        foreach ($pattern in $riskySoftware.Keys) {
            if ($app.Name -match [regex]::Escape($pattern)) {
                Write-WyndisWarning "$($app.Name) v$($app.Version) - $($riskySoftware[$pattern])" "APP-$pattern"
                $foundRisky++
            }
        }
    }

    if ($foundRisky -eq 0) {
        Write-WyndisOk 'No se detectó software de riesgo conocido.'
    }

    # Software desactualizado (sin desinstalador / versiones muy antiguas)
    $oldPatterns = @('200[0-9]', '201[0-5]', 'v1\.', 'v2\.0', 'v3\.0')
    foreach ($app in $uniqueApps | Select-Object -First 200) {
        if ($app.Version -and ($app.Version -match ($oldPatterns -join '|'))) {
            Write-WyndisInfo "Posible software antiguo: $($app.Name) v$($app.Version)"
        }
    }

    # Mostrar top 10 apps instaladas recientemente
    $recent = $uniqueApps | Where-Object { $_.InstallDate -match '^\d{8}$' } |
        Sort-Object InstallDate -Descending |
        Select-Object -First 5

    if ($recent) {
        Write-WyndisInfo 'Instalaciones recientes:'
        foreach ($r in $recent) {
            $date = if ($r.InstallDate.Length -eq 8) {
                "$($r.InstallDate.Substring(0,4))-$($r.InstallDate.Substring(4,2))-$($r.InstallDate.Substring(6,2))"
            } else { $r.InstallDate }
            Write-WyndisInfo "  - $($r.Name) ($date)"
        }
    }
}
