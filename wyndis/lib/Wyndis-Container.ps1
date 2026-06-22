# SPDX-License-Identifier: MIT
# Wyndis - Container and Hyper-V audit

function Invoke-WyndisContainerAudit {
    Write-WyndisInfo '--- Auditoria de Contenedores y Virtualizacion ---'

    try {
        $wsl = wsl -l -v 2>$null
        if ($wsl -and $wsl -notmatch 'no distribution|failed') {
            Write-WyndisInfo 'WSL detectado.'
            Write-WyndisInfo $wsl
            Write-WyndisSuggest 'Revisa las distribuciones WSL - mantén actualizadas.'
        } else {
            Write-WyndisInfo 'WSL no instalado.'
        }
    } catch {
        Write-WyndisInfo 'WSL no disponible.'
    }

    try {
        $docker = Get-Command docker -ErrorAction SilentlyContinue
        if ($docker) {
            Write-WyndisWarning 'Docker Desktop detectado.' 'CNT-001'
            $dockerVer = docker --version 2>$null
            if ($dockerVer) {
                Write-WyndisInfo "  Version: $dockerVer"
            }
            $running = docker ps --format '{{.Names}}' 2>$null
            if ($running -and $running -notmatch 'CONTAINER ID') {
                Write-WyndisInfo "  Contenedores activos: $(($running | Measure-Object).Count)"
            }
            Write-WyndisSuggest 'Docker aumenta superficie de ataque. Revisa imagenes y contenedores.'
        } else {
            Write-WyndisOk 'Docker no instalado.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar Docker.'
    }

    try {
        $hyperv = Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Hyper-V' -ErrorAction SilentlyContinue
        if ($hyperv -and $hyperv.State -eq 'Enabled') {
            Write-WyndisInfo 'Hyper-V habilitado.'
            try {
                $vms = Get-VM -ErrorAction SilentlyContinue
                if ($vms) {
                    Write-WyndisInfo "  Maquinas virtuales: $($vms.Count)"
                    $running = $vms | Where-Object { $_.State -eq 'Running' }
                    if ($running) {
                        Write-WyndisInfo "  VMs activas: $(($running).Count)"
                    }
                }
            } catch {
                Write-WyndisInfo '  No se pudieron listar VMs.'
            }
            Write-WyndisSuggest 'Mantén las VMs actualizadas y con proteccion de red.'
        } else {
            Write-WyndisInfo 'Hyper-V no instalado.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar Hyper-V.'
    }
}
