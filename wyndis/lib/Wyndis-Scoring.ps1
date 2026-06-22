# SPDX-License-Identifier: MIT
# Wyndis - Scoring system 0-100

function Get-WyndisScore {
    $critical = @($Script:Findings | Where-Object { $_.Severity -eq 'critical' }).Count
    $warning  = @($Script:Findings | Where-Object { $_.Severity -eq 'warning' }).Count
    $info     = @($Script:Findings | Where-Object { $_.Severity -eq 'info' }).Count

    $grade = 100.0 - ($critical * 5.0) - ($warning * 2.0)
    if ($grade -lt 0) { $grade = 0 }
    $grade = [math]::Round($grade, 1)

    $label = switch ($true) {
        ($grade -ge 90) { 'Excelente' }
        ($grade -ge 75) { 'Bueno' }
        ($grade -ge 50) { 'Regular' }
        ($grade -ge 25) { 'Malo' }
        default         { 'Critico' }
    }

    return @{
        Grade    = $grade
        Label    = $label
        Critical = $critical
        Warning  = $warning
        Info     = $info
        Total    = $critical + $warning + $info
    }
}
