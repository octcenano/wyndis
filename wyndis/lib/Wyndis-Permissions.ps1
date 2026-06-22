# SPDX-License-Identifier: MIT
# Wyndis - Permissions and accounts audit

function Invoke-WyndisPermissionsAudit {
    # Cuentas locales
    try {
        $users = Get-LocalUser -ErrorAction Stop | Where-Object { $_.Enabled -eq $true }
        Write-WyndisInfo "Cuentas locales activas: $($users.Count)"

        foreach ($user in $users) {
            if ($user.Name -eq 'Administrator' -or $user.Name -eq 'Administrador') {
                if (-not $user.Enabled) {
                    Write-WyndisOk 'Cuenta Administrator deshabilitada.'
                } else {
                    Write-WyndisWarning 'Cuenta Administrator está habilitada.' 'PERM-001'
                    Write-WyndisSuggest 'Deshabilita la cuenta Administrator si no la usas.'
                }
            }

            if ($user.PasswordExpires -eq $false -and $user.Name -notmatch '^(DefaultAccount|WDAGUtilityAccount|Guest|Invitado)$') {
                Write-WyndisWarning "Usuario '$($user.Name)': la contraseña nunca expira." 'PERM-002'
            }

            if ($user.PasswordRequired -eq $false) {
                Write-WyndisCritical "Usuario '$($user.Name)': no requiere contraseña." 'PERM-003'
            }
        }

        $guest = Get-LocalUser -Name 'Guest' -ErrorAction SilentlyContinue
        if (-not $guest) { $guest = Get-LocalUser -Name 'Invitado' -ErrorAction SilentlyContinue }
        if ($guest -and $guest.Enabled) {
            Write-WyndisCritical 'Cuenta Invitado/Guest está habilitada.' 'PERM-004'
            Write-WyndisSuggest 'Deshabilita la cuenta Invitado: Disable-LocalUser -Name Guest'
        } else {
            Write-WyndisOk 'Cuenta Invitado deshabilitada.'
        }
    } catch {
        Write-WyndisWarning 'No se pudieron revisar cuentas locales.' 'PERM-005'
    }

    # Miembros del grupo Administradores
    try {
        $admins = Get-LocalGroupMember -Group 'Administradores' -ErrorAction SilentlyContinue
        if (-not $admins) {
            $admins = Get-LocalGroupMember -Group 'Administrators' -ErrorAction Stop
        }

        Write-WyndisInfo "Miembros del grupo Administradores: $($admins.Count)"
        foreach ($admin in $admins) {
            Write-WyndisInfo "  - $($admin.Name)"
        }

        if ($admins.Count -gt 3) {
            Write-WyndisWarning 'Hay más de 3 administradores locales.' 'PERM-006'
            Write-WyndisSuggest 'Reduce el número de cuentas con privilegios de administrador.'
        } else {
            Write-WyndisOk 'Número razonable de administradores.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo listar el grupo Administradores.'
    }

    # UAC
    try {
        $uac = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -ErrorAction Stop
        if ($uac.EnableLUA -eq 1) {
            Write-WyndisOk 'UAC (Control de cuentas de usuario) está activo.'
        } else {
            Write-WyndisCritical 'UAC está desactivado.' 'PERM-007'
            Write-WyndisSuggest 'Activa UAC en Configuración -> Cuentas -> Opciones de inicio de sesión.'
        }

        if ($uac.ConsentPromptBehaviorAdmin -eq 0) {
            Write-WyndisWarning 'UAC no pide confirmación a administradores.' 'PERM-008'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar configuración UAC.'
    }

    # Contraseñas en texto plano / autologin
    try {
        $autoLogon = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -ErrorAction Stop
        if ($autoLogon.AutoAdminLogon -eq 1) {
            Write-WyndisCritical 'Inicio de sesión automático activado (AutoAdminLogon).' 'PERM-009'
            Write-WyndisSuggest 'Desactiva el inicio automático en el registro Winlogon.'
        } else {
            Write-WyndisOk 'Inicio de sesión automático desactivado.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar AutoAdminLogon.'
    }

    # Permisos compartidos SMB
    try {
        $shares = Get-SmbShare -ErrorAction Stop | Where-Object { $_.Name -notmatch '^\$' -and $_.Name -ne 'IPC$' }
        foreach ($share in $shares) {
            Write-WyndisInfo "Recurso compartido: $($share.Name) -> $($share.Path)"
            $everyone = Get-SmbShareAccess -Name $share.Name -ErrorAction SilentlyContinue |
                Where-Object { $_.AccountName -match 'Everyone|Todos' }
            if ($everyone) {
                Write-WyndisCritical "Recurso '$($share.Name)' accesible por Everyone." "PERM-SMB-$($share.Name)"
            }
        }
        if (-not $shares) {
            Write-WyndisOk 'No hay recursos compartidos públicos detectados.'
        }
    } catch {
        Write-WyndisInfo 'Revisión de recursos compartidos limitada.'
    }
}
