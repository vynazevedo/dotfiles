#!/usr/bin/env bash
# ─────────────────────────────────────────
# pi-hole.sh
# Pi-hole + unbound DNS recursivo
# Author: Vinicius Azevedo <github.com/vynazevedo>
# ─────────────────────────────────────────

set -e

echo "pi-hole — instalando ad blocker + DNS recursivo..."

# ─── Aviso ────────────────────────────────────────────────
cat << 'WARN'

  AVISO: Pi-hole vai assumir o papel de DNS server.

  Roda como serviço escutando nas interfaces de rede.
  Configure os clientes (router, hosts) para usar este IP
  como DNS para benefícios em toda a rede.

  Este script é orientado para máquinas Linux dedicadas
  (servidor caseiro, mini-PC, VPS) — não recomendado em
  desktop normal.

WARN

read -rp "  Continuar? (s/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
  echo "  Cancelado."
  exit 0
fi

# ─── Pre-flight ───────────────────────────────────────────
if [ "$EUID" -eq 0 ]; then
  echo "  Erro: não rode este script como root."
  echo "  Use sudo apenas onde necessário (script pede)."
  exit 1
fi

# Verifica conflitos de DNS
if systemctl is-active systemd-resolved &>/dev/null; then
  echo ""
  echo "  AVISO: systemd-resolved está ativo na porta 53."
  echo "  Pi-hole precisa da porta 53 livre."
  read -rp "  Desabilitar systemd-resolved stub listener? (s/n): " DISABLE_STUB
  if [[ "$DISABLE_STUB" =~ ^[sS]$ ]]; then
    sudo mkdir -p /etc/systemd/resolved.conf.d
    echo -e "[Resolve]\nDNSStubListener=no" | \
      sudo tee /etc/systemd/resolved.conf.d/disable-stub.conf > /dev/null
    sudo systemctl restart systemd-resolved
    sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
    echo "  Stub listener desabilitado"
  fi
fi

# ─── Instalar Pi-hole ─────────────────────────────────────
if command -v pihole &>/dev/null; then
  echo "  Pi-hole já instalado: $(pihole -v | head -1)"
  echo "  Para reconfigurar: pihole -r"
else
  echo ""
  echo "  Baixando Pi-hole installer oficial..."
  echo "  ATENÇÃO: o instalador é interativo. Siga os prompts."
  echo ""

  # Pi-hole official installer
  curl -fsSL https://install.pi-hole.net | sudo bash
fi

# ─── unbound (DNS recursivo) ──────────────────────────────
echo ""
read -rp "  Instalar unbound (DNS recursivo, mais privacidade)? (s/n): " INSTALL_UNBOUND

if [[ "$INSTALL_UNBOUND" =~ ^[sS]$ ]]; then
  if command -v unbound &>/dev/null; then
    echo "  unbound já instalado, pulando..."
  else
    echo "  Instalando unbound..."
    sudo apt update -q
    sudo apt install -y unbound
  fi

  # Backup
  if [ -f /etc/unbound/unbound.conf.d/pi-hole.conf ]; then
    sudo cp /etc/unbound/unbound.conf.d/pi-hole.conf \
      "/etc/unbound/unbound.conf.d/pi-hole.conf.backup.$(date +%Y%m%d%H%M%S)"
  fi

  # Config recomendada Pi-hole + unbound
  sudo tee /etc/unbound/unbound.conf.d/pi-hole.conf > /dev/null << 'CONF'
# unbound config para Pi-hole — gerado por dotfiles

server:
  verbosity: 0

  interface: 127.0.0.1
  port: 5335
  do-ip4: yes
  do-udp: yes
  do-tcp: yes

  do-ip6: no
  prefer-ip6: no

  harden-glue: yes
  harden-dnssec-stripped: yes
  use-caps-for-id: no

  edns-buffer-size: 1232
  prefetch: yes

  num-threads: 1
  so-rcvbuf: 1m

  private-address: 192.168.0.0/16
  private-address: 169.254.0.0/16
  private-address: 172.16.0.0/12
  private-address: 10.0.0.0/8
  private-address: fd00::/8
  private-address: fe80::/10
CONF

  # Root hints
  if [ ! -f /var/lib/unbound/root.hints ]; then
    sudo curl -o /var/lib/unbound/root.hints \
      https://www.internic.net/domain/named.root
  fi

  sudo systemctl enable unbound
  sudo systemctl restart unbound

  sleep 2

  # Test
  echo ""
  echo "  Testando unbound..."
  if dig @127.0.0.1 -p 5335 example.com +short &>/dev/null; then
    echo "  unbound funcionando na porta 5335"
    echo ""
    echo "  Configure Pi-hole para usar unbound:"
    echo "    Settings > DNS > Custom DNS:"
    echo "    127.0.0.1#5335"
    echo "  E desmarque os outros upstream DNS"
  else
    echo "  Aviso: unbound não respondeu. Veja logs: sudo journalctl -u unbound"
  fi
fi

# ─── Block lists adicionais ───────────────────────────────
echo ""
read -rp "  Adicionar block lists curated? (s/n): " ADD_LISTS

if [[ "$ADD_LISTS" =~ ^[sS]$ ]] && command -v pihole &>/dev/null; then
  echo "  Adicionando block lists..."

  EXTRA_LISTS=(
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts"
    "https://urlhaus.abuse.ch/downloads/hostfile/"
    "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
  )

  for list in "${EXTRA_LISTS[@]}"; do
    sudo pihole -a -l "$list" 2>/dev/null || \
      echo "    Aviso: falha ao adicionar $list"
  done

  echo "  Atualizando gravity..."
  sudo pihole -g
fi

# ─── Aliases ──────────────────────────────────────────────
ALIAS_FILE="$HOME/.pihole_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# Pi-hole aliases — gerado por dotfiles
# ─────────────────────────────────────────

alias ph-status='pihole status'
alias ph-up='pihole enable'
alias ph-down='pihole disable'
alias ph-tail='pihole -t'
alias ph-update='pihole -up'
alias ph-gravity='pihole -g'
alias ph-restart='pihole restartdns'
alias ph-flush='pihole flush'
alias ph-tail='pihole -t'

# Logs
alias ph-log='sudo tail -f /var/log/pihole/pihole.log'
alias ph-query='pihole -q'

# Top blocks
ph-top() {
  pihole -c -j 2>/dev/null | jq -r '.top_blocked[] | "\(.value) \(.name)"' | head -20
}

# Stats rápido
ph-stats() {
  curl -s "http://localhost/admin/api.php" | jq .
}
ALIASES

for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "pihole_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# Pi-hole aliases" >> "$RC"
    echo "[ -f ~/.pihole_aliases ] && source ~/.pihole_aliases" >> "$RC"
  fi
done

echo ""
echo "Pi-hole instalado com sucesso!"
echo ""
echo "Acesso:"
echo "  Web UI:    http://$(hostname -I | awk '{print $1}')/admin"
echo "  Senha:     pihole -a -p"
echo ""
echo "Aliases:"
echo "  ph-status / ph-up / ph-down"
echo "  ph-tail            Stream de queries em tempo real"
echo "  ph-update          Atualiza Pi-hole core"
echo "  ph-gravity         Atualiza block lists"
echo "  ph-stats           Stats via API"
echo "  ph-top             Top 20 domínios bloqueados"
echo ""
echo "Próximo passo:"
echo "  Configure seu router para usar este IP como DNS"
echo "  ou configure clientes individualmente."
