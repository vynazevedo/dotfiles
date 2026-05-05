#!/usr/bin/env bash
# ─────────────────────────────────────────
# fail2ban.sh
# Fail2ban — proteção contra brute force
# ─────────────────────────────────────────

set -e

echo "fail2ban-boost — configurando proteção contra brute force..."

# ─── Instalar ─────────────────────────────────────────────
if command -v fail2ban-client &>/dev/null; then
  echo "  Fail2ban já instalado: $(fail2ban-client --version 2>&1 | head -1)"
else
  echo "  Instalando Fail2ban..."
  sudo apt update -q
  sudo apt install -y fail2ban
fi

# ─── Detectar porta SSH ──────────────────────────────────
SSH_PORT=$(grep -E "^Port " /etc/ssh/sshd_config.d/99-hardening.conf 2>/dev/null | awk '{print $2}')
if [ -z "$SSH_PORT" ]; then
  SSH_PORT=$(grep -E "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
fi
SSH_PORT="${SSH_PORT:-22}"

# ─── Config ───────────────────────────────────────────────
echo "  Configurando jails..."

if [ -f /etc/fail2ban/jail.local ]; then
  sudo cp /etc/fail2ban/jail.local "/etc/fail2ban/jail.local.backup.$(date +%Y%m%d%H%M%S)"
  echo "  Backup do jail.local salvo"
fi

sudo tee /etc/fail2ban/jail.local > /dev/null << EOF
# ─────────────────────────────────────────
# Fail2ban config — gerado por dotfiles
# ─────────────────────────────────────────

[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3
backend = systemd
banaction = ufw
destemail = root@localhost
sendername = Fail2ban
action = %(action_)s

[sshd]
enabled = true
port = ${SSH_PORT}
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3h

[sshd-ddos]
enabled = true
port = ${SSH_PORT}
filter = sshd-ddos
logpath = /var/log/auth.log
maxretry = 5
bantime = 24h

# Nginx (descomente se usar)
# [nginx-http-auth]
# enabled = true
# port = http,https
# filter = nginx-http-auth
# logpath = /var/log/nginx/error.log
# maxretry = 3

# [nginx-botsearch]
# enabled = true
# port = http,https
# filter = nginx-botsearch
# logpath = /var/log/nginx/access.log
# maxretry = 2

# Apache (descomente se usar)
# [apache-auth]
# enabled = true
# port = http,https
# filter = apache-auth
# logpath = /var/log/apache2/*error.log
# maxretry = 3
EOF

# ─── Ativar e iniciar ────────────────────────────────────
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

# ─── Status ───────────────────────────────────────────────
echo ""
echo "Fail2ban configurado com sucesso!"
echo ""
echo "Jails ativas:"
sudo fail2ban-client status 2>/dev/null || true
echo ""
echo "Comandos úteis:"
echo "  sudo fail2ban-client status sshd     Ver jail SSH"
echo "  sudo fail2ban-client set sshd unbanip <IP>   Desbanir IP"
echo "  sudo fail2ban-client reload          Recarregar config"
echo "  sudo fail2ban-client banned          Listar IPs banidos"
echo ""
echo "Config: /etc/fail2ban/jail.local"
