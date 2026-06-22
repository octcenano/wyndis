# SPDX-License-Identifier: MIT
# Wyndis - Dangerous services audit

function Invoke-WyndisServicesAudit {
    # Servicios considerados peligrosos si están activos en entornos domésticos/PME
    $riskyServices = @{
        'RemoteRegistry'   = @{ Risk = 'Permite modificar el registro remotamente'; Level = 'critical' }
        'Telnet'           = @{ Risk = 'Protocolo inseguro sin cifrado'; Level = 'critical' }
        'TlntSvr'          = @{ Risk = 'Servidor Telnet'; Level = 'critical' }
        'SNMP'             = @{ Risk = 'SNMP puede filtrar información de red'; Level = 'warning' }
        'SSDPSRV'          = @{ Risk = 'Descubrimiento SSDP - puede ampliar superficie de ataque'; Level = 'warning' }
        'upnphost'         = @{ Risk = 'Host UPnP - riesgo en redes no confiables'; Level = 'warning' }
        'RemoteAccess'     = @{ Risk = 'Enrutamiento y acceso remoto'; Level = 'warning' }
        'LanmanServer'     = @{ Risk = 'Servidor SMB - revisar si es necesario'; Level = 'info' }
        'LanmanWorkstation'= @{ Risk = 'Cliente SMB'; Level = 'info' }
        'W3SVC'            = @{ Risk = 'Servidor web IIS expuesto'; Level = 'warning' }
        'FTPSVC'           = @{ Risk = 'Servidor FTP'; Level = 'critical' }
        'MSFTPSVC'         = @{ Risk = 'Servidor FTP Microsoft'; Level = 'critical' }
        'XblAuthManager'   = @{ Risk = 'Xbox Live Auth - innecesario en empresa'; Level = 'info' }
        'Spooler'          = @{ Risk = 'Print Spooler - histórico de vulnerabilidades'; Level = 'warning' }
        'TermService'      = @{ Risk = 'Escritorio remoto'; Level = 'warning' }
        'SharedAccess'     = @{ Risk = 'Compartición de conexión ICS'; Level = 'warning' }
        'RpcLocator'       = @{ Risk = 'Localizador RPC'; Level = 'info' }
    }

    $runningRisky = 0
    $checked = 0

    foreach ($svcName in $riskyServices.Keys) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if (-not $svc) { continue }

        $checked++
        $info = $riskyServices[$svcName]

        if ($svc.Status -eq 'Running') {
            $msg = "Servicio '$svcName' EN EJECUCIÓN - $($info.Risk)"
            switch ($info.Level) {
                'critical' {
                    Write-WyndisCritical $msg "SVC-$svcName"
                    $runningRisky++
                }
                'warning' {
                    Write-WyndisWarning $msg "SVC-$svcName"
                    $runningRisky++
                }
                default {
                    Write-WyndisInfo $msg
                }
            }

            if ($svc.StartType -eq 'Automatic') {
                Write-WyndisSuggest "Considera deshabilitar: Set-Service -Name $svcName -StartupType Disabled"
            }
        } else {
            if ($info.Level -in @('critical', 'warning')) {
                Write-WyndisOk "Servicio '$svcName' detenido."
            }
        }
    }

    Write-WyndisInfo "Servicios peligrosos revisados: $checked"

    if ($runningRisky -eq 0) {
        Write-WyndisOk 'Ningún servicio de alto riesgo está en ejecución.'
    }

    # Servicios con inicio automático no firmados / desconocidos
    try {
        $autoServices = Get-CimInstance Win32_Service -ErrorAction Stop |
            Where-Object { $_.StartMode -eq 'Auto' -and $_.State -eq 'Running' -and $_.PathName -match '^"?[A-Za-z]:\\(Users|Temp|ProgramData)\\' }

        foreach ($svc in $autoServices) {
            Write-WyndisCritical "Servicio sospechoso en ruta de usuario: $($svc.Name) -> $($svc.PathName)" "SVC-SUS-$($svc.Name)"
        }
    } catch {
        Write-WyndisInfo 'Revisión de servicios sospechosos limitada.'
    }
}
