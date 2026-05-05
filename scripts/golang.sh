#!/usr/bin/env bash
# ─────────────────────────────────────────
# golang.sh
# Go — última versão estável + ferramentas
# ─────────────────────────────────────────

set -e

echo "go-boost — instalando Go..."

# ─── Detectar versão mais recente ─────────────────────────
ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
case "$ARCH" in
  amd64) GO_ARCH="amd64" ;;
  arm64) GO_ARCH="arm64" ;;
  armhf) GO_ARCH="armv6l" ;;
  *) GO_ARCH="amd64" ;;
esac

LATEST_VERSION=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1)
echo "  Versão mais recente: $LATEST_VERSION"

# ─── Verificar se já está instalado ──────────────────────
if command -v go &>/dev/null; then
  CURRENT_VERSION="go$(go version | awk '{print $3}' | sed 's/go//')"
  echo "  Versão instalada: $CURRENT_VERSION"
  if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "  Go já está atualizado!"
  else
    echo "  Atualizando..."
    sudo rm -rf /usr/local/go
  fi
else
  echo "  Go não encontrado, instalando..."
fi

# ─── Download e instalação ────────────────────────────────
if ! command -v go &>/dev/null || [ "${CURRENT_VERSION:-}" != "$LATEST_VERSION" ]; then
  TARBALL="${LATEST_VERSION}.linux-${GO_ARCH}.tar.gz"
  echo "  Baixando $TARBALL..."
  curl -fsSL "https://go.dev/dl/${TARBALL}" -o "/tmp/${TARBALL}"

  echo "  Instalando em /usr/local/go..."
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "/tmp/${TARBALL}"
  rm -f "/tmp/${TARBALL}"
fi

# ─── Environment ──────────────────────────────────────────
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
export GOPATH="$HOME/go"

mkdir -p "$GOPATH/bin"

# ─── Ferramentas ──────────────────────────────────────────
echo ""
echo "  Instalando ferramentas Go..."

GO_TOOLS=(
  "golang.org/x/tools/gopls@latest"
  "github.com/go-delve/delve/cmd/dlv@latest"
  "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
  "github.com/air-verse/air@latest"
  "github.com/swaggo/swag/cmd/swag@latest"
  "gotest.tools/gotestsum@latest"
)

for tool in "${GO_TOOLS[@]}"; do
  TOOL_NAME=$(basename "${tool%%@*}")
  echo "    Instalando $TOOL_NAME..."
  go install "$tool" 2>/dev/null || echo "    Aviso: falha ao instalar $TOOL_NAME"
done

# ─── Shell integration ───────────────────────────────────
GO_BLOCK='
# Go
export GOPATH="$HOME/go"
export PATH="/usr/local/go/bin:$GOPATH/bin:$PATH"'

for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "GOPATH" "$RC"; then
    echo "$GO_BLOCK" >> "$RC"
    echo "  Go PATH adicionado em $(basename "$RC")"
  fi
done

echo ""
echo "Go configurado com sucesso!"
echo "  Versão: $(go version)"
echo "  GOPATH: $GOPATH"
echo ""
echo "Ferramentas instaladas:"
echo "  - gopls (LSP server)"
echo "  - dlv (debugger)"
echo "  - golangci-lint (linter)"
echo "  - air (live reload)"
echo "  - swag (Swagger docs)"
echo "  - gotestsum (test runner)"
