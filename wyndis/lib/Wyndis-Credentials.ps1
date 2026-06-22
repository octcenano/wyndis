# SPDX-License-Identifier: MIT
# Wyndis - Credential security audit

function Invoke-WyndisCredentialsAudit {
    Write-WyndisInfo '--- Auditoria de Credenciales ---'

    try {
        $cmdStore = Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Credentials' -Name 'PasswordHash' -ErrorAction SilentlyContinue
        if ($cmdStore) {
            Write-WyndisWarning 'Credential Manager detectado con datos almacenados.' 'CRED-001'
        }
        $vault = Get-ItemProperty 'HKCU:\Software\Microsoft\Vault\Default' -Name 'VaultFolder' -ErrorAction SilentlyContinue
        if ($vault) {
            Write-WyndisInfo 'Windows Vault detectado - credenciales almacenadas.'
            Write-WyndisSuggest 'Revisa credenciales guardadas: Control Panel -> Credential Manager.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar Credential Manager.'
    }

    try {
        $creds = vaultcmd /list 2>$null
        if ($creds -and $creds -notmatch 'No hay|No vaults') {
            Write-WyndisWarning 'Windows Vault contiene credenciales guardadas.' 'CRED-002'
            Write-WyndisSuggest 'Usa vaultcmd /list para revisar y vaultcmd /delete para eliminar.'
        } else {
            Write-WyndisOk 'Windows Vault vacio o sin credenciales.'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar Windows Vault.'
    }

    try {
        $wslPasswd = Get-ChildItem "$env:USERPROFILE\AppData\Local\Packages\*Canonical*" -ErrorAction SilentlyContinue
        if ($wslPasswd) {
            Write-WyndisInfo 'WSL detectado - revisa contrasenas en distribuciones Linux.'
        }
    } catch {}

    try {
        $hello = Get-WmiObject -Namespace root/cimv2/security/microsofttpm -Class Win32_Tpm -ErrorAction SilentlyContinue
        $ngcKey = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Ngc' -ErrorAction SilentlyContinue
        if ($ngcKey) {
            Write-WyndisInfo 'Windows Hello configurado (autenticacion biometrica/PIN).'
        }
    } catch {
        Write-WyndisInfo 'No se pudo verificar Windows Hello.'
    }

    try {
        $rdpCreds = Get-ItemProperty 'HKCU:\Software\Microsoft\Terminal Server Client\Servers' -ErrorAction SilentlyContinue
        if ($rdpCreds) {
            $rdpServers = $rdpCreds.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' }
            if ($rdpServers) {
                Write-WyndisInfo "Credenciales RDP guardadas para $($rdpServers.Count) servidor(es)."
                Write-WyndisSuggest 'Elimina credenciales RDP guardadas si no son necesarias.'
            }
        }
    } catch {
        Write-WyndisInfo 'No se pudieron verificar credenciales RDP.'
    }
}
