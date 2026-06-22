# SPDX-License-Identifier: MIT
# Wyndis - Windows Update audit

function Invoke-WyndisUpdateAudit {
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $searcher = $updateSession.CreateUpdateSearcher()
        $pending = $searcher.Search("IsInstalled=0 and Type='Software'")

        if ($pending.Updates.Count -eq 0) {
            Write-WyndisOk 'No hay actualizaciones de software pendientes.'
        } else {
            Write-WyndisWarning "Hay $($pending.Updates.Count) actualización(es) pendiente(s)." 'UPD-001'
            foreach ($update in $pending.Updates | Select-Object -First 5) {
                Write-WyndisInfo "  - $($update.Title)"
            }
            if ($pending.Updates.Count -gt 5) {
                Write-WyndisInfo "  ... y $($pending.Updates.Count - 5) más"
            }
            Write-WyndisSuggest 'Instala las actualizaciones: Configuración -> Windows Update'
        }
    } catch {
        Write-WyndisWarning 'No se pudo comprobar actualizaciones pendientes.' 'UPD-002'
        Write-WyndisSuggest 'Abre Configuración -> Windows Update manualmente.'
    }

    # Servicio Windows Update
    $wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
    if ($wuService) {
        if ($wuService.Status -eq 'Running') {
            Write-WyndisOk 'Servicio Windows Update en ejecución.'
        } else {
            Write-WyndisWarning 'Servicio Windows Update detenido.' 'UPD-003'
            Write-WyndisSuggest 'Inicia el servicio: Start-Service wuauserv'
        }

        if ($wuService.StartType -eq 'Disabled') {
            Write-WyndisCritical 'Windows Update está deshabilitado.' 'UPD-004'
        }
    }

    # Última actualización instalada
    try {
        $history = Get-HotFix -ErrorAction Stop | Sort-Object InstalledOn -Descending | Select-Object -First 1
        if ($history -and $history.InstalledOn) {
            $daysSince = ((Get-Date) - $history.InstalledOn).Days
            Write-WyndisInfo "Último parche: $($history.HotFixID) ($($history.InstalledOn.ToString('yyyy-MM-dd')))"

            if ($daysSince -gt 60) {
                Write-WyndisWarning "Han pasado $daysSince días desde la última actualización." 'UPD-005'
            } else {
                Write-WyndisOk 'Actualizaciones recientes instaladas.'
            }
        }
    } catch {
        Write-WyndisInfo 'No se pudo obtener historial de parches.'
    }

    # Reinicio pendiente por actualizaciones
    try {
        $rebootKey = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction Stop
        if ($rebootKey) {
            Write-WyndisWarning 'Reinicio pendiente por actualizaciones de Windows.' 'UPD-006'
            Write-WyndisSuggest 'Reinicia el equipo para completar las actualizaciones.'
        }
    } catch {
        Write-WyndisOk 'No hay reinicio pendiente por actualizaciones.'
    }

    # Versión de Windows y soporte
    $os = Get-CimInstance Win32_OperatingSystem
    $build = [int]$os.BuildNumber

    $eolInfo = Get-WyndisOsEol -Build $build -Caption $os.Caption
    Write-WyndisInfo "Estado de soporte: $($eolInfo.Status)"

    if ($eolInfo.IsEol) {
        Write-WyndisCritical "Windows sin soporte: $($eolInfo.Status)" 'UPD-007'
        Write-WyndisSuggest 'Actualiza a una versión de Windows con soporte activo.'
    } elseif ($eolInfo.IsNearEol) {
        Write-WyndisWarning "El soporte de Windows termina pronto." 'UPD-008'
    } else {
        Write-WyndisOk 'Windows recibe soporte de Microsoft.'
    }
}

function Get-WyndisOsEol {
    param([int]$Build, [string]$Caption)

    # Fechas aproximadas de fin de soporte (2026)
    $eolMap = @{
        22000 = @{ Name = 'Windows 11 21H2'; Eol = '2024-10-08'; Near = $true }
        22621 = @{ Name = 'Windows 11 22H2/23H2'; Eol = '2025-10-14'; Near = $true }
        22631 = @{ Name = 'Windows 11 23H2'; Eol = '2025-11-12'; Near = $false }
        26100 = @{ Name = 'Windows 11 24H2'; Eol = '2026-10-13'; Near = $false }
        19041 = @{ Name = 'Windows 10 2004'; Eol = '2021-12-14'; Near = $true }
        19042 = @{ Name = 'Windows 10 20H2'; Eol = '2022-05-10'; Near = $true }
        19043 = @{ Name = 'Windows 10 21H1'; Eol = '2022-12-13'; Near = $true }
        19044 = @{ Name = 'Windows 10 21H2'; Eol = '2023-06-13'; Near = $true }
        19045 = @{ Name = 'Windows 10 22H2'; Eol = '2025-10-14'; Near = $true }
    }

    $info = $eolMap[$Build.ToString()]
    if (-not $info) {
        if ($Caption -match 'Windows 11') {
            return @{ Status = 'Windows 11 (verifica build)'; IsEol = $false; IsNearEol = $false }
        }
        return @{ Status = 'Versión no catalogada'; IsEol = $false; IsNearEol = $false }
    }

    $eolDate = [datetime]$info.Eol
    $isEol = (Get-Date) -gt $eolDate
    $isNear = -not $isEol -and ((Get-Date).AddMonths(6) -gt $eolDate)

    return @{
        Status    = "$($info.Name) - soporte hasta $($info.Eol)"
        IsEol     = $isEol
        IsNearEol = $isNear
    }
}
