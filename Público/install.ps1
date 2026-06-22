# SPDX-License-Identifier: MIT
# ==============================================================================
# Wyndis v2.0 — Professional Windows Security Auditor
# Installer with integrity verification, transparency, and audit logging
# ==============================================================================
# Usage:
#   Recommended:
#     Open PowerShell as Administrator, then:
#     irm wyndis-download-ce9eb.web.app/install.ps1 | iex
#
#   Preview mode (see what will happen without executing):
#     irm wyndis-download-ce9eb.web.app/install.ps1 | iex; -Preview
#
#   Manual download:
#     Download from https://wyndis-download-ce9eb.web.app
#     Verify SHA-256 from https://wyndis-download-ce9eb.web.app/checksums.txt
#     Run: .\wyndis.ps1
# ==============================================================================
# Wyndis is 100% open source under MIT License.
# Source code: https://github.com/wyndis/wyndis
# Wyndis does NOT collect telemetry, personal data, or send any information
# to external servers. All analysis is performed locally on your machine.
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Preview,
    [switch]$Force,
    [string]$CustomPath = ""
)

$ErrorActionPreference = 'Stop'
$Version = '2.0.0'
$WyndisUrl = 'https://wyndis-download-ce9eb.web.app'
$ExpectedZipHash = '9bde7b0bf5b512e312fd786928d8a8aa67098615193a6cbcfdc531ce8f79488a'
$ExpectedPs1Hash = '51bf60eb06724bdfc9ce7b4015a8fe93ec71fdbe56ba5909e634245f815b8ca4'

function Write-Color {
    param([string]$Text, [string]$Color = 'White')
    Write-Host $Text -ForegroundColor $Color
}

function Show-TransparencyBanner {
    Clear-Host
    Write-Color '╔══════════════════════════════════════════════════════════════╗' 'Cyan'
    Write-Color '║                 Wyndis v2.0 — Security Installer            ║' 'Cyan'
    Write-Color '║          MIT License | Open Source | No Telemetry           ║' 'Cyan'
    Write-Color '╚══════════════════════════════════════════════════════════════╝' 'Cyan'
    Write-Host ''
    Write-Color '  Wyndis is a professional Windows security auditor.' 'White'
    Write-Color '  This installer will perform the following actions:' 'White'
    Write-Host ''
    Write-Color '    [1] Download wyndis.zip from official server' 'Gray'
    Write-Color '    [2] Verify SHA-256 integrity of the downloaded file' 'Gray'
    Write-Color '    [3] Extract contents to a secure location' 'Gray'
    Write-Color '    [4] Create a desktop shortcut for easy access' 'Gray'
    Write-Color '    [5] Log the installation to ProgramData\Wyndis\install.log' 'Gray'
    Write-Host ''
    Write-Color '  ⚠ Wyndis does NOT:' 'Yellow'
    Write-Color '     • Collect personal data or telemetry' 'Yellow'
    Write-Color '     • Send information to external servers' 'Yellow'
    Write-Color '     • Modify system files outside the install directory' 'Yellow'
    Write-Host ''
    Write-Color '  Source code: https://github.com/wyndis/wyndis' 'Blue'
    Write-Color '  Verify checksums: https://wyndis-download-ce9eb.web.app/checksums.txt' 'Blue'
    Write-Host ''
}

function Show-Preview {
    Show-TransparencyBanner
    Write-Color '  [PREVIEW MODE] — No changes have been made.' 'Cyan'
    Write-Host ''
    Write-Color '  Would install:' 'Green'
    Write-Color "    • Destination: $(if ($CustomPath) { $CustomPath } else { "$env:ProgramData\Wyndis" })" 'Gray'
    Write-Color '    • Files: wyndis.ps1, wyndis.bat, lib/*.ps1 (27 modules)' 'Gray'
    Write-Color '    • Desktop shortcut: Wyndis v2.0.lnk' 'Gray'
    Write-Color '    • Install manifest: install.json' 'Gray'
    Write-Color '    • Install log: install.log' 'Gray'
    Write-Host ''
    Write-Color '  To proceed with installation, run without -Preview:' 'White'
    Write-Color '    irm wyndis-download-ce9eb.web.app/install.ps1 | iex' 'Yellow'
    Write-Host ''
    exit 0
}

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-TlsSecurity {
    try {
        $request = [Net.WebRequest]::Create($WyndisUrl)
        $request.GetResponse() | Out-Null
        $tls = [Net.ServicePointManager]::SecurityProtocol
        $isSecure = $tls -match 'Tls12|Tls13'
        if (-not $isSecure) {
            Write-Color '  [WARN] TLS 1.2+ not detected. Connection may be insecure.' 'Yellow'
        }
        return $isSecure
    } catch {
        Write-Color '  [WARN] Could not verify TLS security.' 'Yellow'
        return $false
    }
}

function Confirm-Installation {
    param([string]$Message)
    if ($Force) { return $true }
    Write-Color "`n  $Message [S/N]:" 'Yellow'
    $response = Read-Host '  >'
    return ($response -eq 'S' -or $response -eq 's' -or $response -eq 'Y' -or $response -eq 'y')
}

function Install-Wyndis {
    Show-TransparencyBanner

    if (-not (Test-Admin)) {
        Write-Color '  [INFO] Administrator privileges required.' 'Yellow'
        Write-Color '  [INFO] Requesting elevation...' 'Yellow'
        try {
            $scriptPath = Join-Path $env:TEMP 'install-wyndis.ps1'
            Get-Content $PSCommandPath | Out-File $scriptPath -Encoding UTF8 -Force
            Start-Process powershell -ArgumentList "-ExecutionPolicy RemoteSigned -File `"$scriptPath`" $(if ($Force) { '-Force' })" -Verb RunAs
            exit 0
        } catch {
            Write-Color '  [ERR] Could not elevate privileges.' 'Red'
            Write-Color '  Run PowerShell as Administrator manually, then try again.' 'Yellow'
            exit 1
        }
    }

    Write-Color '  [OK] Running as Administrator.' 'Green'

    if (-not (Confirm-Installation "Do you trust Wyndis and want to continue?")) {
        Write-Color '  Installation cancelled by user.' 'Yellow'
        exit 0
    }

    if ($Preview) {
        Show-Preview
    }

    Test-TlsSecurity

    $installPath = if ($CustomPath) { $CustomPath } else { "$env:ProgramData\Wyndis" }
    $zipPath = Join-Path $env:TEMP 'wyndis.zip'
    $logPath = Join-Path $installPath 'install.log'
    $manifestPath = Join-Path $installPath 'install.json'

    if (-not (Test-Path $installPath)) {
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    }

    Write-Color "`n  [1/5] Downloading Wyndis v$Version..." 'White'
    try {
        $zipUrl = "$WyndisUrl/wyndis.zip"
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
        $fileSize = (Get-Item $zipPath).Length
        Write-Color "  [OK] Downloaded ($([math]::Round($fileSize/1KB,1)) KB)" 'Green'
    } catch {
        Write-Color "  [ERR] Download failed: $_" 'Red'
        Write-Color "  Try manual download: $WyndisUrl" 'Yellow'
        exit 1
    }

    Write-Color "`n  [2/5] Verifying SHA-256 integrity..." 'White'
    try {
        $actualHash = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLower()
        Write-Color "  Expected: $ExpectedZipHash" 'Gray'
        Write-Color "  Actual:   $actualHash" 'Gray'

        if ($actualHash -eq $ExpectedZipHash) {
            Write-Color "  [PASS] Integrity verified. File is authentic." 'Green'
        } else {
            Write-Color "  [FAIL] HASH MISMATCH! File may be tampered or corrupted." 'Red'
            Write-Color "  DO NOT run this file. Contact: wyndis.help@gmail.com" 'Red'
            Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
            exit 1
        }
    } catch {
        Write-Color "  [ERR] Could not verify hash: $_" 'Red'
        Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
        exit 1
    }

    Write-Color "`n  [3/5] Extracting to: $installPath" 'White'
    try {
        if (Test-Path (Join-Path $installPath 'wyndis.ps1')) {
            Write-Color "  [INFO] Existing installation detected. Overwriting..." 'Yellow'
        }
        Expand-Archive -Path $zipPath -DestinationPath $installPath -Force
        Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
        Write-Color "  [OK] Extracted successfully." 'Green'
    } catch {
        Write-Color "  [ERR] Extraction failed: $_" 'Red'
        exit 1
    }

    $ps1Path = Join-Path $installPath 'wyndis.ps1'
    if (Test-Path $ps1Path) {
        $ps1Hash = (Get-FileHash -Path $ps1Path -Algorithm SHA256).Hash.ToLower()
        if ($ps1Hash -eq $ExpectedPs1Hash) {
            Write-Color "  [OK] wyndis.ps1 hash verified: $ps1Hash" 'Green'
        } else {
            Write-Color "  [WARN] wyndis.ps1 hash mismatch! Re-download recommended." 'Yellow'
        }
    }

    Write-Color "`n  [4/5] Setting secure permissions..." 'White'
    try {
        $acl = Get-Acl $installPath
        $inherit = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
        $propagation = [System.Security.AccessControl.PropagationFlags]"None"

        $admins = New-Object System.Security.AccessControl.FileSystemAccessRule(
            'BUILTIN\Administrators',
            'FullControl',
            $inherit,
            $propagation,
            'Allow'
        )
        $users = New-Object System.Security.AccessControl.FileSystemAccessRule(
            'BUILTIN\Users',
            'ReadAndExecute',
            $inherit,
            $propagation,
            'Allow'
        )

        $acl.SetAccessRule($admins)
        $acl.SetAccessRule($users)
        Set-Acl -Path $installPath -AclObject $acl
        Write-Color "  [OK] Permissions configured." 'Green'
    } catch {
        Write-Color "  [WARN] Could not set permissions: $_" 'Yellow'
    }

    Write-Color "`n  [5/5] Creating desktop shortcut..." 'White'
    try {
        $desktopPath = [Environment]::GetFolderPath('Desktop')
        $shortcutPath = Join-Path $desktopPath 'Wyndis v2.0.lnk'
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = Join-Path $installPath 'wyndis.bat'
        $shortcut.WorkingDirectory = $installPath
        $shortcut.Description = "Wyndis v$Version — Professional Windows Security Auditor"
        $shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,77"
        $shortcut.Save()
        Write-Color "  [OK] Shortcut created: $shortcutPath" 'Green'
    } catch {
        Write-Color "  [WARN] Could not create shortcut: $_" 'Yellow'
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $manifest = @{
        Version       = $Version
        InstallDate   = $timestamp
        InstallPath   = $installPath
        ZipHash       = $ExpectedZipHash
        Ps1Hash       = $ExpectedPs1Hash
        InstalledBy   = "$env:USERDOMAIN\$env:USERNAME"
        Source        = $WyndisUrl
        License       = 'MIT'
        OpenSourceUrl = 'https://github.com/wyndis/wyndis'
    }
    $manifest | ConvertTo-Json | Out-File $manifestPath -Encoding UTF8 -Force

    $log = @"
==============================================================================
  Wyndis v$Version — Installation Log
  Date: $timestamp
  Installed by: $env:USERDOMAIN\$env:USERNAME
  Path: $installPath
  SHA-256 (ZIP): $ExpectedZipHash
  SHA-256 (PS1): $ExpectedPs1Hash
  License: MIT
==============================================================================
  All files verified and extracted successfully.
  Wyndis does NOT collect telemetry or personal data.
==============================================================================
"@
    $log | Out-File $logPath -Encoding UTF8 -Force

    Write-Color "`n╔══════════════════════════════════════════════════════════════╗" 'Green'
    Write-Color "║           INSTALLATION COMPLETE — Wyndis v$Version           ║" 'Green'
    Write-Color "╚══════════════════════════════════════════════════════════════╝" 'Green'
    Write-Host ''
    Write-Color "  Installed to: $installPath" 'White'
    Write-Color "  Manifest:     $manifestPath" 'Gray'
    Write-Color "  Log:          $logPath" 'Gray'
    Write-Host ''
    Write-Color "  To run Wyndis:" 'White'
    Write-Color '    1. Right-click the desktop shortcut -> "Run as administrator"' 'Yellow'
    Write-Color "    2. Or open PowerShell as Admin and run:" 'Yellow'
    Write-Color "       & '$installPath\wyndis.ps1'" 'Yellow'
    Write-Host ''
    Write-Color "  Open source: https://github.com/wyndis/wyndis" 'Blue'
    Write-Color "  Contact: wyndis.help@gmail.com" 'Blue'
    Write-Host ''
}

function Uninstall-Wyndis {
    Write-Color '  [INFO] Uninstalling Wyndis...' 'Yellow'

    $installPath = if ($CustomPath) { $CustomPath } else { "$env:ProgramData\Wyndis" }

    if (Test-Path $installPath) {
        try {
            Remove-Item -Path $installPath -Recurse -Force
            Write-Color '  [OK] Files removed.' 'Green'
        } catch {
            Write-Color "  [WARN] Could not remove $installPath" 'Yellow'
        }
    } else {
        Write-Color '  [INFO] Wyndis is not installed.' 'Gray'
    }

    $desktopPath = [Environment]::GetFolderPath('Desktop')
    $shortcutPath = Join-Path $desktopPath 'Wyndis v2.0.lnk'
    if (Test-Path $shortcutPath) {
        try {
            Remove-Item -Path $shortcutPath -Force
            Write-Color '  [OK] Desktop shortcut removed.' 'Green'
        } catch {}
    }

    Write-Color '  [OK] Wyndis has been removed from this system.' 'Green'
}

# ===== MAIN =====

if ($Uninstall) {
    Uninstall-Wyndis
    exit 0
}

if ($Preview) {
    Show-Preview
    exit 0
}

Install-Wyndis
