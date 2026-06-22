# SPDX-License-Identifier: MIT
# Wyndis - Privacy and telemetry audit

function Invoke-WyndisPrivacyAudit {
    Write-WyndisInfo '--- Auditoria de Privacidad ---'

    try {
        $telemetry = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -ErrorAction SilentlyContinue
        if (-not $telemetry) {
            $telemetry = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' -Name 'AllowTelemetry' -ErrorAction SilentlyContinue
        }
        if ($telemetry -and $telemetry.AllowTelemetry -ne $null) {
            $level = $telemetry.AllowTelemetry
            $levelName = switch ($level) {
                0 { 'Seguridad (0)' }
                1 { 'Basica (1)' }
                2 { 'Mejorada (2)' }
                3 { 'Completa (3)' }
                default { "Nivel $level" }
            }
            Write-WyndisInfo "Telemetria: $levelName"
            if ($level -ge 2) {
                Write-WyndisWarning "Telemetria elevada ($levelName) - datos enviados a Microsoft." 'PRIV-001'
                Write-WyndisSuggest 'Reduce la telemetria: nivel 0 o 1. Usa O&O ShutUp10++.'
            } else {
                Write-WyndisOk "Telemetria configurada en nivel minimo."
            }
        } else {
            Write-WyndisWarning 'Telemetria no configurada via politica - probablemente nivel 3 (completa).' 'PRIV-002'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar nivel de telemetria.'
    }

    try {
        $location = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\Location' -Name 'Value' -ErrorAction SilentlyContinue
        if ($location -and $location.Value -eq 'Deny') {
            Write-WyndisOk 'Servicios de ubicacion desactivados.'
        } else {
            Write-WyndisWarning 'Servicios de ubicacion activos.' 'PRIV-003'
            Write-WyndisSuggest 'Desactiva ubicacion en Configuracion -> Privacidad -> Ubicacion.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar estado de ubicacion.'
    }

    try {
        $camera = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\WebCam' -Name 'Value' -ErrorAction SilentlyContinue
        $mic = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\Microphone' -Name 'Value' -ErrorAction SilentlyContinue
        if ($camera -and $camera.Value -eq 'Deny') {
            Write-WyndisOk 'Camara desactivada globalmente.'
        } else {
            Write-WyndisWarning 'Acceso a camara no restringido globalmente.' 'PRIV-004'
        }
        if ($mic -and $mic.Value -eq 'Deny') {
            Write-WyndisOk 'Microfono desactivado globalmente.'
        } else {
            Write-WyndisWarning 'Acceso a microfono no restringido globalmente.' 'PRIV-005'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar estado de camara/microfono.'
    }

    try {
        $adId = Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -ErrorAction SilentlyContinue
        if ($adId -and $adId.Enabled -eq 0) {
            Write-WyndisOk 'ID de publicidad desactivado.'
        } else {
            Write-WyndisWarning 'ID de publicidad activo - seguimiento de intereses.' 'PRIV-006'
            Write-WyndisSuggest 'Desactiva en Configuracion -> Privacidad -> General -> ID de publicidad.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar ID de publicidad.'
    }

    try {
        $ceip = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\SQMClient\Windows' -Name 'CEIPEnable' -ErrorAction SilentlyContinue
        if ($ceip -and $ceip.CEIPEnable -eq 0) {
            Write-WyndisOk 'Programa de mejora (CEIP) desactivado.'
        } else {
            Write-WyndisSuggest 'Considera desactivar CEIP para reducir telemetria.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar CEIP.'
    }

    try {
        $cortana = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortana' -ErrorAction SilentlyContinue
        if ($cortana -and $cortana.AllowCortana -eq 0) {
            Write-WyndisOk 'Cortana desactivado.'
        } else {
            Write-WyndisWarning 'Cortana/personalizacion de voz activa.' 'PRIV-007'
            Write-WyndisSuggest 'Desactiva Cortana si no la usas.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar estado de Cortana.'
    }
}
