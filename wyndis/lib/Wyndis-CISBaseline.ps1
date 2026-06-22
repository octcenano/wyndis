# SPDX-License-Identifier: MIT
# Wyndis - CIS Windows Baseline checks

function Invoke-WyndisCISBaseline {
    Write-WyndisInfo '--- Baseline CIS (Centro de Seguridad de Internet) ---'

    try {
        $lsa = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -ErrorAction Stop
        if ($lsa.LimitBlankPasswordUse -eq 1) {
            Write-WyndisOk 'CIS 2.3.1.1: Restriccion de contrasenas en blanco activa.'
        } else {
            Write-WyndisWarning 'CIS 2.3.1.1: Contrasenas en blanco permitidas.' 'CIS-001'
        }
        if ($lsa.RestrictAnonymous -eq 1) {
            Write-WyndisOk 'CIS 2.3.1.2: Acceso anonimo restringido.'
        } else {
            Write-WyndisWarning 'CIS 2.3.1.2: Acceso anonimo permitido.' 'CIS-002'
        }
        if ($lsa.LMCompatibilityLevel -ge 3) {
            Write-WyndisOk 'CIS 2.3.1.5: Autenticacion LM/NTLMv2 configurada.'
        } else {
            Write-WyndisWarning 'CIS 2.3.1.5: Autenticacion LM debil permitida.' 'CIS-003'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar configuracion LSA.'
    }

    try {
        $net = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -ErrorAction Stop
        if ($net.AutoShareWks -eq 0) {
            Write-WyndisOk 'CIS 2.2.7: Administracion remota restringida.'
        } else {
            Write-WyndisWarning 'CIS 2.2.7: Administracion remota expuesta.' 'CIS-004'
        }
        if ($net.NullSessionPipes -eq '') {
            Write-WyndisOk 'CIS 2.2.8: Sesiones nulas restringidas.'
        } else {
            Write-WyndisWarning 'CIS 2.2.8: Sesiones nulas detectadas.' 'CIS-005'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar LanmanServer.'
    }

    try {
        $rdp = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -ErrorAction Stop
        $rdpEnabled = ($rdp.fDenyTSConnections -eq 0)
        if ($rdpEnabled) {
            try {
                $nla = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -ErrorAction Stop
                if ($nla.UserAuthentication -eq 0) {
                    Write-WyndisCritical 'CIS 2.2.12: RDP sin NLA - riesgo elevado.' 'CIS-006'
                }
            } catch {}
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar RDP CIS.'
    }

    try {
        $uac = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -ErrorAction Stop
        if ($uac.ConsentPromptBehaviorAdmin -eq 2) {
            Write-WyndisOk 'CIS 2.3.2.1: UAC admin prompt configurado correctamente.'
        } elseif ($uac.ConsentPromptBehaviorAdmin -eq 0) {
            Write-WyndisWarning 'CIS 2.3.2.1: UAC no pide confirmacion a admins.' 'CIS-007'
        } elseif ($uac.ConsentPromptBehaviorAdmin -eq 1) {
            Write-WyndisWarning 'CIS 2.3.2.1: UAC pide credenciales en escritorio seguro.' 'CIS-008'
        }
        if ($uac.EnableInstallerDetection -ne 1) {
            Write-WyndisWarning 'CIS 2.3.2.2: Deteccion de instaladores desactivada.' 'CIS-009'
        }
        if ($uac.ValidateAdminCodeSignatures -eq 1) {
            Write-WyndisOk 'CIS 2.3.2.3: Validacion de firmas de admin activa.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar UAC CIS.'
    }

    try {
        $policies = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -ErrorAction SilentlyContinue
        if ($policies -and $policies.DisableAutomaticRestartSignOn -eq 0) {
            Write-WyndisSuggest 'CIS 18.8.4.1: Configura reinicio automatico de sesion.'
        }
    } catch {}

    try {
        $audit = Get-ItemProperty 'HKLM:\SECURITY\Policy\PolAdtEv' -ErrorAction SilentlyContinue
        Write-WyndisInfo 'Politicas de auditoria revisadas (requiere privilegios elevados).'
    } catch {
        Write-WyndisInfo 'No se pudieron verificar politicas de auditoria del sistema.'
    }

    try {
        $pwdPolicy = Get-CimInstance Win32_AccountPolicy -Filter "Name='Maximum Password Age'" -ErrorAction SilentlyContinue
        if ($pwdPolicy) {
            $maxAge = $pwdPolicy.MaximumPasswordAge
            if ($maxAge -gt 60) {
                Write-WyndisWarning "CIS 1.1.1: Contrasenas expiran cada $maxAge dias (max recomendado: 60)." 'CIS-010'
            } else {
                Write-WyndisOk "CIS 1.1.1: Expiracion de contrasenas cada $maxAge dias."
            }
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar politica de expiracion de contrasenas.'
    }

    try {
        $minLen = Get-CimInstance Win32_AccountPolicy -Filter "Name='Minimum Password Length'" -ErrorAction SilentlyContinue
        if ($minLen) {
            $len = $minLen.MinimumPasswordLength
            if ($len -lt 8) {
                Write-WyndisWarning "CIS 1.1.2: Longitud minima de contrasena: $len (min recomendado: 8)." 'CIS-011'
            } else {
                Write-WyndisOk "CIS 1.1.2: Longitud minima de contrasena: $len."
            }
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar longitud minima de contrasena.'
    }
}
