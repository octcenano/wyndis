# SPDX-License-Identifier: MIT
# Wyndis - WiFi security audit

function Invoke-WyndisWiFiAudit {
    Write-WyndisInfo '--- Auditoria de WiFi ---'

    try {
        $wlanInterfaces = Get-NetAdapter -Name '*Wi-Fi*' -ErrorAction Stop
        if (-not $wlanInterfaces) {
            $wlanInterfaces = Get-NetAdapter -Name '*Wireless*' -ErrorAction SilentlyContinue
        }

        if (-not $wlanInterfaces) {
            Write-WyndisInfo 'No se detectaron interfaces WiFi.'
            return
        }

        Write-WyndisInfo "Interfaces WiFi detectadas: $($wlanInterfaces.Count)"

        $profiles = netsh wlan show profiles 2>$null | Select-String 'Perfil de todos los usuarios'
        if (-not $profiles) {
            $profiles = netsh wlan show profiles 2>$null | Select-String 'All User Profile'
        }

        if ($profiles) {
            Write-WyndisInfo "Perfiles WiFi guardados: $($profiles.Count)"
            foreach ($profile in $profiles) {
                $ssid = ($profile -split ':')[1].Trim()
                $detail = netsh wlan show profile name="$ssid" key=clear 2>$null
                $auth = if ($detail -match 'Autenticaci.n\s*:\s*(.+)') { $matches[1] } else { '?' }
                $cipher = if ($detail -match 'Cifrado\s*:\s*(.+)') { $matches[1] } else { '?' }
                $keyContent = if ($detail -match 'Contenido de la clave\s*:\s*(.+)') { $matches[1] } else { $null }

                Write-WyndisInfo "  Red: $ssid | Autenticacion: $auth | Cifrado: $cipher"

                if ($auth -match 'WPA2|WPA3') {
                    Write-WyndisOk "  $ssid usa cifrado seguro ($auth)."
                } elseif ($auth -match 'WEP|Open') {
                    Write-WyndisCritical "  $ssid usa cifrado debil ($auth) - RIESGO." 'WIFI-001'
                    Write-WyndisSuggest "Actualiza el router: cambia $ssid a WPA2 o WPA3."
                }

                if ($keyContent) {
                    Write-WyndisWarning "  Contrasena WiFi visible en texto plano para $ssid." 'WIFI-002'
                }
            }
        } else {
            Write-WyndisOk 'Sin perfiles WiFi guardados.'
        }
    } catch {
        Write-WyndisWarning 'No se pudieron revisar redes WiFi.' 'WIFI-003'
        Write-WyndisSuggest 'Ejecuta como Administrador para ver detalles WiFi.'
    }
}
