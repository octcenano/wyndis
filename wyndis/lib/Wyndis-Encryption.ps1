# SPDX-License-Identifier: MIT
# Wyndis - Encryption and BitLocker audit

function Invoke-WyndisEncryptionAudit {
    Write-WyndisInfo '--- Auditoria de Cifrado ---'

    try {
        $tpm = Get-CimInstance -Namespace root/cimv2/Security/MicrosoftTpm -ClassName Win32_Tpm -ErrorAction Stop
        if ($tpm -and $tpm.IsEnabled_InitialValue -eq $true) {
            Write-WyndisOk 'TPM detectado y habilitado.'
            $tpmVersion = $tpm.SpecVersion
            Write-WyndisInfo "Version TPM: $tpmVersion"
            if ($tpmVersion -match '1\.2') {
                Write-WyndisWarning 'TPM version 1.2 - considera actualizar a TPM 2.0.' 'ENC-001'
            }
        } else {
            Write-WyndisWarning 'TPM no detectado o deshabilitado.' 'ENC-002'
            Write-WyndisSuggest 'Activa TPM en la BIOS/UEFI para BitLocker y seguridad.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo consultar TPM.'
    }

    try {
        $secureBoot = Confirm-SecureBootUEFI -ErrorAction Stop
        if ($secureBoot) {
            Write-WyndisOk 'Secure Boot activo.'
        } else {
            Write-WyndisCritical 'Secure Boot desactivado.' 'ENC-003'
            Write-WyndisSuggest 'Activa Secure Boot en la BIOS/UEFI.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar Secure Boot (sistema no UEFI o sin permisos).'
    }

    try {
        $blv = Get-BitLockerVolume -ErrorAction Stop
        $protectedCount = 0
        $unprotectedCount = 0
        foreach ($vol in $blv) {
            $mount = $vol.MountPoint
            if ($vol.ProtectionStatus -eq 1) {
                Write-WyndisOk "BitLocker activo en $mount ($($vol.EncryptionPercentage)%)"
                $protectedCount++
            } else {
                Write-WyndisWarning "BitLocker NO activo en $mount." 'ENC-004'
                Write-WyndisSuggest "Activa BitLocker: Enable-BitLocker -MountPoint '$mount' -SkipHardwareTest"
                $unprotectedCount++
            }
        }
        if ($unprotectedCount -eq 0 -and $protectedCount -gt 0) {
            Write-WyndisOk 'Todos los volumenes estan cifrados con BitLocker.'
        } elseif ($protectedCount -eq 0) {
            Write-WyndisCritical 'No hay volumenes cifrados con BitLocker.' 'ENC-005'
            Write-WyndisSuggest 'Cifra el disco del sistema con BitLocker para proteger datos.'
        }
    } catch {
        Write-WyndisWarning 'No se pudo verificar BitLocker (caracteristica no disponible).' 'ENC-006'
        Write-WyndisSuggest 'BitLocker requiere Windows Pro/Enterprise. Considera VeraCrypt como alternativa.'
    }

    try {
        $deviceGuard = Get-CimInstance -Namespace root/Microsoft/Windows/DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction Stop
        if ($deviceGuard) {
            $ready = $deviceGuard.DeviceGuardSmartStatus -eq 1 -or $deviceGuard.VirtualizationBasedSecurityStatus -eq 2
            if ($ready) {
                Write-WyndisOk 'Device Guard / Credential Guard habilitado.'
            } else {
                Write-WyndisWarning 'Device Guard no disponible en este hardware.' 'ENC-007'
                Write-WyndisSuggest 'Device Guard requiere virtualizacion habilitada en BIOS.'
            }
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar Device Guard.'
    }

    try {
        $appGuard = Get-WindowsPackage -Online -PackageName '*Windows-Defender-ApplicationGuard*' -ErrorAction SilentlyContinue
        if ($appGuard) {
            Write-WyndisInfo 'Windows Defender Application Guard instalado.'
        } else {
            Write-WyndisSuggest 'Considera instalar Windows Defender Application Guard (Windows 10/11 Pro/Enterprise).'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar Application Guard.'
    }
}
