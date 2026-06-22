# SPDX-License-Identifier: MIT
# Wyndis - System lifespan and hardware health

function Invoke-WyndisSystemLifeAudit {
    $cs = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
    $disk = Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue | Select-Object -First 1
    $os = Get-CimInstance Win32_OperatingSystem

    # BIOS / fabricante
    if ($bios) {
        Write-WyndisInfo "Fabricante: $($cs.Manufacturer) | Modelo: $($cs.Model)"
        Write-WyndisInfo "BIOS: $($bios.SMBIOSBIOSVersion) ($($bios.Manufacturer))"

        if ($bios.ReleaseDate) {
            $biosDate = $bios.ReleaseDate
            $biosAge = ((Get-Date) - $biosDate).Days
            Write-WyndisInfo "Fecha BIOS: $($biosDate.ToString('yyyy-MM-dd')) (~$([math]::Round($biosAge/365, 1)) años)"

            if ($biosAge -gt 3650) {
                Write-WyndisWarning 'BIOS con más de 10 años - verifica actualizaciones del fabricante.' 'LIFE-001'
            }
        }
    }

    # RAM
    $ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
    Write-WyndisInfo "Memoria RAM: ${ramGB} GB"

    if ($ramGB -lt 4) {
        Write-WyndisWarning 'Menos de 4 GB RAM - el sistema puede quedar obsoleto para uso moderno.' 'LIFE-002'
        Write-WyndisSuggest 'Considera ampliar RAM para Windows 10/11.'
    } elseif ($ramGB -lt 8) {
        Write-WyndisWarning 'Menos de 8 GB RAM - limitado para multitarea.' 'LIFE-003'
    } else {
        Write-WyndisOk "RAM adecuada (${ramGB} GB)."
    }

    # CPU
    $logical = 0
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    if ($cpu) {
        Write-WyndisInfo "Procesador: $($cpu.Name)"
        $cores = $cpu.NumberOfCores
        $logical = $cpu.NumberOfLogicalProcessors
        Write-WyndisInfo "Núcleos: $cores físicos / $logical lógicos"

        if ($logical -lt 4) {
            Write-WyndisWarning 'CPU con menos de 4 hilos - rendimiento limitado.' 'LIFE-004'
        }
    }

    # Disco
    if ($disk) {
        Write-WyndisInfo "Disco: $($disk.Model) ($([math]::Round($disk.Size/1GB)) GB)"
        if ($disk.MediaType -match 'SSD|Solid') {
            Write-WyndisOk 'Disco SSD detectado.'
        } elseif ($disk.MediaType -match 'HDD|Fixed hard') {
            Write-WyndisWarning 'Disco HDD mecánico - considera migrar a SSD.' 'LIFE-005'
            Write-WyndisSuggest 'Un SSD mejora mucho la velocidad y vida útil percibida del PC.'
        }
    }

    # Espacio en disco (volumen C:)
    $freePct = 100
    $volume = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
    if ($volume) {
        $freeGB = [math]::Round($volume.FreeSpace / 1GB, 1)
        $totalGB = [math]::Round($volume.Size / 1GB, 1)
        $freePct = [math]::Round(($volume.FreeSpace / $volume.Size) * 100, 1)
        Write-WyndisInfo "Disco C: ${freeGB} GB libres de ${totalGB} GB (${freePct}%)"

        if ($freePct -lt 10) {
            Write-WyndisCritical "Disco C: casi lleno (${freePct}% libre)." 'LIFE-006'
            Write-WyndisSuggest 'Libera espacio - Windows necesita espacio para actualizaciones.'
        } elseif ($freePct -lt 20) {
            Write-WyndisWarning "Poco espacio libre en C: (${freePct}%)." 'LIFE-007'
        } else {
            Write-WyndisOk 'Espacio en disco suficiente.'
        }
    }

    # Batería (portátiles)
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        Write-WyndisInfo 'Batería detectada (portátil).'
        $estimatedLife = $battery.EstimatedChargeRemaining
        Write-WyndisInfo "Carga estimada: ${estimatedLife}%"

        # WMI no siempre da wear level; aviso genérico
        Write-WyndisSuggest 'En portátiles, revisa la salud de batería cada 2-3 años.'
    }

    # Edad estimada del sistema operativo (instalación)
    $installDate = $os.InstallDate
    if ($installDate) {
        $install = $installDate
        $osAge = ((Get-Date) - $install).Days
        Write-WyndisInfo "Windows instalado: $($install.ToString('yyyy-MM-dd')) (~$([math]::Round($osAge/365, 1)) años)"

        if ($osAge -gt 1095) {
            Write-WyndisWarning 'Windows instalado hace más de 3 años - considera reinstalar limpio.' 'LIFE-008'
            Write-WyndisSuggest 'Una instalación limpia elimina basura acumulada y posible malware oculto.'
        }
    }

    # Resumen vida útil
    Write-WyndisInfo '--- Evaluación de vida útil ---'
    $score = 0
    if ($ramGB -ge 8) { $score += 2 } elseif ($ramGB -ge 4) { $score += 1 }
    if ($disk.MediaType -match 'SSD|Solid') { $score += 2 }
    if ($freePct -ge 20) { $score += 1 }
    if ($logical -ge 4) { $score += 1 }

    switch ($score) {
        { $_ -ge 5 } { Write-WyndisOk 'El hardware tiene buena vida útil restante.' }
        { $_ -ge 3 } { Write-WyndisWarning 'El sistema funciona pero podría necesitar mejoras pronto.' 'LIFE-009' }
        default      { Write-WyndisWarning 'Hardware limitado - planifica renovación.' 'LIFE-010' }
    }
}
