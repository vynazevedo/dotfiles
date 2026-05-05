#!/usr/bin/env bash
# ─────────────────────────────────────────
# wazuh.sh
# Wazuh agent (SIEM open source)
# Author: Vinicius Azevedo <github.com/vynazevedo>
# ─────────────────────────────────────────

set -e

echo "wazuh-boost — instalando Wazuh agent..."

# ─── Detecção de distro ───────────────────────────────────
if [ -f /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  DISTRO_ID="${ID}"
fi

case "$DISTRO_ID" in
  ubuntu|debian|kali) ;;
  *)
    echo "  Distro '${DISTRO_ID:-unknown}' não testada. Continuando..."
    ;;
esac

# ─── Já instalado? ────────────────────────────────────────
if command -v wazuh-control &>/dev/null || \
   [ -d /var/ossec ]; then
  echo "  Wazuh agent já instalado em /var/ossec"
  echo "  Para reconfigurar manager: edite /var/ossec/etc/ossec.conf"
  exit 0
fi

# ─── Coleta info do manager ───────────────────────────────
echo ""
echo "  Wazuh agent precisa apontar para um Wazuh manager."
echo "  Manager pode ser self-hosted ou cloud (Wazuh Cloud)."
echo ""

read -rp "  IP/hostname do Wazuh manager: " WAZUH_MANAGER
if [ -z "$WAZUH_MANAGER" ]; then
  echo "  Manager não pode ser vazio. Cancelando."
  exit 1
fi

read -rp "  Nome deste agent (default: $(hostname)): " AGENT_NAME
AGENT_NAME="${AGENT_NAME:-$(hostname)}"

read -rp "  Group do agent (default: default): " AGENT_GROUP
AGENT_GROUP="${AGENT_GROUP:-default}"

# ─── GPG key + repo ──────────────────────────────────────
echo ""
echo "  Adicionando repo Wazuh..."

curl -fsSL https://packages.wazuh.com/key/GPG-KEY-WAZUH | \
  sudo gpg --dearmor -o /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | \
  sudo tee /etc/apt/sources.list.d/wazuh.list > /dev/null

sudo apt update -q

# ─── Instalar agent ──────────────────────────────────────
echo "  Instalando wazuh-agent..."
sudo WAZUH_MANAGER="$WAZUH_MANAGER" \
  WAZUH_AGENT_NAME="$AGENT_NAME" \
  WAZUH_AGENT_GROUP="$AGENT_GROUP" \
  apt install -y wazuh-agent

# ─── Backup ossec.conf antes de qualquer ajuste ──────────
OSSEC_CONF="/var/ossec/etc/ossec.conf"
if [ -f "$OSSEC_CONF" ]; then
  sudo cp "$OSSEC_CONF" "$OSSEC_CONF.backup.$(date +%Y%m%d%H%M%S)"
  echo "  Backup do ossec.conf salvo"
fi

# ─── Pin version (não atualizar via apt upgrade automático) ──
echo "  Pinando versão (evita upgrade acidental)..."
sudo apt-mark hold wazuh-agent

# ─── Habilitar e iniciar ─────────────────────────────────
echo "  Habilitando wazuh-agent..."
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

sleep 3

# ─── Status ──────────────────────────────────────────────
echo ""
echo "  Status do agent:"
sudo /var/ossec/bin/wazuh-control status 2>/dev/null || \
  sudo systemctl status wazuh-agent --no-pager

# ─── Verificação ─────────────────────────────────────────
sleep 2
if grep -q "Connected to the server" /var/ossec/logs/ossec.log 2>/dev/null; then
  echo "  Agent conectado ao manager $WAZUH_MANAGER"
else
  echo "  Aviso: agent ainda não confirmou conexão."
  echo "  Verifique:"
  echo "    sudo tail -f /var/ossec/logs/ossec.log"
  echo "    No manager: /var/ossec/bin/agent_control -l"
fi

# ─── Aliases ──────────────────────────────────────────────
ALIAS_FILE="$HOME/.wazuh_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# Wazuh aliases — gerado por dotfiles
# ─────────────────────────────────────────

# Control
alias wz-status='sudo /var/ossec/bin/wazuh-control status'
alias wz-start='sudo systemctl start wazuh-agent'
alias wz-stop='sudo systemctl stop wazuh-agent'
alias wz-restart='sudo systemctl restart wazuh-agent'

# Logs
alias wz-log='sudo tail -f /var/ossec/logs/ossec.log'
alias wz-alerts='sudo tail -f /var/ossec/logs/alerts/alerts.log 2>/dev/null'
alias wz-active='sudo tail -f /var/ossec/logs/active-responses.log 2>/dev/null'

# Config
alias wz-conf='sudo ${EDITOR:-nano} /var/ossec/etc/ossec.conf'
alias wz-rules='ls /var/ossec/ruleset/rules/'

# Status
wz-info() {
  echo "=== Wazuh Agent Info ==="
  sudo /var/ossec/bin/wazuh-control info 2>/dev/null || true
  echo ""
  echo "=== Connected to ==="
  grep -E "MANAGER|server" /var/ossec/etc/ossec.conf | head -5
}

# Test connectivity
wz-test() {
  local manager
  manager=$(grep -oP '(?<=<address>)[^<]+' /var/ossec/etc/ossec.conf | head -1)
  echo "Testing connection to $manager..."
  nc -zv "$manager" 1514 2>&1
  nc -zv "$manager" 1515 2>&1
}
ALIASES

for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "wazuh_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# Wazuh aliases" >> "$RC"
    echo "[ -f ~/.wazuh_aliases ] && source ~/.wazuh_aliases" >> "$RC"
  fi
done

echo ""
echo "Wazuh agent instalado com sucesso!"
echo ""
echo "O que está sendo monitorado (defaults Wazuh):"
echo "  - File integrity (FIM): /etc, /usr/bin, /usr/sbin, /bin, /sbin"
echo "  - Rootkit detection (rootcheck)"
echo "  - System auditing (CIS benchmarks)"
echo "  - Vulnerability assessment"
echo "  - Active response capability"
echo ""
echo "Aliases:"
echo "  wz-status / wz-restart"
echo "  wz-log              Live logs do agent"
echo "  wz-alerts           Alertas (se configurado)"
echo "  wz-conf             Edita ossec.conf"
echo "  wz-info             Info detalhada"
echo "  wz-test             Testa conectividade com manager"
echo ""
echo "Manager: $WAZUH_MANAGER"
echo "Agent:   $AGENT_NAME (group: $AGENT_GROUP)"
