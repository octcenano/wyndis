# SPDX-License-Identifier: MIT
# Wyndis - Network security audit

function Invoke-WyndisNetworkAudit {
    Write-WyndisInfo '--- Auditoria de Red ---'

    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
    Write-WyndisInfo "Adaptadores de red activos: $($adapters.Count)"

    foreach ($adapter in $adapters) {
        Write-WyndisInfo "  - $($adapter.Name) ($($adapter.LinkSpeed))"
    }

    try {
        $ipv6 = Get-NetAdapterBinding -ComponentID 'ms_tcpip6' -ErrorAction Stop |
            Where-Object { $_.Enabled -eq $true }
        Write-WyndisInfo "IPv6 habilitado en $($ipv6.Count) adaptador(es)."
        Write-WyndisSuggest 'Considera deshabilitar IPv6 si no es necesario en tu red.'
    } catch {
        Write-WyndisInfo 'No se pudo verificar estado de IPv6.'
    }

    $netProfiles = Get-NetConnectionProfile -ErrorAction SilentlyContinue
    foreach ($np in $netProfiles) {
        Write-WyndisInfo "Perfil de red '$($np.Name)': $($np.NetworkCategory)"
        if ($np.NetworkCategory -eq 'Public') {
            Write-WyndisOk "Perfil Publico - configuracion segura."
        } elseif ($np.NetworkCategory -eq 'Private') {
            Write-WyndisWarning "Perfil Privado en '$($np.Name)' - solo si es confiable." 'NET-001'
        }
    }

    try {
        $dnsClients = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop |
            Where-Object { $_.ServerAddresses }
        foreach ($dc in $dnsClients) {
            $dnsServers = $dc.ServerAddresses -join ', '
            Write-WyndisInfo "DNS ($($dc.InterfaceAlias)): $dnsServers"
            $nonStandard = $dc.ServerAddresses | Where-Object { $_ -notmatch '^(8\.8\.|1\.1\.|9\.9\.|208\.67\.|192\.168\.|10\.|172\.)' }
            if ($nonStandard) {
                foreach ($ns in $nonStandard) {
                    if ($ns -notmatch '^(192\.168\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.)') {
                        Write-WyndisWarning "DNS no estandar: $ns - verifica que sea confiable." 'NET-002'
                    }
                }
            }
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar configuracion DNS.'
    }

    try {
        $doh = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'EdgeDnsOverHttpsMode' -ErrorAction SilentlyContinue
        if ($doh -and $doh.EdgeDnsOverHttpsMode) {
            Write-WyndisInfo "DNS-over-HTTPS (Edge): $($doh.EdgeDnsOverHttpsMode)"
        } else {
            Write-WyndisSuggest 'Considera activar DNS-over-HTTPS en Edge/Chrome para privacidad.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar DoH.'
    }

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
            5985 = 'WinRM HTTP'
            5986 = 'WinRM HTTPS'
        }

        foreach ($conn in $listening) {
            $port = $conn.LocalPort
            if ($riskyPorts.ContainsKey($port)) {
                $procName = try { (Get-Process -Id $conn.OwningProcess -ErrorAction Stop).ProcessName } catch { 'desconocido' }
                Write-WyndisWarning "Puerto $port ($($riskyPorts[$port])) escuchando - proceso: $procName" "NET-PORT-$port"
            }
        }

        $totalListen = @($listening).Count
        if ($totalListen -gt 30) {
            Write-WyndisWarning "Muchos puertos en escucha ($totalListen) - posible amplia superficie de ataque." 'NET-003'
        }

        Write-WyndisInfo "Puertos en escucha: $totalListen"
    } catch {
        Write-WyndisInfo 'Revision de puertos limitada sin privilegios elevados.'
    }

    try {
        $smbConfig = Get-SmbServerConfiguration -ErrorAction Stop
        if (-not $smbConfig.EnableSMB1Protocol) {
            Write-WyndisOk 'SMBv1 deshabilitado.'
        } else {
            Write-WyndisCritical 'SMBv1 habilitado - protocolo inseguro.' 'NET-004'
        }
        if ($smbConfig.RequireSecuritySignature) {
            Write-WyndisOk 'Firmado SMB requerido.'
        } else {
            Write-WyndisWarning 'Firmado SMB no requerido - riesgo de MiTM.' 'NET-005'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar configuracion SMB.'
    }

    try {
        $llmnr = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient' -Name 'EnableLLMNR' -ErrorAction SilentlyContinue
        if ($llmnr -and $llmnr.EnableLLMNR -eq 0) {
            Write-WyndisOk 'LLMNR deshabilitado.'
        } else {
            Write-WyndisSuggest 'Considera deshabilitar LLMNR via GPO para prevenir ataques de suplantacion.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar LLMNR.'
    }
}
