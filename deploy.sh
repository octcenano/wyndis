#!/bin/bash
set -e

NODE_DIR="$HOME/.local/node-wyndis"
mkdir -p "$NODE_DIR"

echo "=================================================="
echo "  Wyndis - Deploy Completo"
echo "=================================================="
echo ""

# 1. Verificar/Crear repositorio GitHub
if ! command -v gh &> /dev/null; then
    echo "[!] GitHub CLI (gh) no instalado. Saltando paso de GitHub."
    echo "    Crea el repo manualmente en https://github.com/new"
    echo "    Nombre: wyndis"
    echo "    Luego ejecuta:"
    echo "      git remote add origin https://github.com/octcenano/wyndis.git"
    echo "      git push -u origin main"
    echo ""
else
    if ! gh repo view octcenano/wyndis &> /dev/null; then
        echo "[*] Creando repositorio GitHub: octcenano/wyndis..."
        gh repo create octcenano/wyndis --public --source=. --remote=origin --push
        gh secret set FIREBASE_TOKEN < firebase.token 2>/dev/null || echo "[!] No hay firebase.token para GitHub Actions"
        echo "[+] Repositorio creado."
    else
        echo "[+] Repositorio GitHub ya existe."
    fi
fi

# 2. Descargar Node.js portable si no existe
if [ ! -f "$NODE_DIR/bin/node" ]; then
    echo "[*] Descargando Node.js..."
    NODE_VERSION="v20.11.0"
    NODE_TAR="node-$NODE_VERSION-linux-x64.tar.xz"
    curl -sS -o "$NODE_DIR/$NODE_TAR" "https://nodejs.org/dist/$NODE_VERSION/$NODE_TAR"
    tar -xf "$NODE_DIR/$NODE_TAR" -C "$NODE_DIR" --strip-components=1
    rm "$NODE_DIR/$NODE_TAR"
    echo "[+] Node.js instalado."
else
    echo "[+] Node.js ya disponible."
fi

export PATH="$NODE_DIR/bin:$PATH"

# 3. Instalar firebase-tools si no está
if ! command -v firebase &> /dev/null; then
    echo "[*] Instalando firebase-tools..."
    npm install -g firebase-tools --prefix "$NODE_DIR"
    export PATH="$NODE_DIR/lib/node_modules/firebase-tools/bin:$PATH"
fi

echo "[+] Firebase CLI listo."
echo ""

# 4. Login (primera vez o si expiró)
echo "=================================================="
echo "  INICIO DE SESIÓN EN FIREBASE"
echo "=================================================="
firebase login --no-localhost || true

echo ""
echo "=================================================="
echo "  DESPLEGANDO A FIREBASE HOSTING"
echo "=================================================="
echo ""

# 5. Deploy
firebase deploy --only hosting

echo ""
echo "=================================================="
echo "  COMPLETADO"
echo "=================================================="
echo ""
echo "  Web:     https://wyndis-download-ce9eb.web.app"
echo "  GitHub:  https://github.com/octcenano/wyndis"
echo "  Discord: https://discord.gg/wyndis"
echo ""
echo "  Próximos pasos:"
echo "  1. Crear canal de Discord y reemplazar enlace"
echo "  2. Subir screenshot del PDF a Público/img/" 
echo "  3. Crear GitHub Release con wyndis.zip adjunto"
echo "  4. Enviar a Chocolatey: choco push choco/wyndis.nuspec"
echo "  5. Enviar a Winget: wingetcreate submit winget/manifests"
echo ""
