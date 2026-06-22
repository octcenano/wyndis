# SPDX-License-Identifier: MIT
# Wyndis - PowerShell security audit

function Invoke-WyndisPowerShellAudit {
    Write-WyndisInfo '--- Auditoria de Seguridad de PowerShell ---'

    $execPolicy = Get-ExecutionPolicy
    Write-WyndisInfo "Politica de ejecucion PowerShell: $execPolicy"
    switch ($execPolicy) {
        'Restricted'   { Write-WyndisOk 'Execution Policy restrictiva (maxima seguridad).' }
        'RemoteSigned' { Write-WyndisOk 'Execution Policy RemoteSigned (recomendada).' }
        'AllSigned'    { Write-WyndisOk 'Execution Policy AllSigned (alta seguridad).' }
        'Unrestricted' { Write-WyndisWarning 'Execution Policy Unrestricted - permite cualquier script.' 'PS-001' }
        'Bypass'       { Write-WyndisWarning 'Execution Policy Bypass - sin restricciones.' 'PS-002' }
        default        { Write-WyndisInfo "Politica de ejecucion: $execPolicy" }
    }

    try {
        $tls = [Net.ServicePointManager]::SecurityProtocol
        Write-WyndisInfo "Protocolo TLS: $tls"
        if ($tls -notmatch 'Tls12|Tls13') {
            Write-WyndisWarning 'TLS 1.2/1.3 no habilitado en .NET - conexiones inseguras.' 'PS-003'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar TLS.'
    }

    try {
        $psModules = Get-Module -ListAvailable -ErrorAction SilentlyContinue
        $dangerousModules = @(
            'PSScriptAnalyzer',
            'PSReadLine'
        )
        Write-WyndisInfo "Modulos PowerShell instalados: $(($psModules | Measure-Object).Count)"
    } catch {
        Write-WyndisInfo 'No se pudo listar modulos PowerShell.'
    }

    try {
        $ps5Logging = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging' -Name 'EnableModuleLogging' -ErrorAction SilentlyContinue
        if ($ps5Logging -and $ps5Logging.EnableModuleLogging -eq 1) {
            Write-WyndisOk 'Module Logging de PowerShell activo.'
        } else {
            Write-WyndisSuggest 'Activa Module Logging para PowerShell via GPO.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar Module Logging.'
    }

    try {
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            Write-WyndisInfo 'PowerShell 7+ detectado (moderno, multiplataforma).'
        }
        Write-WyndisInfo "Version PowerShell: $($PSVersionTable.PSVersion)"
    } catch {}
}
