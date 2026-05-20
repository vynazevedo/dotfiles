#!/usr/bin/env bash
# ─────────────────────────────────────────
# cleanup.sh
# Limpeza e manutenção do sistema
# ─────────────────────────────────────────

set -e

echo "cleanup — limpando sistema..."
echo ""

bytes_to_human() {
  local bytes=$1
  if [ "$bytes" -ge 1073741824 ]; then
    echo "$(( bytes / 1073741824 ))G"
  elif [ "$bytes" -ge 1048576 ]; then
    echo "$(( bytes / 1048576 ))M"
  elif [ "$bytes" -ge 1024 ]; then
    echo "$(( bytes / 1024 ))K"
  else
    echo "${bytes}B"
  fi
}

space_before=$(df / --output=avail | tail -1)

# ─── APT cache ────────────────────────────────────────────
echo "  [1/8] Limpando cache do APT..."
sudo apt clean -y 2>/dev/null
sudo apt autoclean -y 2>/dev/null

# ─── Pacotes órfãos ──────────────────────────────────────
echo "  [2/8] Removendo pacotes órfãos..."
sudo apt autoremove -y 2>/dev/null

# ─── Kernels antigos ──────────────────────────────────────
echo "  [3/8] Removendo kernels antigos..."
CURRENT_KERNEL=$(uname -r)
dpkg -l 'linux-image-*' 2>/dev/null | grep '^ii' | awk '{print $2}' | \
  grep -v "$CURRENT_KERNEL" | grep -v "linux-image-generic" | \
  while read -r kernel; do
    echo "    Removendo $kernel..."
    sudo apt purge -y "$kernel" 2>/dev/null || true
  done

# ─── Logs antigos ─────────────────────────────────────────
echo "  [4/8] Rotacionando e limpando logs..."
sudo journalctl --vacuum-time=7d 2>/dev/null || true
sudo journalctl --vacuum-size=100M 2>/dev/null || true

# ─── Thumbnails cache ─────────────────────────────────────
echo "  [5/8] Limpando cache de thumbnails..."
rm -rf "$HOME/.cache/thumbnails"/* 2>/dev/null || true

# ─── Trash ────────────────────────────────────────────────
echo "  [6/8] Esvaziando lixeira..."
rm -rf "$HOME/.local/share/Trash"/* 2>/dev/null || true

# ─── Temp files ───────────────────────────────────────────
echo "  [7/8] Limpando temporários..."
sudo find /tmp -type f -atime +7 -delete 2>/dev/null || true
sudo find /var/tmp -type f -atime +7 -delete 2>/dev/null || true

# ─── Snap cache (se usar) ────────────────────────────────
echo "  [8/8] Limpando cache de snaps..."
if command -v snap &>/dev/null; then
  snap list --all | awk '/disabled/{print $1, $3}' | \
    while read -r snapname revision; do
      sudo snap remove "$snapname" --revision="$revision" 2>/dev/null || true
    done
fi

# ─── Docker cleanup (se instalado) ───────────────────────
if command -v docker &>/dev/null; then
  echo ""
  read -rp "  Limpar containers/images Docker parados? (s/n): " DOCKER_CLEAN
  if [[ "$DOCKER_CLEAN" =~ ^[sS]$ ]]; then
    docker container prune -f 2>/dev/null || true
    docker image prune -f 2>/dev/null || true
    docker volume prune -f 2>/dev/null || true
    docker network prune -f 2>/dev/null || true
  fi
fi

# ─── Resultado ────────────────────────────────────────────
space_after=$(df / --output=avail | tail -1)
freed_kb=$(( space_after - space_before ))
freed_bytes=$(( freed_kb * 1024 ))

echo ""
echo "Limpeza concluída!"
echo ""
echo "Espaço recuperado: ~$(bytes_to_human $freed_bytes)"
echo ""
echo "Uso atual do disco:"
df -h / --output=size,used,avail,pcent | head -2
