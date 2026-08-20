#Requires -Module Pester

<#
    Pruebas unitarias del módulo Wyndis-Core.

    Cubren las funciones puras y la contabilidad de hallazgos de Wyndis-Core
    sin ejecutar un audit completo ni depender de un sistema concreto.

    Ejecución:
        Install-Module Pester -Force -Scope CurrentUser
        Invoke-Pester ./wyndis/tests
#>

BeforeAll {
    $script:NoColor = $true   # Evitar códigos ANSI en la salida de CI
    . "$PSScriptRoot/../lib/Wyndis-Core.ps1"
}

Describe 'Wyndis-Core' {

    It 'expone la versión actual 4.0.0' {
        $script:WyndisVersion | Should -Be '4.0.0'
    }

    It 'devuelve string vacío para colores cuando NoColor está activo' {
        Get-WyndisColor -Color 'Green' | Should -Be ''
    }

    It 'registra un hallazgo con severidad y días estimados correctos' {
        $before = $script:Findings.Count

        Add-WyndisFinding -Id 'TEST-001' -Category 'Test' -Name 'Hallazgo de prueba' -Severity 'Critical' -EstimatedHours 20

        $after = $script:Findings.Count
        $after | Should -Be ($before + 1)

        $f = $script:Findings | Select-Object -Last 1
        $f.Severity      | Should -Be 'Critical'
        $f.Status        | Should -Be 'Open'
        $f.EstimatedDays | Should -Be ([math]::Ceiling(20 / 8))
    }

    It 'distingue entre hallazgos críticos y de advertencia' {
        Add-WyndisFinding -Id 'TEST-002' -Category 'Test' -Name 'Aviso' -Severity 'Warning'
        $f = $script:Findings | Select-Object -Last 1
        $f.Severity | Should -Be 'Warning'
    }

    It 'mantiene el histórico como lista vacía inicial' {
        $script:Findings | Should -Not -Be $null
    }
}