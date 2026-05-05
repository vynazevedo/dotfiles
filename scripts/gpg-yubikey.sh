#!/usr/bin/env bash
# ─────────────────────────────────────────
# gpg-yubikey.sh
# GPG + YubiKey + signed commits + SSH com GPG
# Author: Vinicius Azevedo <github.com/vynazevedo>
# ─────────────────────────────────────────

set -e

echo "gpg-yubikey — configurando GPG com suporte a YubiKey..."

# ─── Dependências ─────────────────────────────────────────
echo "  Instalando dependências..."
sudo apt update -q
sudo apt install -y \
  gnupg \
  scdaemon \
  pcscd \
  pcsc-tools \
  yubikey-manager \
  libpam-u2f \
  yubikey-personalization 2>/dev/null || \
  echo "  Aviso: alguns pacotes podem não estar disponíveis nos repos"

# ─── Iniciar daemon de smart card ────────────────────────
sudo systemctl enable pcscd
sudo systemctl start pcscd

# ─── GPG agent config ────────────────────────────────────
GNUPGHOME="${GNUPGHOME:-$HOME/.gnupg}"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

GPG_AGENT_CONF="$GNUPGHOME/gpg-agent.conf"
GPG_CONF="$GNUPGHOME/gpg.conf"
SCDAEMON_CONF="$GNUPGHOME/scdaemon.conf"

# Backup
for f in "$GPG_AGENT_CONF" "$GPG_CONF" "$SCDAEMON_CONF"; do
  if [ -f "$f" ]; then
    cp "$f" "$f.backup.$(date +%Y%m%d%H%M%S)"
    echo "  Backup de $(basename "$f") salvo"
  fi
done

# ─── gpg-agent.conf ──────────────────────────────────────
cat > "$GPG_AGENT_CONF" << 'CONF'
# gpg-agent.conf — gerado por dotfiles

# SSH support via GPG agent
enable-ssh-support

# Cache TTL (10 min default, max 2h)
default-cache-ttl 600
max-cache-ttl 7200
default-cache-ttl-ssh 600
max-cache-ttl-ssh 7200

# Pinentry (preferência: curses para terminal)
pinentry-program /usr/bin/pinentry-curses
CONF

# Detectar pinentry disponível
for pinentry in pinentry-gtk-2 pinentry-qt pinentry-curses pinentry; do
  if command -v "$pinentry" &>/dev/null; then
    sed -i "s|/usr/bin/pinentry-curses|$(command -v "$pinentry")|" "$GPG_AGENT_CONF"
    echo "  pinentry detectado: $pinentry"
    break
  fi
done

# ─── gpg.conf ────────────────────────────────────────────
cat > "$GPG_CONF" << 'CONF'
# gpg.conf — gerado por dotfiles

# Defaults seguros
personal-cipher-preferences AES256 AES192 AES
personal-digest-preferences SHA512 SHA384 SHA256
personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed

default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed

cert-digest-algo SHA512
s2k-digest-algo SHA512
s2k-cipher-algo AES256

charset utf-8
fixed-list-mode
no-comments
no-emit-version
keyid-format 0xlong
list-options show-uid-validity
verify-options show-uid-validity
with-fingerprint
require-cross-certification
no-symkey-cache
use-agent
throw-keyids
CONF

# ─── scdaemon.conf ───────────────────────────────────────
cat > "$SCDAEMON_CONF" << 'CONF'
# scdaemon.conf — gerado por dotfiles

# Forçar uso do PC/SC
# disable-ccid

# Logs (descomente para debug)
# log-file /var/log/scdaemon.log
# debug-level guru
CONF

chmod 600 "$GPG_AGENT_CONF" "$GPG_CONF" "$SCDAEMON_CONF"

# ─── Restart agent ───────────────────────────────────────
echo ""
echo "  Recarregando gpg-agent..."
gpgconf --kill gpg-agent 2>/dev/null || true
gpg-connect-agent reloadagent /bye 2>/dev/null || true

# ─── Shell integration: SSH via GPG ──────────────────────
GPG_BLOCK='
# GPG + YubiKey
export GPG_TTY=$(tty)
unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi
gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1'

for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "gnupg_SSH_AUTH_SOCK_by" "$RC"; then
    echo "$GPG_BLOCK" >> "$RC"
    echo "  GPG-SSH config adicionada em $(basename "$RC")"
  fi
done

# ─── Aliases ──────────────────────────────────────────────
ALIAS_FILE="$HOME/.gpg_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# GPG aliases — gerado por dotfiles
# ─────────────────────────────────────────

# Listas
alias gpg-keys='gpg --list-keys --keyid-format 0xlong'
alias gpg-secret='gpg --list-secret-keys --keyid-format 0xlong'
alias gpg-fingerprint='gpg --fingerprint'

# YubiKey
alias yk-status='gpg --card-status'
alias yk-edit='gpg --card-edit'
alias yk-info='ykman info'
alias yk-list='ykman list'

# Agent
alias gpg-reload='gpgconf --kill gpg-agent && gpg-connect-agent reloadagent /bye'
alias gpg-stop='gpgconf --kill gpg-agent'

# Export public key (para GitHub/GitLab)
gpg-pub() {
  local KEYID="${1:-}"
  if [ -z "$KEYID" ]; then
    echo "Uso: gpg-pub <keyid>"
    gpg --list-secret-keys --keyid-format 0xlong
    return 1
  fi
  gpg --armor --export "$KEYID"
}

# SSH public key derivada da GPG (auth subkey)
gpg-ssh-pub() {
  ssh-add -L 2>/dev/null | grep "cardno:" || \
    echo "Conecte o YubiKey e tente novamente"
}

# Configurar git para signing com este key
gpg-git-setup() {
  local KEYID="${1:-}"
  if [ -z "$KEYID" ]; then
    echo "Uso: gpg-git-setup <keyid>"
    return 1
  fi
  git config --global user.signingkey "$KEYID"
  git config --global commit.gpgsign true
  git config --global tag.gpgsign true
  echo "Git configurado para signing com $KEYID"
}

# Sign + verify rápido
gpg-sign() {
  gpg --clearsign "$1"
}

gpg-verify() {
  gpg --verify "$1"
}

# Encrypt/decrypt rápido
gpg-encrypt() {
  local RECIPIENT="$1"
  local FILE="$2"
  if [ -z "$RECIPIENT" ] || [ -z "$FILE" ]; then
    echo "Uso: gpg-encrypt <recipient> <file>"
    return 1
  fi
  gpg --encrypt --armor --recipient "$RECIPIENT" "$FILE"
}

gpg-decrypt() {
  gpg --decrypt "$1"
}
ALIASES

# ─── Source ───────────────────────────────────────────────
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "gpg_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# GPG aliases" >> "$RC"
    echo "[ -f ~/.gpg_aliases ] && source ~/.gpg_aliases" >> "$RC"
  fi
done

echo ""
echo "GPG + YubiKey configurado com sucesso!"
echo ""
echo "Próximos passos manuais (com YubiKey conectado):"
echo ""
echo "  1. Verifique o YubiKey:"
echo "     yk-status"
echo ""
echo "  2. Se precisar gerar/importar key:"
echo "     gpg --full-generate-key      # gerar nova"
echo "     gpg --import key.asc         # importar existente"
echo ""
echo "  3. Mover key para o YubiKey (cuidado: keytocard é destrutivo):"
echo "     gpg --edit-key <KEYID>"
echo "     > keytocard"
echo ""
echo "  4. Configurar git para signed commits:"
echo "     gpg-git-setup <KEYID>"
echo ""
echo "  5. Adicionar SSH key (derivada do GPG) no GitHub:"
echo "     gpg-ssh-pub"
echo ""
echo "Comandos úteis:"
echo "  gpg-keys / gpg-secret    Listar keys"
echo "  yk-status / yk-info      Info do YubiKey"
echo "  gpg-pub <keyid>          Export public key (PEM)"
echo "  gpg-encrypt / gpg-decrypt"
