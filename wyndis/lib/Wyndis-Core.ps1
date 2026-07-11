# SPDX-License-Identifier: MIT
# Wyndis Core Module - Sistema base, helpers, utilidades, history/timeline

# Variables globales del script
$Script:WyndisVersion = '4.0.0'
$Script:WyndisStartTime = Get-Date
$Script:Findings = [System.Collections.Generic.List[object]]::new()
$Script:ReportLines = [System.Collections.Generic.List[string]]::new()
$Script:ModulesExecuted = 0
$Script:AuditDuration = 0
$Script:SystemInfo = @{}
$Script:HistoryPath = "$env:ProgramData\Wyndis\history"
$Script:MaxHistoryEntries = 50
$Script:ConfidenceThreshold = 70

# Colores ANSI para consola
$Script:Colors = @{
    Reset      = "`e[0m"
    Red        = "`e[31m"
    Green      = "`e[32m"
    Yellow     = "`e[33m"
    Blue       = "`e[34m"
    Magenta    = "`e[35m"
    Cyan       = "`e[36m"
    White      = "`e[37m"
    Gray       = "`e[90m"
    Bold       = "`e[1m"
    Dim        = "`e[2m"
    Underline  = "`e[4m"
}

function Test-WyndisAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-WyndisColor {
    param([string]$Color)
    if ($Script:NoColor) { return '' }
    return $Script:Colors[$Color]
}

function Write-WyndisBanner {
    $c = $Script:Colors
    $reset = $c.Reset
    Write-Host ""
    Write-Host "$($c.Cyan)$($c.Bold)  ╔══════════════════════════════════════════════════════════════╗$reset"
    Write-Host "$($c.Cyan)$($c.Bold)  ║                  Wyndis v$Script:WyndisVersion — Security Advisor           ║$reset"
    Write-Host "$($c.Cyan)$($c.Bold)  ║           MIT License | Open Source | Enterprise Ready         ║$reset"
    Write-Host "$($c.Cyan)$($c.Bold)  ║           https://github.com/octcenano/wyndis                ║$reset"
    Write-Host "$($c.Cyan)$($c.Bold)  ╚══════════════════════════════════════════════════════════════╝$reset"
    Write-Host ""
    Write-Host "$($c.White)  Auditor de seguridad profesional para Windows y Linux$reset"
    Write-Host "$($c.Gray)  30+ módulos · 345+ checks · Dual-mode PDF · Timeline · Confidence$reset"
    Write-Host "$($c.Gray)  100% gratuito · Código abierto (MIT) · Sin telemetría$reset"
    Write-Host ""
    Write-Host "$($c.Blue)  🌐 Web: https://wyndis-download-ce9eb.web.app$reset"
    Write-Host "$($c.Blue)  💻 GitHub: https://github.com/octcenano/wyndis$reset"
    Write-Host "$($c.Blue)  💬 Discord: https://discord.gg/wyndis$reset"
    Write-Host ""
    Write-Host "$($c.Yellow)  ⚠ Wyndis NO recopila telemetría ni datos personales.$reset"
    Write-Host "$($c.Yellow)  ⚠ Todo el análisis se ejecuta localmente en tu máquina.$reset"
    Write-Host ""
}

function Invoke-WyndisSystemInfo {
    Write-WyndisInfo 'Recopilando información del sistema...'
    
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $cs = Get-CimInstance Win32_ComputerSystem
        $bios = Get-CimInstance Win32_BIOS
        $proc = Get-CimInstance Win32_Processor
        
        $Script:SystemInfo = @{
            ComputerName   = $env:COMPUTERNAME
            UserName       = $env:USERNAME
            Domain         = $env:USERDOMAIN
            OSName         = $os.Caption
            OSVersion      = $os.Version
            OSBuild        = $os.BuildNumber
            OSInstallDate  = $os.InstallDate
            LastBootUpTime = $os.LastBootUpTime
            Manufacturer   = $cs.Manufacturer
            Model          = $cs.Model
            TotalMemoryGB  = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
            CPUName        = $proc[0].Name
            CPUCores       = $proc[0].NumberOfCores
            CPULogical     = $proc[0].NumberOfLogicalProcessors
            BIOSBIOSVersion = $bios.SMBIOSBIOSVersion
            BIOSDate       = $bios.ReleaseDate
            IsAdmin        = (Test-WyndisAdmin)
        }
        
        $uptime = (Get-Date) - $Script:SystemInfo.LastBootUpTime
        $Script:SystemInfo.Uptime = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
        
        Write-WyndisOk "Equipo: $($Script:SystemInfo.ComputerName)"
        Write-WyndisOk "Usuario: $($Script:SystemInfo.UserName) @ $($Script:SystemInfo.Domain)"
        Write-WyndisOk "SO: $($Script:SystemInfo.OSName) $($Script:SystemInfo.OSVersion) (Build $($Script:SystemInfo.OSBuild))"
        Write-WyndisOk "Instalado: $($Script:SystemInfo.OSInstallDate.ToString('yyyy-MM-dd'))"
        Write-WyndisOk "Último arranque: $($Script:SystemInfo.LastBootUpTime.ToString('yyyy-MM-dd HH:mm'))"
        Write-WyndisOk "Uptime: $($Script:SystemInfo.Uptime)"
        Write-WyndisOk "Hardware: $($Script:SystemInfo.Manufacturer) $($Script:SystemInfo.Model)"
        Write-WyndisOk "CPU: $($Script:SystemInfo.CPUName) ($($Script:SystemInfo.CPUCores)C/$($Script:SystemInfo.CPULogical)L)"
        Write-WyndisOk "RAM: $($Script:SystemInfo.TotalMemoryGB) GB"
        Write-WyndisOk "BIOS: $($Script:SystemInfo.BIOSBIOSVersion) ($($Script:SystemInfo.BIOSDate.ToString('yyyy-MM-dd')))"
        Write-WyndisOk "Administrador: $(if ($Script:SystemInfo.IsAdmin) { 'Sí' } else { 'No' })"
    }
    catch {
        Write-WyndisError "Error recopilando info del sistema: $_"
    }
}

function Add-WyndisFinding {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Category,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('Critical','Warning')][string]$Severity,
        [string]$Details = '',
        [string]$Remediation = '',
        [string]$Reference = '',
        [int]$Confidence = 85,
        [int]$EstimatedHours = 2,
        [string]$MITRE = '',
        [string]$CVE = ''
    )
    
    $finding = [PSCustomObject]@{
        Id              = $Id
        Category        = $Category
        Name            = $Name
        Severity        = $Severity
        Details         = $Details
        Remediation     = $Remediation
        Reference       = $Reference
        Confidence      = $Confidence
        EstimatedHours  = $EstimatedHours
        EstimatedDays   = [math]::Ceiling($EstimatedHours / 8)
        MITRE           = $MITRE
        CVE             = $CVE
        Timestamp       = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        FirstSeen       = Get-Date -Format 'yyyy-MM-dd'
        Status          = 'Open'
    }
    
    $Script:Findings.Add($finding)
    
    $color = if ($Severity -eq 'Critical') { $Script:Colors.Red } else { $Script:Colors.Yellow }
    $prefix = if ($Severity -eq 'Critical') { '[CRIT]' } else { '[WARN]' }
    
    $confText = if ($Confidence -lt 70) { " $($Script:Colors.Red)[CONF $Confidence% - VERIFICAR]$($Script:Colors.Reset)" } else { " $($Script:Colors.Gray)[Conf $Confidence%]$($Script:Colors.Reset)" }
    $timeText = " $($Script:Colors.Gray)[~$EstimatedHours h]$($Script:Colors.Reset)"
    
    Write-Host "  $color$prefix$($Script:Colors.Reset) $Category - $Name$confText$timeText"
    if ($Details) { Write-Host "       $($Script:Colors.Gray)$Details$($Script:Colors.Reset)" }
    if ($MITRE) { Write-Host "       $($Script:Colors.Magenta)MITRE: $MITRE$($Script:Colors.Reset)" }
    if ($CVE) { Write-Host "       $($Script:Colors.Red)CVE: $CVE$($Script:Colors.Reset)" }
}

function Write-WyndisSection { param([string]$Title) { Write-Host ""; Write-Host "$($Script:Colors.Cyan)$($Script:Colors.Bold)== $Title ==$($Script:Colors.Reset)" } }
function Write-WyndisOk    { param([string]$Msg) { Write-Host "  $($Script:Colors.Green)[ OK ]$($Script:Colors.Reset) $Msg" } }
function Write-WyndisWarn  { param([string]$Msg) { Write-Host "  $($Script:Colors.Yellow)[WARN]$($Script:Colors.Reset) $Msg" } }
function Write-WyndisCrit  { param([string]$Msg) { Write-Host "  $($Script:Colors.Red)[CRIT]$($Script:Colors.Reset) $Msg" } }
function Write-WyndisInfo  { param([string]$Msg) { Write-Host "  $($Script:Colors.Blue)[INFO]$($Script:Colors.Reset) $Msg" } }
function Write-WyndisError { param([string]$Msg) { Write-Host "  $($Script:Colors.Red)[ERR ]$($Script:Colors.Reset) $Msg" } }
function Write-WyndisSuggest { param([string]$Msg) { Write-Host "  $($Script:Colors.Magenta)[SUGG]$($Script:Colors.Reset) $Msg" } }

# ===== HISTORY / TIMELINE FUNCTIONS =====

function Initialize-WyndisHistory {
    if (-not (Test-Path $Script:HistoryPath)) {
        New-Item -ItemType Directory -Path $Script:HistoryPath -Force | Out-Null
        $acl = Get-Acl $Script:HistoryPath
        $acl.SetAccessRuleProtection($true, $false)
        $admins = New-Object System.Security.AccessControl.FileSystemAccessRule('BUILTIN\Administrators','FullControl','ContainerInherit,ObjectInherit','None','Allow')
        $system = New-Object System.Security.AccessControl.FileSystemAccessRule('SYSTEM','FullControl','ContainerInherit,ObjectInherit','None','Allow')
        $acl.SetAccessRule($admins)
        $acl.SetAccessRule($system)
        Set-Acl -Path $Script:HistoryPath -AclObject $acl
    }
}

function Save-WyndisAuditSnapshot {
    param([hashtable]$Score)
    
    Initialize-WyndisHistory
    
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $snapshotFile = Join-Path $Script:HistoryPath "audit-$timestamp.json"
    
    $snapshot = @{
        Timestamp     = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
        Version       = $Script:WyndisVersion
        Host          = $Script:SystemInfo.ComputerName
        OS            = $Script:SystemInfo.OSName
        User          = "$($Script:SystemInfo.UserName)@$($Script:SystemInfo.Domain)"
        IsAdmin       = $Script:SystemInfo.IsAdmin
        DurationSec   = $Script:AuditDuration
        ModulesRun    = $Script:ModulesExecuted
        Score         = $Score
        Findings      = $Script:Findings
        AttackSim     = $global:WyndisAttackSimulation
        Roadmap       = $global:WyndisRoadmap
        LOLBinInv     = $global:WyndisLOLBinInventory
    }
    
    $snapshot | ConvertTo-Json -Depth 6 | Out-File -FilePath $snapshotFile -Encoding UTF8
    
    # Limpiar histórico antiguo
    $files = Get-ChildItem $Script:HistoryPath -Filter 'audit-*.json' | Sort-Object LastWriteTime -Descending
    if ($files.Count -gt $Script:MaxHistoryEntries) {
        $files | Select-Object -Skip $Script:MaxHistoryEntries | Remove-Item -Force
    }
    
    Write-WyndisInfo "Snapshot guardado: $snapshotFile"
    return $snapshotFile
}

function Load-WyndisHistory {
    param([int]$Limit = 10)
    
    Initialize-WyndisHistory
    $files = Get-ChildItem $Script:HistoryPath -Filter 'audit-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First $Limit
    
    $history = @()
    foreach ($f in $files) {
        try {
            $data = Get-Content $f.FullName -Raw | ConvertFrom-Json
            $history += [PSCustomObject]@{
                File         = $f.Name
                Date         = $data.Timestamp
                Score        = $data.Score.Score
                Total        = $data.Score.Total
                Critical     = $data.Score.Critical
                Warning      = $data.Score.Warning
                Duration     = $data.DurationSec
                Modules      = $data.ModulesRun
                FindingsCount= $data.Findings.Count
            }
        } catch { }
    }
    return $history
}

function Compare-WyndisAudits {
    param(
        [string]$BaselineFile,
        [string]$CurrentFile
    )
    
    Write-WyndisSection "COMPARACIÓN DE AUDITORÍAS"
    
    $baseline = if (Test-Path $BaselineFile) { Get-Content $BaselineFile -Raw | ConvertFrom-Json } else { throw "Baseline no encontrado: $BaselineFile" }
    $current = if (Test-Path $CurrentFile) { Get-Content $CurrentFile -Raw | ConvertFrom-Json } else { throw "Current no encontrado: $CurrentFile" }
    
    # Score comparison
    $scoreDiff = $current.Score.Score - $baseline.Score.Score
    $scoreDir = if ($scoreDiff -gt 0) { "↑ MEJORA" } elseif ($scoreDiff -lt 0) { "↓ EMPEORA" } else { "→ SIN CAMBIOS" }
    Write-WyndisInfo "Score: $($baseline.Score.Score) → $($current.Score.Score) ($scoreDiff $scoreDir)"
    
    # Findings comparison
    $baseIds = $baseline.Findings.Id | Sort-Object -Unique
    $currIds = $current.Findings.Id | Sort-Object -Unique
    
    $new = $currIds | Where-Object { $_ -notin $baseIds }
    $fixed = $baseIds | Where-Object { $_ -notin $currIds }
    $persistent = $currIds | Where-Object { $_ -in $baseIds }
    
    Write-WyndisOk "Nuevos hallazgos: $($new.Count)"
    Write-WyndisOk "Corregidos: $($fixed.Count)"
    Write-WyndisInfo "Persistentes: $($persistent.Count)"
    
    if ($new.Count -gt 0) {
        Write-Host ""
        Write-Host "$($Script:Colors.Yellow)NUEVOS HALLAZGOS:$($Script:Colors.Reset)"
        foreach ($id in $new) {
            $f = $current.Findings | Where-Object { $_.Id -eq $id }
            Write-Host "  [$($f.Severity)] $($f.Id) - $($f.Name) [$($f.Category)]"
        }
    }
    
    if ($fixed.Count -gt 0) {
        Write-Host ""
        Write-Host "$($Script:Colors.Green)CORREGIDOS:$($Script:Colors.Reset)"
        foreach ($id in $fixed) {
            $f = $baseline.Findings | Where-Object { $_.Id -eq $id }
            Write-Host "  [$($f.Severity)] $($f.Id) - $($f.Name) [$($f.Category)]"
        }
    }
    
    # Category trend
    Write-Host ""
    Write-Host "TENDENCIA POR CATEGORÍA:"
    $cats = @($baseline.Findings.Category, $current.Findings.Category) | Sort-Object -Unique
    foreach ($c in $cats) {
        $baseCount = ($baseline.Findings | Where-Object { $_.Category -eq $c }).Count
        $currCount = ($current.Findings | Where-Object { $_.Category -eq $c }).Count
        $diff = $currCount - $baseCount
        $arrow = if ($diff -gt 0) { "↑" } elseif ($diff -lt 0) { "↓" } else { "→" }
        Write-Host "  $c: $baseCount → $currCount ($arrow $diff)"
    }
}

function Show-WyndisTimeline {
    param([int]$Days = 90)
    
    Write-WyndisSection "TIMELINE DE HALLAZGOS (últimos $Days días)"
    
    $history = Load-WyndisHistory -Limit 100
    $cutoff = (Get-Date).AddDays(-$Days)
    
    $timeline = $history | Where-Object { [DateTime]::Parse($_.Date) -ge $cutoff } | Sort-Object Date
    
    if ($timeline.Count -eq 0) {
        Write-WyndisInfo "Sin historial en los últimos $Days días."
        return
    }
    
    Write-Host ""
    foreach ($entry in $timeline) {
        $date = [DateTime]::Parse($entry.Date).ToString('yyyy-MM-dd HH:mm')
        $trend = ""
        if ($entry.Score -ge 90) { $trend = "$($Script:Colors.Green)🟢$($Script:Colors.Reset)" }
        elseif ($entry.Score -ge 70) { $trend = "$($Script:Colors.Yellow)🟡$($Script:Colors.Reset)" }
        elseif ($entry.Score -ge 40) { $trend = "$($Script:Colors.Magenta)🟠$($Script:Colors.Reset)" }
        elseif ($entry.Score -ge 10) { $trend = "$($Script:Colors.Red)🔴$($Script:Colors.Reset)" }
        else { $trend = "$($Script:Colors.Red)$($Script:Colors.Bold)⚫$($Script:Colors.Reset)" }
        
        Write-Host "  $date | Score: $($entry.Score)/100 $trend | Hallazgos: $($entry.FindingsCount) (C:$($entry.Critical) W:$($entry.Warning)) | Dur: $($entry.Duration)s"
    }
    
    # Trend analysis
    if ($timeline.Count -ge 2) {
        $first = $timeline[-1].Score
        $last = $timeline[0].Score
        $trend = $last - $first
        $trendText = if ($trend -gt 0) { "MEJORANDO ↑" } elseif ($trend -lt 0) { "EMPEORANDO ↓" } else { "ESTABLE →" }
        Write-Host ""
        Write-Host "Tendencia ($Days días): $first → $last ($trend $trendText)"
    }
}

Export-ModuleMember -Function *
Export-ModuleMember -Variable Colors, WyndisVersion, WyndisStartTime, Findings, ReportLines, ModulesExecuted, AuditDuration, SystemInfo, NoColor, HistoryPath, MaxHistoryEntries, ConfidenceThreshold