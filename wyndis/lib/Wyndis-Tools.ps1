# SPDX-License-Identifier: MIT
# Wyndis - Tool recommendations (gratis)

function Invoke-WyndisToolRecommendations {
    Write-WyndisInfo 'Herramientas gratuitas recomendadas para complementar Wyndis:'
    Write-Host ''

    $tools = @(
        @{
            Name = 'Windows Security (Defender)'
            Use  = 'Antivirus integrado - ya incluido en Windows'
            Cost = 'Gratis'
            Must = $true
        },
        @{
            Name = 'Bitwarden'
            Use  = 'Gestor de contraseñas seguro'
            Cost = 'Gratis'
            Must = $true
        },
        @{
            Name = '7-Zip'
            Use  = 'Compresión de archivos (alternativa segura a WinRAR pirata)'
            Cost = 'Gratis'
            Must = $false
        },
        @{
            Name = 'Firefox / Brave'
            Use  = 'Navegador con buenas opciones de privacidad'
            Cost = 'Gratis'
            Must = $false
        },
        @{
            Name = 'VeraCrypt'
            Use  = 'Cifrado de discos y contenedores'
            Cost = 'Gratis'
            Must = $false
        },
        @{
            Name = 'Autoruns (Sysinternals)'
            Use  = 'Análisis avanzado de inicio automático'
            Cost = 'Gratis (Microsoft)'
            Must = $false
        },
        @{
            Name = 'Process Explorer (Sysinternals)'
            Use  = 'Monitor de procesos avanzado'
            Cost = 'Gratis (Microsoft)'
            Must = $false
        },
        @{
            Name = 'O&O ShutUp10++'
            Use  = 'Privacidad en Windows 10/11'
            Cost = 'Gratis'
            Must = $false
        },
        @{
            Name = 'WinMerge'
            Use  = 'Comparar archivos y carpetas'
            Cost = 'Gratis'
            Must = $false
        },
        @{
            Name = 'Wireshark'
            Use  = 'Análisis de red (solo para usuarios avanzados)'
            Cost = 'Gratis'
            Must = $false
        }
    )

    foreach ($tool in $tools) {
        $tag = if ($tool.Must) { '[ ESENCIAL ]' } else { '[ OPCIONAL ]' }
        if ($NoColor) {
            Write-WyndisRaw "  $tag $($tool.Name) - $($tool.Use) ($($tool.Cost))"
        } else {
            $color = if ($tool.Must) { 'Green' } else { 'Gray' }
            Write-Host "  $tag " -NoNewline -ForegroundColor $color
            Write-Host "$($tool.Name)" -NoNewline
            Write-Host " - $($tool.Use) ($($tool.Cost))"
            $Script:ReportLines.Add("  $tag $($tool.Name) - $($tool.Use) ($($tool.Cost))")
        }
    }

    Write-Host ''
    Write-WyndisSuggest 'Para empresas pequeñas: combina Wyndis + Bitwarden + backups en OneDrive/Google Drive.'
    Write-WyndisSuggest 'Ejecuta Wyndis cada mes o después de instalar software nuevo.'
    Write-WyndisSuggest 'Descarga Sysinternals desde: https://learn.microsoft.com/sysinternals'
}
