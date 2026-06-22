@echo off
title Wyndis v2.0 — Professional Windows Security Auditor
setlocal enabledelayedexpansion

chcp 65001 >nul 2>&1

echo.
echo  ╔══════════════════════════════════════════════════════╗
echo  ║          Wyndis v2.0 — Security Auditor             ║
echo  ║   MIT License | Open Source | 300+ Security Checks  ║
echo  ║   https://wyndis-download-ce9eb.web.app             ║
echo  ╚══════════════════════════════════════════════════════╝
echo.
echo  Wyndis analyzes Windows security across 27 modules
echo  and generates a professional PDF report with charts.
echo.
echo  This script is open source. You can audit every line:
echo  https://github.com/wyndis/wyndis
echo.
echo  Wyndis does NOT collect telemetry or personal data.
echo  All analysis is performed locally on your machine.
echo.

:: Auto-elevate to Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo  [INFO] Administrator privileges required.
    echo  [INFO] If you see a UAC prompt, click "Yes".
    echo.
    timeout /t 2 /nobreak >nul
    powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy RemoteSigned -File ""%~dp0wyndis.ps1""' -Verb RunAs"
    exit /b
)

echo  [OK] Running as Administrator.
echo.

:: Verify script integrity
echo  [INFO] Verifying script integrity...
powershell -Command ^
    "$hash = (Get-FileHash -Algorithm SHA256 '%~dp0wyndis.ps1').Hash.ToLower();" ^
    "$expected = '51bf60eb06724bdfc9ce7b4015a8fe93ec71fdbe56ba5909e634245f815b8ca4';" ^
    "if ($hash -ne $expected) { Write-Host '  [FAIL] Integrity check failed! Hash: '$hash -ForegroundColor Red; exit 1 }" ^
    "Write-Host '  [PASS] Integrity verified.' -ForegroundColor Green; exit 0"

if %errorLevel% neq 0 (
    echo.
    echo  ⚠ WARNING: The script hash does not match the expected value.
    echo  The file may have been tampered with or corrupted.
    echo  Do NOT run this file. Download a fresh copy from:
    echo  https://wyndis-download-ce9eb.web.app
    echo.
    pause
    exit /b
)

echo.
echo  Starting Wyndis security audit...
echo  ============================================
echo.

powershell -ExecutionPolicy RemoteSigned -File "%~dp0wyndis.ps1" %*

echo.
echo  ============================================
echo  Wyndis audit completed.
echo  Report PDF saved to your Desktop.
echo.
pause
