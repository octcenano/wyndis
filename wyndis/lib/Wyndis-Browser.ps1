# SPDX-License-Identifier: MIT
# Wyndis - Browser security audit

function Invoke-WyndisBrowserAudit {
    Write-WyndisInfo '--- Auditoria de Navegadores ---'

    $browsers = @(
        @{ Name = 'Google Chrome'; Path = "$env:LOCALAPPDATA\Google\Chrome\User Data" },
        @{ Name = 'Microsoft Edge'; Path = "$env:LOCALAPPDATA\Microsoft\Edge\User Data" },
        @{ Name = 'Brave'; Path = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data" },
        @{ Name = 'Firefox'; Path = "$env:APPDATA\Mozilla\Firefox\Profiles" }
    )

    $foundCount = 0
    foreach ($b in $browsers) {
        $exists = Test-Path $b.Path
        if ($exists) {
            Write-WyndisInfo "Navegador detectado: $($b.Name)"
            $foundCount++
        }
        if ($b.Name -eq 'Google Chrome' -and $exists) {
            try {
                $prefsPath = Join-Path $b.Path 'Default\Preferences'
                if (Test-Path $prefsPath) {
                    $prefs = Get-Content $prefsPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($prefs) {
                        $extCount = ($prefs.extensions.settings.PSObject.Properties | Where-Object { $_ }).Count
                        Write-WyndisInfo "  Extensiones Chrome: $extCount"
                        $pwCheck = $prefs.profile.password_manager_enabled
                        if ($pwCheck -eq $true) {
                            Write-WyndisWarning 'Chrome: gestor de contrasenas integrado activo.' 'BRW-001'
                            Write-WyndisSuggest 'Usa Bitwarden en lugar del gestor integrado del navegador.'
                        }
                    }
                }
            } catch {
                Write-WyndisInfo '  No se pudo analizar preferencias de Chrome.'
            }
        }
        if ($b.Name -eq 'Firefox' -and $exists) {
            try {
                $profiles = Get-ChildItem $b.Path -Directory -ErrorAction SilentlyContinue
                foreach ($profile in $profiles) {
                    $prefsjs = Join-Path $profile.FullName 'prefs.js'
                    if (Test-Path $prefsjs) {
                        $content = Get-Content $prefsjs -Raw
                        $dohEnabled = $content -match 'network\.trr\.mode.*2'
                        if ($dohEnabled) {
                            Write-WyndisOk '  Firefox: DNS-over-HTTPS activo.'
                        } else {
                            Write-WyndisSuggest '  Firefox: activa DNS-over-HTTPS en Configuracion de red.'
                        }
                    }
                }
            } catch {
                Write-WyndisInfo '  No se pudo analizar Firefox.'
            }
        }
    }

    try {
        $chromePolicy = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Google\Chrome' -ErrorAction SilentlyContinue
        $edgePolicy = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -ErrorAction SilentlyContinue
        if ($chromePolicy -or $edgePolicy) {
            Write-WyndisInfo 'Politicas de navegador detectadas (entorno gestionado).'
        } else {
            Write-WyndisInfo 'Sin politicas corporativas de navegador.'
        }
    } catch {
        Write-WyndisInfo 'No se pudieron verificar politicas de navegador.'
    }

    if ($foundCount -eq 0) {
        Write-WyndisWarning 'No se detectaron navegadores modernos - ¿usas Internet Explorer?' 'BRW-002'
    }
}
