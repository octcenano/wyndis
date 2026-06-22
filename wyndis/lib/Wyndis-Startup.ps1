# SPDX-License-Identifier: MIT
# Wyndis - Startup programs (auto inicio)

function Invoke-WyndisStartupAudit {
    $startupItems = [System.Collections.Generic.List[object]]::new()

    # Registro: HKLM Run
    $runPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
    )

    foreach ($path in $runPaths) {
        try {
            $items = Get-ItemProperty -Path $path -ErrorAction Stop
            $items.PSObject.Properties | Where-Object {
                $_.Name -notmatch '^PS' -and $_.Value
            } | ForEach-Object {
                $startupItems.Add([PSCustomObject]@{
                    Name   = $_.Name
                    Path   = $_.Value
                    Source = $path
                })
            }
        } catch { }
    }

    # Carpeta Startup
    $startupFolders = @(
        [Environment]::GetFolderPath('Startup'),
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
    )

    foreach ($folder in $startupFolders) {
        if (Test-Path $folder) {
            Get-ChildItem $folder -ErrorAction SilentlyContinue | ForEach-Object {
                $startupItems.Add([PSCustomObject]@{
                    Name   = $_.Name
                    Path   = $_.FullName
                    Source = "Startup folder: $folder"
                })
            }
        }
    }

    # Tareas programadas al inicio
    try {
        $tasks = Get-ScheduledTask -ErrorAction Stop |
            Where-Object { $_.Triggers.CimClass.CimClassName -match 'Boot|Logon' -and $_.State -ne 'Disabled' }

        foreach ($task in $tasks | Select-Object -First 20) {
            $startupItems.Add([PSCustomObject]@{
                Name   = $task.TaskName
                Path   = ($task.Actions | Select-Object -First 1).Execute
                Source = 'Scheduled Task'
            })
        }
        Write-WyndisInfo "Tareas al inicio (mostrando hasta 20): $($tasks.Count) total"
    } catch {
        Write-WyndisInfo 'No se pudieron listar tareas programadas.'
    }

    Write-WyndisInfo "Elementos de inicio detectados: $($startupItems.Count)"

    # Programas sospechosos en inicio
    $suspiciousPatterns = @(
        'temp\\', 'appdata\\local\\temp', 'downloads\\',
        '\.vbs$', '\.js$', '\.bat$', '\.cmd$', '\.ps1$',
        'powershell -enc', 'powershell -e ', 'cmd /c',
        'wscript', 'cscript', 'mshta'
    )

    $suspiciousCount = 0
    foreach ($item in $startupItems) {
        $pathLower = $item.Path.ToLower()
        $isSuspicious = $false

        foreach ($pattern in $suspiciousPatterns) {
            if ($pathLower -match $pattern) {
                $isSuspicious = $true
                break
            }
        }

        if ($isSuspicious) {
            Write-WyndisCritical "Inicio sospechoso: $($item.Name) -> $($item.Path)" "START-SUS-$($item.Name)"
            $suspiciousCount++
        } else {
            Write-WyndisInfo "  $($item.Name) [$($item.Source)]"
        }
    }

    if ($suspiciousCount -eq 0) {
        Write-WyndisOk 'No se detectaron entradas de inicio claramente sospechosas.'
    }

    if ($startupItems.Count -gt 25) {
        Write-WyndisWarning "Muchos programas en inicio ($($startupItems.Count)) - puede ralentizar el arranque." 'START-001'
        Write-WyndisSuggest 'Revisa el Administrador de tareas -> Inicio y desactiva lo innecesario.'
    } elseif ($startupItems.Count -le 15) {
        Write-WyndisOk 'Cantidad razonable de programas en inicio.'
    }

    # WMI persistence check (básico)
    try {
        $wmiConsumers = Get-CimInstance -Namespace root/subscription -ClassName __EventConsumer -ErrorAction Stop
        if ($wmiConsumers) {
            Write-WyndisWarning "Detectados $($wmiConsumers.Count) consumidor(es) WMI - revisar persistencia." 'START-002'
            Write-WyndisSuggest 'Los consumidores WMI pueden usarse para persistencia de malware.'
        }
    } catch {
        Write-WyndisOk 'Sin consumidores WMI detectados (o sin acceso).'
    }
}
