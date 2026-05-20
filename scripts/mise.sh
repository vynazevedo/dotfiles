#!/usr/bin/env bash
# ─────────────────────────────────────────
# mise.sh
# mise — version manager universal (nvm + pyenv + rbenv num só)
# Author: Vinicius Azevedo <github.com/vynazevedo>
# ─────────────────────────────────────────

set -e

echo "mise-boost — instalando version manager universal..."

# ─── Dependências ─────────────────────────────────────────
echo "  Instalando dependências..."
sudo apt update -q
sudo apt install -y curl git

# ─── Instalar mise ────────────────────────────────────────
echo ""
if command -v mise &>/dev/null; then
  echo "  mise já instalado: $(mise --version)"
  echo "  Atualizando..."
  mise self-update 2>/dev/null || true
else
  echo "  Instalando mise..."
  curl -fsSL https://mise.run | sh
fi

export PATH="$HOME/.local/bin:$PATH"

MISE_BIN="$HOME/.local/bin/mise"
if [ ! -x "$MISE_BIN" ]; then
  MISE_BIN="$(command -v mise)"
fi

# ─── Shell activation ────────────────────────────────────
echo "  Configurando ativação no shell..."

for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "mise activate" "$RC"; then
    SHELL_NAME=$(basename "$RC" | sed 's/^\.//;s/rc$//')
    echo "" >> "$RC"
    echo "# mise (version manager)" >> "$RC"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC"
    echo "eval \"\$(mise activate ${SHELL_NAME})\"" >> "$RC"
    echo "  mise activate adicionado em $(basename "$RC")"
  fi
done

# Ativar na sessão atual
eval "$("$MISE_BIN" activate bash)" 2>/dev/null || true

# ─── Plugins/runtimes opcionais ──────────────────────────
echo ""
echo "┌──────────────────────────────────────────────────┐"
echo "│  Instalar runtimes agora? (mise gerencia depois)  │"
echo "│                                                    │"
echo "│  1) nenhum     só o mise, instalo runtimes depois │"
echo "│  2) essencial  node@lts python@latest             │"
echo "│  3) completo   node, python, go, ruby (latest)    │"
echo "│                                                    │"
echo "└──────────────────────────────────────────────────┘"

read -rp "  Escolha [1-3]: " RUNTIME_CHOICE

install_runtime() {
  local tool="$1"
  echo "  Instalando $tool..."
  "$MISE_BIN" use -g "$tool" 2>/dev/null || \
    echo "    Aviso: falha ao instalar $tool"
}

case "$RUNTIME_CHOICE" in
  2)
    install_runtime "node@lts"
    install_runtime "python@latest"
    ;;
  3)
    install_runtime "node@lts"
    install_runtime "python@latest"
    install_runtime "go@latest"
    install_runtime "ruby@latest"
    ;;
  *)
    echo "  Nenhum runtime instalado. Use 'mise use -g <tool>@<versão>' depois."
    ;;
esac

# ─── Aliases ──────────────────────────────────────────────
ALIAS_FILE="$HOME/.mise_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# mise aliases — gerado por dotfiles
# ─────────────────────────────────────────

alias m='mise'
alias mi='mise install'
alias mu='mise use'
alias mug='mise use -g'
alias ml='mise list'
alias mlr='mise list-remote'
alias mx='mise exec'
alias mr='mise run'
alias mup='mise upgrade'
alias mcurrent='mise current'

# Listar runtimes disponíveis para um tool
mise-versions() {
  if [ -z "$1" ]; then
    echo "Uso: mise-versions <tool>  (ex: mise-versions node)"
    return 1
  fi
  mise list-remote "$1"
}

# Setup de projeto: cria .mise.toml com os runtimes atuais
mise-pin() {
  mise local "$@"
  echo "Runtimes pinados em .mise.toml"
}
ALIASES

# ─── Source ───────────────────────────────────────────────
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "mise_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# mise aliases" >> "$RC"
    echo "[ -f ~/.mise_aliases ] && source ~/.mise_aliases" >> "$RC"
  fi
done

echo ""
echo "mise instalado com sucesso!"
echo "  Versão: $("$MISE_BIN" --version)"
echo ""
echo "mise substitui nvm, pyenv, rbenv, etc. num único binário."
echo ""
echo "Comandos:"
echo "  mise use -g node@lts      Instala e define Node LTS global"
echo "  mise use python@3.12      Define Python no projeto (.mise.toml)"
echo "  mise list                 Runtimes instalados"
echo "  mise list-remote node     Versões disponíveis"
echo "  mise upgrade              Atualiza tudo"
echo ""
echo "Aliases: m, mi, mu, mug, ml, mx, mr"
echo ""
echo "Reabra o terminal ou rode: source ~/.zshrc"
