# SPDX-License-Identifier: MIT
# Wyndis - Firewall audit

function Invoke-WyndisFirewallAudit {
    try {
        $profiles = Get-NetFirewallProfile -ErrorAction Stop
    } catch {
        Write-WyndisWarning 'No se pudo consultar el firewall (¿permisos insuficientes?).' 'FW-001'
        Write-WyndisSuggest 'Ejecuta Wyndis como Administrador.'
        return
    }

    $allEnabled = $true
    foreach ($profile in $profiles) {
        $status = if ($profile.Enabled) { 'activo' } else { 'DESACTIVADO' }
        if ($profile.Enabled) {
            Write-WyndisOk "Perfil '$($profile.Name)': $status"
        } else {
            Write-WyndisCritical "Perfil '$($profile.Name)': firewall $status" "FW-002-$($profile.Name)"
            Write-WyndisSuggest "Activa el firewall: Set-NetFirewallProfile -Profile $($profile.Name) -Enabled True"
            $allEnabled = $false
        }

        $defaultIn = $profile.DefaultInboundAction
        $defaultOut = $profile.DefaultOutboundAction
        Write-WyndisInfo "  Entrada predeterminada: $defaultIn | Salida: $defaultOut"

        if ($defaultIn -eq 'Allow') {
            Write-WyndisWarning "Perfil '$($profile.Name)': tráfico entrante permitido por defecto." "FW-003-$($profile.Name)"
            Write-WyndisSuggest 'Configura la acción entrante predeterminada como Block.'
        }
    }

    if ($allEnabled) {
        Write-WyndisOk 'Todos los perfiles de firewall están activos.'
    }

    # Reglas peligrosas: RDP abierto a todos
    try {
        $rdpRules = Get-NetFirewallRule -DisplayGroup 'Escritorio remoto' -ErrorAction SilentlyContinue |
            Where-Object { $_.Enabled -eq 'True' -and $_.Direction -eq 'Inbound' }
        if (-not $rdpRules) {
            $rdpRules = Get-NetFirewallRule -DisplayName '*Remote Desktop*' -ErrorAction SilentlyContinue |
                Where-Object { $_.Enabled -eq 'True' -and $_.Direction -eq 'Inbound' }
        }

        foreach ($rule in $rdpRules) {
            Write-WyndisWarning "Regla de firewall activa: $($rule.DisplayName)" 'FW-004'
        }
    } catch {
        Write-WyndisInfo 'No se pudieron revisar reglas RDP del firewall.'
    }

    # Puertos abiertos comunes
    try {
        $listening = Get-NetTCPConnection -State Listen -ErrorAction Stop |
            Select-Object LocalPort, OwningProcess -Unique |
            Sort-Object LocalPort

        $riskyPorts = @{
            21   = 'FTP'
            23   = 'Telnet'
            135  = 'RPC'
            139  = 'NetBIOS'
            445  = 'SMB'
            3389 = 'RDP'
            5900 = 'VNC'
        }

        foreach ($conn in $listening) {
            $port = $conn.LocalPort
            if ($riskyPorts.ContainsKey($port)) {
                $procName = try {
                    (Get-Process -Id $conn.OwningProcess -ErrorAction Stop).ProcessName
                } catch { 'desconocido' }
                Write-WyndisWarning "Puerto $port ($($riskyPorts[$port])) escuchando - proceso: $procName" "FW-PORT-$port"
            }
        }

        Write-WyndisInfo "Puertos en escucha: $($listening.Count)"
    } catch {
        Write-WyndisInfo 'Revisión de puertos limitada sin privilegios elevados.'
    }
}
