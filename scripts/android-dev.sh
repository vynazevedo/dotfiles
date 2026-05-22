#!/usr/bin/env bash
# ─────────────────────────────────────────
# android-dev.sh
# Ambiente Android: JDK + SDK + emulador + Expo
# Author: Vinicius Azevedo <github.com/vynazevedo>
# ─────────────────────────────────────────

set -e

echo "android-dev — montando ambiente de desenvolvimento Android..."

# ─── Detecção de distro / arch / WSL ──────────────────────
if [ -f /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  DISTRO_ID="${ID}"
else
  echo "Erro: /etc/os-release não encontrado."
  exit 1
fi

ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
case "$ARCH" in
  arm64) IMG_ABI="arm64-v8a" ;;
  *)     IMG_ABI="x86_64" ;;
esac

IS_WSL=false
if grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=true
fi

echo "  Distro: ${PRETTY_NAME:-$DISTRO_ID} | Arch: ${ARCH}"
if [ "$IS_WSL" = true ]; then
  echo "  Ambiente: WSL2 detectado"
fi

# ─── Versões alvo ─────────────────────────────────────────
API_LEVEL="35"
BUILD_TOOLS="35.0.0"
SYSIMG="system-images;android-${API_LEVEL};google_apis;${IMG_ABI}"
ANDROID_HOME="$HOME/Android/Sdk"

# ─── Dependências ─────────────────────────────────────────
echo ""
echo "Instalando dependências base..."
sudo apt update -q
sudo apt install -y curl unzip git wget

# ─── JDK 17 ───────────────────────────────────────────────
echo ""
echo "Instalando OpenJDK 17..."
if command -v javac &>/dev/null && javac -version 2>&1 | grep -q "17\."; then
  echo "  JDK 17 já instalado, pulando..."
else
  sudo apt install -y openjdk-17-jdk
fi

JAVA_PATH="/usr/lib/jvm/java-17-openjdk-${ARCH}"
if [ ! -d "$JAVA_PATH" ]; then
  JAVA_PATH=$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")
fi

# ─── Android SDK — command line tools ────────────────────
echo ""
echo "Instalando Android SDK (command line tools)..."

mkdir -p "$ANDROID_HOME/cmdline-tools"

if [ -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
  echo "  cmdline-tools já instalado, pulando..."
else
  CLT_FILE=$(curl -fsSL https://developer.android.com/studio 2>/dev/null \
    | grep -oE 'commandlinetools-linux-[0-9]+_latest\.zip' | head -1)
  CLT_FILE="${CLT_FILE:-commandlinetools-linux-11076708_latest.zip}"

  echo "  Baixando ${CLT_FILE}..."
  TMP=$(mktemp -d)
  curl -fsSL "https://dl.google.com/android/repository/${CLT_FILE}" \
    -o "$TMP/cmdline-tools.zip"
  unzip -q "$TMP/cmdline-tools.zip" -d "$TMP"

  # O zip extrai para cmdline-tools/, mas o sdkmanager exige
  # cmdline-tools/latest/ — gotcha clássico.
  mv "$TMP/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  rm -rf "$TMP"
  echo "  cmdline-tools instalado em $ANDROID_HOME/cmdline-tools/latest"
fi

# ─── Variáveis de ambiente na sessão atual ───────────────
export ANDROID_HOME
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export JAVA_HOME="$JAVA_PATH"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
AVDMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager"

# ─── Aceitar licenças ────────────────────────────────────
echo ""
echo "Aceitando licenças do SDK..."
yes 2>/dev/null | "$SDKMANAGER" --licenses > /dev/null || true

# ─── Pacotes do SDK ──────────────────────────────────────
echo ""
echo "Instalando pacotes do SDK (pode demorar)..."
"$SDKMANAGER" \
  "platform-tools" \
  "platforms;android-${API_LEVEL}" \
  "build-tools;${BUILD_TOOLS}" \
  "emulator" \
  "$SYSIMG" > /dev/null

echo "  platform-tools, platforms;android-${API_LEVEL}, build-tools, emulator instalados"

# ─── KVM + AVD (apenas bare-metal) ───────────────────────
echo ""
if [ "$IS_WSL" = true ]; then
  echo "Emulador: pulado (WSL2)."
  echo "  O emulador Android não roda bem em WSL2 (virtualização aninhada"
  echo "  + GPU). Caminhos recomendados no WSL2:"
  echo "    - Expo Go num celular físico (mesma rede Wi-Fi)"
  echo "    - adb via USB com usbipd-win"
else
  echo "Configurando KVM (aceleração do emulador)..."
  sudo apt install -y qemu-kvm

  if ! groups "$USER" | grep -q kvm; then
    sudo usermod -aG kvm "$USER"
    echo "  Usuário adicionado ao grupo kvm (precisa relogar)"
  fi

  if [ -e /dev/kvm ]; then
    echo "  /dev/kvm disponível — aceleração OK"
  else
    echo "  AVISO: /dev/kvm não existe. Habilite a virtualização (VT-x/AMD-V)"
    echo "  na BIOS/UEFI para o emulador ter desempenho aceitável."
  fi

  # AVD
  echo ""
  echo "Criando AVD (Android Virtual Device)..."
  AVD_NAME="Pixel_API${API_LEVEL}"
  if "$AVDMANAGER" list avd 2>/dev/null | grep -q "$AVD_NAME"; then
    echo "  AVD '$AVD_NAME' já existe, pulando..."
  else
    echo "no" | "$AVDMANAGER" create avd \
      -n "$AVD_NAME" \
      -k "$SYSIMG" \
      -d "pixel_7" 2>/dev/null && \
      echo "  AVD '$AVD_NAME' criada" || \
      echo "  Aviso: falha ao criar AVD (crie manualmente com avdmanager)"
  fi
fi

# ─── Node.js (para Expo) ─────────────────────────────────
echo ""
echo "Verificando Node.js..."
if command -v node &>/dev/null; then
  echo "  Node já instalado: $(node --version)"
else
  echo "  Node não encontrado — instalando LTS via NodeSource..."
  echo "  (alternativas: scripts/node.sh ou scripts/mise.sh)"
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs
fi

# ─── EAS CLI (Expo Application Services) ─────────────────
echo ""
echo "Instalando EAS CLI..."
if command -v eas &>/dev/null; then
  echo "  eas-cli já instalado, pulando..."
else
  npm install -g eas-cli 2>/dev/null || sudo npm install -g eas-cli
fi

# ─── scrcpy (espelhar device físico) ─────────────────────
echo ""
echo "Instalando scrcpy..."
if command -v scrcpy &>/dev/null; then
  echo "  scrcpy já instalado, pulando..."
else
  sudo apt install -y scrcpy 2>/dev/null || \
    echo "  Aviso: scrcpy não disponível nos repos"
fi

# ─── inotify watches (Metro bundler) ─────────────────────
echo ""
echo "Ajustando fs.inotify.max_user_watches (Metro bundler)..."
INOTIFY_CONF="/etc/sysctl.d/99-android-dev.conf"
if [ ! -f "$INOTIFY_CONF" ]; then
  echo "fs.inotify.max_user_watches = 524288" | \
    sudo tee "$INOTIFY_CONF" > /dev/null
  sudo sysctl -p "$INOTIFY_CONF" > /dev/null 2>&1 || true
  echo "  inotify watches aumentado para 524288"
else
  echo "  já configurado, pulando..."
fi

# ─── Variáveis de ambiente nos shells ────────────────────
echo ""
echo "Configurando variáveis de ambiente..."

ANDROID_ENV_BLOCK="
# Android SDK
export JAVA_HOME=\"${JAVA_PATH}\"
export ANDROID_HOME=\"\$HOME/Android/Sdk\"
export ANDROID_SDK_ROOT=\"\$ANDROID_HOME\"
export PATH=\"\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/emulator:\$PATH\""

for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "ANDROID_HOME" "$RC"; then
    echo "$ANDROID_ENV_BLOCK" >> "$RC"
    echo "  variáveis adicionadas em $(basename "$RC")"
  fi
done

# ─── Aliases ──────────────────────────────────────────────
ALIAS_FILE="$HOME/.android_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# Android dev aliases — gerado por dotfiles
# ─────────────────────────────────────────

# adb
alias adevices='adb devices -l'
alias alogcat='adb logcat'
alias ainstall='adb install -r'
alias areverse='adb reverse tcp:8081 tcp:8081'
alias akill='adb kill-server && adb start-server'

# Emulador
alias emu-list='emulator -list-avds'
emu() {
  local avd="${1:-$(emulator -list-avds 2>/dev/null | head -1)}"
  if [ -z "$avd" ]; then
    echo "Nenhuma AVD encontrada. Crie com: avdmanager create avd ..."
    return 1
  fi
  echo "Iniciando AVD: $avd"
  nohup emulator "@$avd" > /dev/null 2>&1 &
}

# scrcpy (espelhar device físico)
alias mirror='scrcpy'
alias mirror-wifi='scrcpy --tcpip'

# Expo / React Native
alias expo-start='npx expo start'
alias expo-android='npx expo run:android'
alias expo-doctor='npx expo-doctor'
alias easb='eas build'
alias eass='eas submit'

expo-new() {
  if [ -z "$1" ]; then
    echo "Uso: expo-new <nome-do-projeto>"
    return 1
  fi
  npx create-expo-app@latest "$1"
}

# Gradle wrapper
alias gw='./gradlew'
alias gwclean='./gradlew clean'
alias gwbuild='./gradlew assembleDebug'

# SDK
alias sdk='sdkmanager'
alias sdk-list='sdkmanager --list_installed'
alias sdk-update='sdkmanager --update'
ALIASES

for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "android_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# Android dev aliases" >> "$RC"
    echo "[ -f ~/.android_aliases ] && source ~/.android_aliases" >> "$RC"
  fi
done

# ─── Summary ──────────────────────────────────────────────
echo ""
echo "Ambiente Android montado com sucesso!"
echo ""
echo "O que foi instalado:"
echo "  - OpenJDK 17"
echo "  - Android SDK (API ${API_LEVEL}, build-tools ${BUILD_TOOLS})"
echo "  - platform-tools (adb, fastboot), emulator"
[ "$IS_WSL" = false ] && echo "  - KVM + AVD Pixel_API${API_LEVEL}"
echo "  - Node.js + EAS CLI"
echo "  - scrcpy (espelhar device físico)"
echo ""
echo "Aliases:"
echo "  emu [avd]          Inicia o emulador"
echo "  emu-list           Lista AVDs"
echo "  adevices           Lista devices conectados"
echo "  mirror             Espelha device físico (scrcpy)"
echo "  expo-new <nome>    Novo projeto Expo"
echo "  expo-start         npx expo start"
echo "  expo-android       roda no Android"
echo "  easb / eass        eas build / submit"
echo ""
echo "Próximos passos:"
echo "  1. Reabra o terminal (ou: source ~/.zshrc) para carregar as vars"
if [ "$IS_WSL" = false ]; then
  echo "  2. Faça logout/login para o grupo kvm valer"
  echo "  3. Teste o emulador: emu"
else
  echo "  2. No WSL2: use Expo Go num celular físico (mesma rede)"
fi
echo ""
echo "Criar projeto Expo:  expo-new meu-app"
