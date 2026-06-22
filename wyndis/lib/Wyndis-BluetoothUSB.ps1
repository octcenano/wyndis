# SPDX-License-Identifier: MIT
# Wyndis - Bluetooth and USB audit

function Invoke-WyndisBluetoothUsbAudit {
    Write-WyndisInfo '--- Auditoria de Bluetooth y USB ---'

    try {
        $btRadio = Get-CimInstance -Namespace root/cimv2 -ClassName Win32_PnPEntity -ErrorAction Stop |
            Where-Object { $_.Name -match 'Bluetooth|Bluetooth' -and $_.Status -eq 'OK' }
        if ($btRadio) {
            Write-WyndisInfo "Dispositivos Bluetooth detectados: $($btRadio.Count)"
            try {
                $btInfo = Get-PnpDevice -ClassName 'Bluetooth' -ErrorAction Stop | Where-Object { $_.Status -eq 'OK' }
                $discoverable = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters' -Name 'Discoverable' -ErrorAction SilentlyContinue
                if ($discoverable -and $discoverable.Discoverable -eq 1) {
                    Write-WyndisWarning 'Bluetooth en modo detectable.' 'BT-001'
                    Write-WyndisSuggest 'Desactiva el modo detectable de Bluetooth si no lo necesitas.'
                } else {
                    Write-WyndisOk 'Bluetooth no detectable.'
                }
            } catch {
                Write-WyndisInfo 'No se pudo verificar modo Bluetooth.'
            }
        } else {
            Write-WyndisOk 'Sin radios Bluetooth detectadas.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar Bluetooth.'
    }

    try {
        $usbStorage = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR' -Name 'Start' -ErrorAction SilentlyContinue
        if ($usbStorage -and $usbStorage.Start -eq 4) {
            Write-WyndisOk 'Almacenamiento USB deshabilitado (proteccion contra exfiltracion).'
        } else {
            Write-WyndisInfo 'Almacenamiento USB habilitado.'
            if ($usbStorage -and $usbStorage.Start -eq 3) {
                Write-WyndisSuggest 'Considera deshabilitar almacenamiento USB en entornos de alta seguridad.'
            }
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar politica USB.'
    }

    try {
        $autoPlay = Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers' -Name 'DisableAutoplay' -ErrorAction SilentlyContinue
        if ($autoPlay -and $autoPlay.DisableAutoplay -eq 1) {
            Write-WyndisOk 'AutoPlay deshabilitado.'
        } else {
            Write-WyndisWarning 'AutoPlay habilitado - riesgo de infeccion por USB.' 'USB-001'
            Write-WyndisSuggest 'Desactiva AutoPlay en Configuracion -> Dispositivos -> AutoPlay.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar AutoPlay.'
    }
}
