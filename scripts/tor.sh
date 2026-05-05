#!/usr/bin/env bash
# ─────────────────────────────────────────
# tor.sh
# Tor + torsocks + obfs4 + aliases
# Author: Vinicius Azevedo <github.com/vynazevedo>
# ─────────────────────────────────────────

set -e

echo "tor-boost — instalando Tor e ferramentas de anonimato..."

# ─── Aviso ético ──────────────────────────────────────────
cat << 'WARN'

  AVISO: Tor é uma ferramenta de privacidade legítima.
  Usos legítimos: pesquisa de segurança, OSINT, bypass de
  censura, jornalismo, comunicação privada.

  NÃO use para atividades ilegais. Você é responsável
  pelo seu uso.

WARN

read -rp "  Continuar? (s/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
  echo "  Cancelado."
  exit 0
fi

# ─── Instalar Tor ─────────────────────────────────────────
if command -v tor &>/dev/null; then
  echo "  Tor já instalado: $(tor --version | head -1)"
else
  echo "  Instalando Tor..."
  sudo apt update -q
  sudo apt install -y tor torsocks
fi

# ─── obfs4proxy (bridges) ─────────────────────────────────
if command -v obfs4proxy &>/dev/null; then
  echo "  obfs4proxy já instalado, pulando..."
else
  echo "  Instalando obfs4proxy..."
  sudo apt install -y obfs4proxy 2>/dev/null || \
    echo "  Aviso: obfs4proxy não disponível nos repos"
fi

# ─── Backup torrc ─────────────────────────────────────────
TORRC="/etc/tor/torrc"
if [ -f "$TORRC" ]; then
  sudo cp "$TORRC" "$TORRC.backup.$(date +%Y%m%d%H%M%S)"
  echo "  Backup do torrc salvo"
fi

# ─── Config básica ────────────────────────────────────────
echo ""
echo "┌──────────────────────────────────────────────────┐"
echo "│  Profiles disponíveis:                            │"
echo "│                                                    │"
echo "│  1) client       SOCKS5 proxy local (padrão)      │"
echo "│  2) client+bridge Cliente atrás de censura        │"
echo "│  3) hidden       Hidden service (.onion)          │"
echo "│  4) skip         Manter config atual              │"
echo "│                                                    │"
echo "└──────────────────────────────────────────────────┘"

read -rp "  Escolha o profile [1-4]: " PROFILE

case "$PROFILE" in
  1)
    sudo tee "$TORRC" > /dev/null << 'CONF'
# Tor client config — gerado por dotfiles

SOCKSPort 9050
SOCKSPolicy accept 127.0.0.1
SOCKSPolicy reject *

ControlPort 9051
CookieAuthentication 1

DataDirectory /var/lib/tor
Log notice file /var/log/tor/notices.log

ExitPolicy reject *:*
CONF
    ;;
  2)
    sudo tee "$TORRC" > /dev/null << 'CONF'
# Tor client + bridge config — gerado por dotfiles

SOCKSPort 9050
ControlPort 9051

UseBridges 1
ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy

# Adicione bridges em https://bridges.torproject.org
# Exemplo:
# Bridge obfs4 IP:PORT FINGERPRINT cert=... iat-mode=0

DataDirectory /var/lib/tor
Log notice file /var/log/tor/notices.log
CONF
    echo ""
    echo "  IMPORTANTE: edite /etc/tor/torrc e adicione bridges de:"
    echo "  https://bridges.torproject.org"
    ;;
  3)
    read -rp "  Porta do serviço local (ex: 80): " LOCAL_PORT
    LOCAL_PORT="${LOCAL_PORT:-80}"

    sudo tee "$TORRC" > /dev/null << CONF
# Tor hidden service config — gerado por dotfiles

SOCKSPort 9050
ControlPort 9051

HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServicePort 80 127.0.0.1:${LOCAL_PORT}

DataDirectory /var/lib/tor
Log notice file /var/log/tor/notices.log
CONF

    sudo mkdir -p /var/lib/tor/hidden_service
    sudo chown -R debian-tor:debian-tor /var/lib/tor/hidden_service
    sudo chmod 700 /var/lib/tor/hidden_service
    ;;
  4)
    echo "  Mantendo config atual."
    ;;
  *)
    echo "  Opção inválida."
    exit 1
    ;;
esac

# ─── Restart ──────────────────────────────────────────────
if [ "$PROFILE" != "4" ]; then
  echo ""
  echo "  Reiniciando Tor..."
  sudo systemctl enable tor
  sudo systemctl restart tor
  sleep 2

  if systemctl is-active tor &>/dev/null; then
    echo "  Tor ativo"
  else
    echo "  Aviso: Tor não está ativo. Verifique: sudo journalctl -u tor"
  fi
fi

# ─── Hidden service hostname ──────────────────────────────
if [ "$PROFILE" = "3" ]; then
  sleep 3
  if [ -f /var/lib/tor/hidden_service/hostname ]; then
    echo ""
    echo "  Endereço .onion do seu serviço:"
    sudo cat /var/lib/tor/hidden_service/hostname
  fi
fi

# ─── Aliases ──────────────────────────────────────────────
ALIAS_FILE="$HOME/.tor_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# Tor aliases — gerado por dotfiles
# ─────────────────────────────────────────

# Status
alias tor-status='sudo systemctl status tor'
alias tor-restart='sudo systemctl restart tor'
alias tor-log='sudo tail -f /var/log/tor/notices.log'

# Browsing via Tor
alias over-tor='torsocks'
alias curl-tor='curl --socks5 127.0.0.1:9050 --socks5-hostname 127.0.0.1:9050'
alias wget-tor='wget -e use_proxy=yes -e socks_proxy=127.0.0.1:9050'

# Verificar IP via Tor
checktor() {
  local ip
  ip=$(curl --socks5 127.0.0.1:9050 -s https://check.torproject.org/api/ip)
  echo "$ip" | jq . 2>/dev/null || echo "$ip"
}

# Renovar circuit (precisa cookie de auth)
new-circuit() {
  echo "AUTHENTICATE \"\"" | nc -q 1 127.0.0.1 9051 2>/dev/null || \
    echo "Configure cookie auth ou senha no torrc primeiro"
  echo "SIGNAL NEWNYM" | nc -q 1 127.0.0.1 9051 2>/dev/null
}

# Hostname do hidden service (se existir)
onion-addr() {
  sudo cat /var/lib/tor/hidden_service/hostname 2>/dev/null || \
    echo "Nenhum hidden service configurado"
}
ALIASES

# ─── Source ───────────────────────────────────────────────
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "tor_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# Tor aliases" >> "$RC"
    echo "[ -f ~/.tor_aliases ] && source ~/.tor_aliases" >> "$RC"
  fi
done

echo ""
echo "Tor configurado com sucesso!"
echo ""
echo "Aliases disponíveis:"
echo "  tor-status / tor-restart / tor-log"
echo "  over-tor <cmd>     Roda comando via Tor"
echo "  curl-tor <url>     curl via SOCKS5"
echo "  checktor           Verifica IP visto pelo Tor"
echo "  new-circuit        Renova circuit Tor"
echo "  onion-addr         Mostra endereço .onion"
echo ""
echo "  SOCKS5 proxy: 127.0.0.1:9050"
echo "  Control port: 127.0.0.1:9051"
