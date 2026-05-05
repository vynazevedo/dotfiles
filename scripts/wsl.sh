#!/usr/bin/env bash
# ─────────────────────────────────────────
# wsl.sh
# Otimizações e fixes para WSL2
# ─────────────────────────────────────────

set -e

echo "wsl-boost — configurando WSL2..."

# ─── Verificar se está no WSL ─────────────────────────────
if ! grep -qi microsoft /proc/version 2>/dev/null; then
  echo "  Este script é apenas para WSL2."
  exit 0
fi

echo "  WSL2 detectado!"

# ─── Configurar /etc/wsl.conf ────────────────────────────
echo ""
echo "  Configurando /etc/wsl.conf..."

if [ -f /etc/wsl.conf ]; then
  sudo cp /etc/wsl.conf "/etc/wsl.conf.backup.$(date +%Y%m%d%H%M%S)"
  echo "  Backup do wsl.conf salvo"
fi

sudo tee /etc/wsl.conf > /dev/null << 'CONF'
# ─────────────────────────────────────────
# wsl.conf — gerado por dotfiles
# ─────────────────────────────────────────

[boot]
systemd=true

[automount]
enabled = true
root = /mnt/
options = "metadata,umask=22,fmask=11"
mountFsTab = true

[network]
generateHosts = true
generateResolvConf = true

[interop]
enabled = true
appendWindowsPath = true
CONF

# ─── .wslconfig (no Windows) ─────────────────────────────
WINDOWS_USER=$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
WSLCONFIG="/mnt/c/Users/${WINDOWS_USER}/.wslconfig"

if [ -n "$WINDOWS_USER" ]; then
  echo "  Configurando .wslconfig para user: $WINDOWS_USER..."

  if [ -f "$WSLCONFIG" ]; then
    cp "$WSLCONFIG" "$WSLCONFIG.backup.$(date +%Y%m%d%H%M%S)"
    echo "  Backup do .wslconfig salvo"
  fi

  cat > "$WSLCONFIG" << 'WSLCONF'
# ─────────────────────────────────────────
# .wslconfig — gerado por dotfiles
# ─────────────────────────────────────────

[wsl2]
memory=8GB
processors=4
swap=4GB
localhostForwarding=true
nestedVirtualization=true

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
WSLCONF

  echo "  .wslconfig criado em $WSLCONFIG"
  echo "  AVISO: Ajuste memory e processors conforme seu hardware"
fi

# ─── Aliases WSL ──────────────────────────────────────────
ALIAS_FILE="$HOME/.wsl_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# WSL2 aliases — gerado por dotfiles
# ─────────────────────────────────────────

# Abrir no Windows Explorer
alias open='explorer.exe'
alias explorer='explorer.exe .'

# Clipboard integration
alias clip='clip.exe'
alias pbcopy='clip.exe'
alias pbpaste='powershell.exe -command "Get-Clipboard" | head -n -1'

# Windows paths
alias cddrive='cd /mnt/c'
alias cdwin='cd /mnt/c/Users/$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d "\r\n")'

# IP do host Windows (útil para conectar serviços)
alias winip='cat /etc/resolv.conf | grep nameserver | awk "{print \$2}"'

# Reiniciar WSL (rodar no PowerShell)
alias wslrestart='echo "Execute no PowerShell: wsl --shutdown"'

# Limpar cache do WSL
alias wslclean='sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"'

# Abrir VS Code no diretório atual
alias c.='code .'
ALIASES

# ─── Source ───────────────────────────────────────────────
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "wsl_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# WSL2 aliases" >> "$RC"
    echo "[ -f ~/.wsl_aliases ] && source ~/.wsl_aliases" >> "$RC"
  fi
done

# ─── Fix DNS (problema comum em WSL2) ────────────────────
echo ""
echo "  Verificando DNS..."

if ! nslookup google.com &>/dev/null; then
  echo "  DNS com problemas, aplicando fix..."
  sudo tee /etc/resolv.conf > /dev/null << 'DNS'
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
DNS

  sudo chattr +i /etc/resolv.conf 2>/dev/null || true
  echo "  DNS fixado (Google + Cloudflare)"
else
  echo "  DNS funcionando normalmente"
fi

# ─── Permissões de metadata ──────────────────────────────
echo "  Configurando umask para compatibilidade Windows/Linux..."
if ! grep -q "umask 022" "$HOME/.profile" 2>/dev/null; then
  echo "umask 022" >> "$HOME/.profile"
fi

echo ""
echo "WSL2 configurado com sucesso!"
echo ""
echo "Configurações aplicadas:"
echo "  - /etc/wsl.conf (systemd, automount, interop)"
echo "  - .wslconfig (memória, processadores, swap)"
echo "  - DNS fallback (Google + Cloudflare)"
echo "  - Aliases WSL (clipboard, explorer, paths)"
echo ""
echo "Aliases disponíveis:"
echo "  open <file>    Abrir no Windows"
echo "  explorer       Abrir Explorer no diretório atual"
echo "  clip           Copiar para clipboard Windows"
echo "  pbpaste        Colar do clipboard Windows"
echo "  cdwin          Ir para pasta do usuário Windows"
echo "  winip          IP do host Windows"
echo "  c.             Abrir VS Code aqui"
echo ""
echo "  Para aplicar: reinicie o WSL (wsl --shutdown no PowerShell)"
