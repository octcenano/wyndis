$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$url = 'https://wyndis-download-ce9eb.web.app/wyndis.zip'
$checksum = '9bde7b0bf5b512e312fd786928d8a8aa67098615193a6cbcfdc531ce8f79488a'

$packageArgs = @{
  PackageName   = 'wyndis'
  UnzipLocation = "$env:ProgramData\Wyndis"
  Url           = $url
  Checksum      = $checksum
  ChecksumType  = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

# Create shortcut
$targetPath = "$env:ProgramData\Wyndis\wyndis.bat"
$shortcutFile = "$env:Public\Desktop\Wyndis.lnk"
Install-ChocolateyShortcut -ShortcutFilePath $shortcutFile -TargetPath $targetPath -Description "Wyndis Security Auditor"

Write-Host "Wyndis installed to $env:ProgramData\Wyndis" -ForegroundColor Green
Write-Host "Run: wyndis.bat (as Administrator)" -ForegroundColor Cyan
