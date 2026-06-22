# SPDX-License-Identifier: MIT
# Wyndis - Display helpers (estilo Lynis)

function Write-WyndisRaw {
    param([string]$Line)
    Write-Host $Line
    $Script:ReportLines.Add($Line)
}

function Write-WyndisOk {
    param([string]$Message)
    if ($NoColor) {
        Write-WyndisRaw "  [ OK ] $Message"
    } else {
        Write-Host '  ' -NoNewline
        Write-Host '[ OK ]' -ForegroundColor Green -NoNewline
        Write-Host " $Message"
        $Script:ReportLines.Add("  [ OK ] $Message")
    }
}

function Write-WyndisWarning {
    param([string]$Message, [string]$Id = '')
    Add-WyndisFinding -Severity 'warning' -Message $Message -Id $Id
    if ($NoColor) {
        Write-WyndisRaw "  [ WARN ] $Message"
    } else {
        Write-Host '  ' -NoNewline
        Write-Host '[ WARN ]' -ForegroundColor Yellow -NoNewline
        Write-Host " $Message"
        $Script:ReportLines.Add("  [ WARN ] $Message")
    }
}

function Write-WyndisCritical {
    param([string]$Message, [string]$Id = '')
    Add-WyndisFinding -Severity 'critical' -Message $Message -Id $Id
    if ($NoColor) {
        Write-WyndisRaw "  [ CRIT ] $Message"
    } else {
        Write-Host '  ' -NoNewline
        Write-Host '[ CRIT ]' -ForegroundColor Red -NoNewline
        Write-Host " $Message"
        $Script:ReportLines.Add("  [ CRIT ] $Message")
    }
}

function Write-WyndisSuggest {
    param([string]$Message)
    if ($NoColor) {
        Write-WyndisRaw "  [ SUGG ] $Message"
    } else {
        Write-Host '  ' -NoNewline
        Write-Host '[ SUGG ]' -ForegroundColor Cyan -NoNewline
        Write-Host " $Message"
        $Script:ReportLines.Add("  [ SUGG ] $Message")
    }
}

function Write-WyndisInfo {
    param([string]$Message)
    if ($NoColor) {
        Write-WyndisRaw "  [ INFO ] $Message"
    } else {
        Write-Host '  ' -NoNewline
        Write-Host '[ INFO ]' -ForegroundColor Gray -NoNewline
        Write-Host " $Message"
        $Script:ReportLines.Add("  [ INFO ] $Message")
    }
}

function Write-WyndisSection {
    param([string]$Title)
    Write-Host ''
    $line = "== $Title =="
    if ($NoColor) {
        Write-WyndisRaw $line
    } else {
        Write-Host $line -ForegroundColor White
        $Script:ReportLines.Add($line)
    }
}

function Show-WyndisBanner {
    $banner = @"

   __      __  _   _ _____ _   _ ____ ___ ___
   \ \    / / | \ | | ____| \ | |  _ \_ _/ _ \
    \ \  / /  |  \| |  _| |  \| | | | | | | | |
     \ \/ /   | |\  | |___| |\  | |_| | | |_| |
      \__/    |_| \_|_____|_| \_|____/___\___/

   Auditor de seguridad para Windows v$Script:WyndisVersion
   Licencia MIT - 100% gratuito
   Inspirado en Lynis | wyndis.help@gmail.com
   Website: wyndis-download-ce9eb.web.app

"@
    if ($NoColor) {
        Write-WyndisRaw $banner
    } else {
        Write-Host $banner -ForegroundColor Cyan
        $Script:ReportLines.Add($banner)
    }
}

function Show-WyndisScore {
    param([hashtable]$Score)

    Write-Host ''
    $bar = '=' * 50
    Write-WyndisRaw $bar
    Write-WyndisRaw "  PUNTUACION DE SEGURIDAD: $($Score.Grade) / 100"
    Write-WyndisRaw "  ($($Score.Label))"
    Write-WyndisRaw $bar
    Write-Host ''

    $barLen = [math]::Floor($Score.Grade / 2)
    $barStr = '#' * $barLen + '-' * (50 - $barLen)
    Write-WyndisRaw "  [$barStr] $($Score.Grade)%"
    Write-Host ''

    if ($Score.Critical -gt 0) {
        Write-WyndisCritical "Se encontraron $($Score.Critical) problema(s) critico(s)."
    }
    if ($Score.Warning -gt 0) {
        Write-WyndisWarning "Se encontraron $($Score.Warning) advertencia(s)."
    }
    if ($Score.Grade -ge 90) {
        Write-WyndisOk '!Excelente! No se detectaron vulnerabilidades significativas.'
    }

    Write-Host ''
    Write-WyndisInfo "Hallazgos totales: $($Score.Total) (Criticos: $($Score.Critical) | Advertencias: $($Score.Warning))"
}

function Export-WyndisPdfReport {
    param([hashtable]$Score)

    $outputDir = Join-Path $env:USERPROFILE 'Desktop'
    $timestamp = Get-Date -Format 'yyyy-MM-dd-HHmm'
    $htmlPath = Join-Path $env:TEMP "wyndis-report-$timestamp.html"
    $pdfPath  = Join-Path $outputDir "Wyndis-Informe-$timestamp.pdf"

    $criticalList = $Script:Findings | Where-Object { $_.Severity -eq 'critical' }
    $warningList  = $Script:Findings | Where-Object { $_.Severity -eq 'warning' }

    $scoreColor = switch ($true) {
        ($Score.Grade -ge 90) { '#10b981' }
        ($Score.Grade -ge 75) { '#3b82f6' }
        ($Score.Grade -ge 50) { '#f59e0b' }
        ($Score.Grade -ge 25) { '#f97316' }
        default               { '#ef4444' }
    }

    $scoreLabel = switch ($true) {
        ($Score.Grade -ge 90) { 'Excelente' }
        ($Score.Grade -ge 75) { 'Bueno' }
        ($Score.Grade -ge 50) { 'Regular' }
        ($Score.Grade -ge 25) { 'Malo' }
        default               { 'Critico' }
    }

    $criticalRows = ''
    $c = 0
    foreach ($f in $criticalList) {
        $c++
        $icon = '&#x2716;'
        $criticalRows += "<tr><td>$c</td><td>$($f.Category)</td><td>$($f.Message)</td><td style='color:#ef4444'><b>$icon Critico</b></td></tr>"
    }
    if (-not $criticalRows) { $criticalRows = '<tr><td colspan="4" style="color:#10b981">No se detectaron hallazgos criticos.</td></tr>' }

    $warningRows = ''
    $w = 0
    foreach ($f in $warningList) {
        $w++
        $icon = '&#x26A0;'
        $warningRows += "<tr><td>$w</td><td>$($f.Category)</td><td>$($f.Message)</td><td style='color:#f59e0b'><b>$icon Advertencia</b></td></tr>"
    }
    if (-not $warningRows) { $warningRows = '<tr><td colspan="4" style="color:#10b981">No se detectaron advertencias.</td></tr>' }

    $osInfo = Get-CimInstance Win32_OperatingSystem
    $csInfo = Get-CimInstance Win32_ComputerSystem

    $barFill = [math]::Floor($Score.Grade / 2)
    $barEmpty = 50 - $barFill
    $barSvg = "<div style='background:#1e293b;border-radius:8px;height:24px;width:100%;overflow:hidden;'>
    <div style='width:$($Score.Grade)%;height:100%;background:linear-gradient(90deg,$scoreColor,#60a5fa);border-radius:8px;display:flex;align-items:center;justify-content:center;color:#fff;font-size:12px;font-weight:bold;'>$($Score.Grade)/100</div></div>"

    $html = @"
<!DOCTYPE html>
<html><head>
<meta charset='UTF-8'>
<title>Wyndis - Informe de Auditoria</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body { font-family:'Segoe UI',system-ui; background:#0f172a; color:#e2e8f0; padding:40px; }
  .header { text-align:center; padding:30px; background:linear-gradient(135deg,#1e293b,#0f172a); border-radius:16px; border:1px solid #334155; margin-bottom:30px; }
  .header h1 { font-size:28px; background:linear-gradient(to right,#3b82f6,#10b981); -webkit-background-clip:text; -webkit-text-fill-color:transparent; }
  .header p { color:#94a3b8; margin-top:8px; }
  .score-box { background:linear-gradient(135deg,#1e293b,#0f172a); border-radius:16px; padding:30px; border:1px solid #334155; margin-bottom:30px; }
  .score-box h2 { color:#94a3b8; font-size:14px; text-transform:uppercase; letter-spacing:1px; margin-bottom:15px; }
  .score-grid { display:flex; gap:20px; flex-wrap:wrap; }
  .score-item { flex:1; min-width:120px; background:#1e293b; border-radius:12px; padding:20px; text-align:center; border:1px solid #334155; }
  .score-item .num { font-size:32px; font-weight:800; }
  .score-item .lbl { font-size:12px; color:#94a3b8; margin-top:4px; }
  table { width:100%; border-collapse:collapse; margin-top:15px; }
  th { text-align:left; padding:12px 16px; color:#94a3b8; font-size:12px; text-transform:uppercase; border-bottom:1px solid #334155; }
  td { padding:12px 16px; border-bottom:1px solid #1e293b; font-size:14px; }
  .section { margin-bottom:30px; }
  .section h2 { color:#e2e8f0; font-size:18px; margin-bottom:15px; display:flex; align-items:center; gap:8px; }
  .footer { text-align:center; padding:20px; color:#475569; font-size:12px; border-top:1px solid #1e293b; margin-top:30px; }
  .badge { display:inline-block; padding:2px 10px; border-radius:999px; font-size:11px; font-weight:600; }
  .badge-blue { background:rgba(59,130,246,0.15); color:#60a5fa; border:1px solid rgba(59,130,246,0.3); }
</style>
</head><body>

<div class='header'>
  <h1>Wyndis - Informe de Auditoria</h1>
  <p>Generado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Equipo: $($csInfo.Name) | v$Script:WyndisVersion</p>
  <p style='margin-top:4px'><span class='badge badge-blue'>MIT License</span> wyndis-download-ce9eb.web.app</p>
</div>

<div class='score-box'>
  <h2>Puntuacion de Seguridad</h2>
  $barSvg
  <div class='score-grid' style='margin-top:20px'>
    <div class='score-item'><div class='num' style='color:$scoreColor'>$($Score.Grade)</div><div class='lbl'>/ 100</div></div>
    <div class='score-item'><div class='num' style='color:#ef4444'>$($Score.Critical)</div><div class='lbl'>Criticos</div></div>
    <div class='score-item'><div class='num' style='color:#f59e0b'>$($Score.Warning)</div><div class='lbl'>Advertencias</div></div>
    <div class='score-item'><div class='num' style='color:#3b82f6'>$($Score.Total)</div><div class='lbl'>Total Hallazgos</div></div>
  </div>
  <div style='margin-top:15px;font-size:14px;color:#94a3b8;'>Etiqueta: <b style='color:$scoreColor'>$scoreLabel</b></div>
</div>

<div class='section'>
  <h2><span style='color:#ef4444'>&#x2716;</span> Hallazgos Criticos ($($Score.Critical))</h2>
  <table><tr><th>#</th><th>Categoria</th><th>Descripcion</th><th>Severidad</th></tr>$criticalRows</table>
</div>

<div class='section'>
  <h2><span style='color:#f59e0b'>&#x26A0;</span> Advertencias ($($Score.Warning))</h2>
  <table><tr><th>#</th><th>Categoria</th><th>Descripcion</th><th>Severidad</th></tr>$warningRows</table>
</div>

<div class='section'>
  <h2><span style='color:#3b82f6'>&#x2139;</span> Resumen de la Auditoria</h2>
  <table>
    <tr><td style='width:200px'>Sistema Operativo</td><td>$($os.Caption) ($($os.Version))</td></tr>
    <tr><td>Arquitectura</td><td>$($os.OSArchitecture)</td></tr>
    <tr><td>Ultimo arranque</td><td>$($os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm'))</td></tr>
    <tr><td>Modulos ejecutados</td><td>$($Script:ModulesExecuted)</td></tr>
    <tr><td>Duracion</td><td>$($Script:AuditDuration) segundos</td></tr>
  </table>
</div>

<div class='footer'>
  Generado por Wyndis v$Script:WyndisVersion | MIT License | wyndis-download-ce9eb.web.app | Contacto: wyndis.help@gmail.com
</div>

</body></html>
"@

    try {
        $html | Out-File -FilePath $htmlPath -Encoding UTF8 -Force
        Write-WyndisInfo "Generando PDF desde: $htmlPath"

        Start-Process -FilePath "msedge.exe" -ArgumentList "--headless --disable-gpu --print-to-pdf=`"$pdfPath`" `"$htmlPath`"" -NoNewWindow -Wait -ErrorAction Stop

        if (Test-Path $pdfPath) {
            Write-WyndisOk "PDF generado exitosamente: $pdfPath"
            Remove-Item -Path $htmlPath -Force -ErrorAction SilentlyContinue
            return $pdfPath
        }
    } catch {
        try {
            Start-Process -FilePath "chrome.exe" -ArgumentList "--headless --disable-gpu --print-to-pdf=`"$pdfPath`" `"$htmlPath`"" -NoNewWindow -Wait -ErrorAction Stop
            if (Test-Path $pdfPath) {
                Write-WyndisOk "PDF generado exitosamente: $pdfPath"
                Remove-Item -Path $htmlPath -Force -ErrorAction SilentlyContinue
                return $pdfPath
            }
        } catch {
            Write-WyndisWarning "No se pudo generar PDF automaticamente. Se guardo el reporte HTML en: $htmlPath"
            Write-WyndisSuggest "Abre $htmlPath en Edge/Chrome y usa Ctrl+P -> Guardar como PDF"
            return $htmlPath
        }
    }
}
