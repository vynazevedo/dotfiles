#!/usr/bin/env bash
# ─────────────────────────────────────────
# bun-deno.sh
# Bun + Deno — runtimes JavaScript modernos
# Author: Vinicius Azevedo <github.com/vynazevedo>
# ─────────────────────────────────────────

set -e

echo "bun-deno — instalando runtimes JS modernos..."

# ─── Dependências ─────────────────────────────────────────
echo "  Instalando dependências..."
sudo apt update -q
sudo apt install -y curl unzip

# ─── Bun ──────────────────────────────────────────────────
echo ""
echo "  Instalando Bun..."

export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"

if command -v bun &>/dev/null; then
  echo "  Bun já instalado: $(bun --version)"
  echo "  Atualizando..."
  bun upgrade 2>/dev/null || true
else
  curl -fsSL https://bun.sh/install | bash
fi

export PATH="$BUN_INSTALL/bin:$PATH"

# ─── Deno ─────────────────────────────────────────────────
echo ""
echo "  Instalando Deno..."

export DENO_INSTALL="${DENO_INSTALL:-$HOME/.deno}"

if command -v deno &>/dev/null; then
  echo "  Deno já instalado: $(deno --version | head -1)"
  echo "  Atualizando..."
  deno upgrade 2>/dev/null || true
else
  curl -fsSL https://deno.land/install.sh | sh -s -- -y
fi

export PATH="$DENO_INSTALL/bin:$PATH"

# ─── Shell integration ───────────────────────────────────
BUN_BLOCK='
# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"'

DENO_BLOCK='
# Deno
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"'

for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ]; then
    if ! grep -q "BUN_INSTALL" "$RC"; then
      echo "$BUN_BLOCK" >> "$RC"
      echo "  Bun PATH adicionado em $(basename "$RC")"
    fi
    if ! grep -q "DENO_INSTALL" "$RC"; then
      echo "$DENO_BLOCK" >> "$RC"
      echo "  Deno PATH adicionado em $(basename "$RC")"
    fi
  fi
done

# ─── Completions Bun ─────────────────────────────────────
if command -v bun &>/dev/null; then
  bun completions 2>/dev/null || true
fi

# ─── Aliases ──────────────────────────────────────────────
ALIAS_FILE="$HOME/.bundeno_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# Bun + Deno aliases — gerado por dotfiles
# ─────────────────────────────────────────

# Bun
alias b='bun'
alias br='bun run'
alias bi='bun install'
alias ba='bun add'
alias bad='bun add --dev'
alias brm='bun remove'
alias bx='bunx'
alias bt='bun test'
alias bb='bun build'
alias bd='bun dev'

# Deno
alias dn='deno'
alias dnr='deno run'
alias dnt='deno test'
alias dnf='deno fmt'
alias dnl='deno lint'
alias dnc='deno check'
alias dni='deno install'
alias dntask='deno task'

# Deno run com permissões comuns
alias dn-net='deno run --allow-net'
alias dn-all='deno run --allow-all'

# Bun: novo projeto
bun-new() {
  if [ -z "$1" ]; then
    echo "Uso: bun-new <nome>"
    return 1
  fi
  mkdir -p "$1" && cd "$1" && bun init -y
}
ALIASES

# ─── Source ───────────────────────────────────────────────
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "bundeno_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# Bun + Deno aliases" >> "$RC"
    echo "[ -f ~/.bundeno_aliases ] && source ~/.bundeno_aliases" >> "$RC"
  fi
done

echo ""
echo "Bun + Deno instalados com sucesso!"
echo "  Bun:  $(bun --version 2>/dev/null || echo 'reabra o terminal')"
echo "  Deno: $(deno --version 2>/dev/null | head -1 || echo 'reabra o terminal')"
echo ""
echo "Aliases:"
echo "  b / br / bi / ba / bx     Bun (run, install, add, bunx)"
echo "  dn / dnr / dnt / dnf      Deno (run, test, fmt)"
echo "  bun-new <nome>            Novo projeto Bun"
echo ""
echo "Reabra o terminal ou rode: source ~/.zshrc"
