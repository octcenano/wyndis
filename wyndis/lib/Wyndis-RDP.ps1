# SPDX-License-Identifier: MIT
# Wyndis - Remote Desktop (RDP) detection

function Invoke-WyndisRdpAudit {
    # fDenyTSConnections: 0 = RDP habilitado, 1 = deshabilitado
    try {
        $rdpKey = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -ErrorAction Stop
        $rdpEnabled = ($rdpKey.fDenyTSConnections -eq 0)

        if ($rdpEnabled) {
            Write-WyndisWarning 'Escritorio remoto (RDP) está HABILITADO.' 'RDP-001'
            Write-WyndisSuggest 'Si no lo necesitas: desactívalo en Configuración -> Sistema -> Escritorio remoto.'
        } else {
            Write-WyndisOk 'Escritorio remoto deshabilitado.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar estado de RDP en el registro.'
    }

    # NLA (Network Level Authentication)
    try {
        $nla = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -ErrorAction Stop
        if ($nla.UserAuthentication -eq 1) {
            Write-WyndisOk 'NLA (autenticación a nivel de red) activa para RDP.'
        } else {
            Write-WyndisCritical 'RDP sin NLA - vulnerable a ataques.' 'RDP-002'
            Write-WyndisSuggest 'Activa NLA en propiedades del Escritorio remoto.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar NLA de RDP.'
    }

    # Puerto RDP (3389 por defecto)
    try {
        $port = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -ErrorAction Stop).PortNumber
        Write-WyndisInfo "Puerto RDP configurado: $port"
        if ($port -eq 3389) {
            Write-WyndisWarning 'RDP usa el puerto predeterminado 3389.' 'RDP-003'
            Write-WyndisSuggest 'Cambia el puerto RDP si necesitas acceso remoto.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo leer el puerto RDP.'
    }

    # Servicio TermService
    $termService = Get-Service -Name TermService -ErrorAction SilentlyContinue
    if ($termService) {
        if ($termService.Status -eq 'Running') {
            Write-WyndisWarning 'Servicio TermService (RDP) en ejecución.' 'RDP-004'
        } else {
            Write-WyndisOk 'Servicio TermService detenido.'
        }
    }

    # Conexiones RDP activas
    try {
        $sessions = query user 2>$null
        if ($sessions) {
            Write-WyndisInfo 'Sesiones de usuario activas:'
            $sessions | ForEach-Object { Write-WyndisInfo "  $_" }
        }
    } catch {
        Write-WyndisInfo 'No se pudieron listar sesiones activas.'
    }

    # Reglas firewall RDP
    try {
        $rdpFw = Get-NetFirewallRule -DisplayGroup 'Escritorio remoto' -ErrorAction SilentlyContinue |
            Where-Object { $_.Enabled -eq 'True' -and $_.Direction -eq 'Inbound' }
        if (-not $rdpFw) {
            $rdpFw = Get-NetFirewallRule -DisplayName '*Remote Desktop*' -ErrorAction SilentlyContinue |
                Where-Object { $_.Enabled -eq 'True' }
        }

        foreach ($rule in $rdpFw) {
            Write-WyndisWarning "Regla firewall RDP activa: $($rule.DisplayName)" 'RDP-005'
        }
    } catch {
        Write-WyndisInfo 'Revisión de firewall RDP limitada.'
    }
}
