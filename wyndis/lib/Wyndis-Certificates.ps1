# SPDX-License-Identifier: MIT
# Wyndis - Certificate store audit

function Invoke-WyndisCertificateAudit {
    Write-WyndisInfo '--- Auditoria de Certificados ---'

    try {
        $stores = @(
            'Cert:\LocalMachine\Root',
            'Cert:\LocalMachine\TrustedPublisher',
            'Cert:\LocalMachine\CA',
            'Cert:\CurrentUser\Root'
        )

        foreach ($store in $stores) {
            try {
                $certs = Get-ChildItem $store -ErrorAction Stop
                if ($certs) {
                    $valid = 0
                    $expired = 0
                    foreach ($cert in $certs) {
                        if ($cert.NotAfter -and $cert.NotAfter -lt (Get-Date)) {
                            $expired++
                        } else {
                            $valid++
                        }
                    }
                    Write-WyndisInfo "Certificados en $store : $valid validos, $expired expirados"
                    if ($expired -gt 5) {
                        Write-WyndisWarning "Muchos certificados expirados en $store ." 'CERT-001'
                    }
                }
            } catch {
                Write-WyndisInfo "No se pudo acceder a $store ."
            }
        }
    } catch {
        Write-WyndisInfo 'No se pudo realizar auditoria de certificados.'
    }

    try {
        $selfSigned = Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue | Where-Object { $_.Issuer -eq $_.Subject }
        if ($selfSigned) {
            Write-WyndisWarning "Certificados auto-firmados en almacen local: $($selfSigned.Count)." 'CERT-002'
            foreach ($s in $selfSigned | Select-Object -First 3) {
                Write-WyndisInfo "  - $($s.Subject) (valido hasta $($s.NotAfter))"
            }
        }
    } catch {
        Write-WyndisInfo 'No se pudieron revisar certificados auto-firmados.'
    }
}
