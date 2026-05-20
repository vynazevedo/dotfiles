#!/usr/bin/env bash
# ─────────────────────────────────────────
# system-info.sh
# Dashboard de informações do sistema
# ─────────────────────────────────────────

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

bar() {
  local percent=$1
  local width=30
  local filled=$(( percent * width / 100 ))
  local empty=$(( width - filled ))
  local color="$GREEN"
  [ "$percent" -ge 70 ] && color="$YELLOW"
  [ "$percent" -ge 90 ] && color="$RED"
  printf "${color}"
  printf '█%.0s' $(seq 1 "$filled" 2>/dev/null) || true
  printf "${DIM}"
  printf '░%.0s' $(seq 1 "$empty" 2>/dev/null) || true
  printf "${NC} ${percent}%%"
}

echo ""
echo -e "${GREEN}"
cat << 'BANNER'
  ┌─────────────────────────────────┐
  │       S Y S T E M   I N F O    │
  └─────────────────────────────────┘
BANNER
echo -e "${NC}"

# ─── OS ───────────────────────────────────────────────────
OS_NAME=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2)
KERNEL=$(uname -r)
ARCH=$(uname -m)
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
HOSTNAME=$(hostname)
USER_NAME=$(whoami)
SHELL_NAME=$(basename "$SHELL")
TERM_NAME=${TERM:-unknown}

echo -e "  ${BOLD}Host${NC}     $HOSTNAME"
echo -e "  ${BOLD}User${NC}     $USER_NAME"
echo -e "  ${BOLD}OS${NC}       $OS_NAME"
echo -e "  ${BOLD}Kernel${NC}   $KERNEL ($ARCH)"
echo -e "  ${BOLD}Uptime${NC}   $UPTIME"
echo -e "  ${BOLD}Shell${NC}    $SHELL_NAME"
echo -e "  ${BOLD}Terminal${NC} $TERM_NAME"

# ─── CPU ──────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}── CPU ──${NC}"

CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
CPU_CORES=$(nproc)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2 + $4)}')
LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')

echo -e "  ${BOLD}Model${NC}    $CPU_MODEL"
echo -e "  ${BOLD}Cores${NC}    $CPU_CORES"
echo -e "  ${BOLD}Usage${NC}    $(bar "$CPU_USAGE")"
echo -e "  ${BOLD}Load${NC}     $LOAD"

# ─── Memória ──────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}── MEMÓRIA ──${NC}"

MEM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/^Mem:/ {print $3}')
MEM_AVAIL=$(free -m | awk '/^Mem:/ {print $7}')
MEM_PERCENT=$(( MEM_USED * 100 / MEM_TOTAL ))
SWAP_TOTAL=$(free -m | awk '/^Swap:/ {print $2}')
SWAP_USED=$(free -m | awk '/^Swap:/ {print $3}')

echo -e "  ${BOLD}RAM${NC}      ${MEM_USED}M / ${MEM_TOTAL}M (${MEM_AVAIL}M disponível)"
echo -e "           $(bar "$MEM_PERCENT")"
if [ "$SWAP_TOTAL" -gt 0 ]; then
  SWAP_PERCENT=$(( SWAP_USED * 100 / SWAP_TOTAL ))
  echo -e "  ${BOLD}Swap${NC}     ${SWAP_USED}M / ${SWAP_TOTAL}M"
  echo -e "           $(bar "$SWAP_PERCENT")"
fi

# ─── Disco ────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}── DISCO ──${NC}"

df -h --output=source,size,used,avail,pcent,target 2>/dev/null | \
  grep -E "^/dev/" | while read -r dev size used avail pcent mount; do
  pcent_num=${pcent//%/}
  echo -e "  ${BOLD}${mount}${NC}"
  echo -e "    ${dev}  ${used} / ${size} (${avail} livre)"
  echo -e "    $(bar "$pcent_num")"
done

# ─── Rede ─────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}── REDE ──${NC}"

# IPs locais
ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | while read -r addr; do
  IFACE=$(ip -4 addr show | grep "$addr" -B2 | grep -oP '(?<=: )\w+' | head -1)
  echo -e "  ${BOLD}${IFACE}${NC}     $addr"
done

# IP público (timeout rápido)
PUB_IP=$(curl -s --connect-timeout 2 ifconfig.me 2>/dev/null || echo "N/A")
echo -e "  ${BOLD}Public${NC}   $PUB_IP"

# DNS
DNS=$(grep nameserver /etc/resolv.conf 2>/dev/null | head -2 | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
echo -e "  ${BOLD}DNS${NC}      $DNS"

# ─── Serviços ─────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}── SERVIÇOS ──${NC}"

SERVICES=("ssh" "sshd" "docker" "nginx" "apache2" "mysql" "postgresql" "redis-server" "ufw" "fail2ban")
for svc in "${SERVICES[@]}"; do
  if systemctl is-active "$svc" &>/dev/null 2>&1; then
    echo -e "  ${GREEN}●${NC} $svc"
  elif systemctl is-enabled "$svc" &>/dev/null 2>&1; then
    echo -e "  ${YELLOW}○${NC} $svc ${DIM}(enabled but stopped)${NC}"
  fi
done

# ─── Ferramentas instaladas ──────────────────────────────
echo ""
echo -e "  ${BOLD}── TOOLCHAIN ──${NC}"

check_tool() {
  if command -v "$1" &>/dev/null; then
    local version
    version=$("$1" --version 2>/dev/null | head -1 | grep -oP '[\d]+\.[\d]+\.[\d]+' | head -1)
    [ -z "$version" ] && version=$("$1" --version 2>/dev/null | head -1)
    echo -e "  ${GREEN}●${NC} $1 ${DIM}${version}${NC}"
  fi
}

check_tool node
check_tool go
check_tool rustc
check_tool python3
check_tool docker
check_tool nvim
check_tool tmux
check_tool git
check_tool zsh

# ─── Segurança rápida ─────────────────────────────────────
echo ""
echo -e "  ${BOLD}── SEGURANÇA ──${NC}"

# Firewall
if command -v ufw &>/dev/null && sudo ufw status 2>/dev/null | grep -q "active"; then
  echo -e "  ${GREEN}●${NC} Firewall ativo"
else
  echo -e "  ${RED}●${NC} Firewall inativo"
fi

# ASLR
ASLR=$(cat /proc/sys/kernel/randomize_va_space)
[ "$ASLR" = "2" ] && echo -e "  ${GREEN}●${NC} ASLR ativo" || echo -e "  ${RED}●${NC} ASLR desabilitado"

# Fail2ban
if systemctl is-active fail2ban &>/dev/null 2>&1; then
  echo -e "  ${GREEN}●${NC} Fail2ban ativo"
fi

# Unattended upgrades
if dpkg -l unattended-upgrades &>/dev/null 2>&1; then
  echo -e "  ${GREEN}●${NC} Unattended upgrades instalado"
else
  echo -e "  ${YELLOW}○${NC} Unattended upgrades não instalado"
fi

echo ""
echo -e "  ${DIM}Gerado em $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""
