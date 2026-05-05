#!/usr/bin/env bash
# ─────────────────────────────────────────
# yara.sh
# YARA + rule sets + scanner template
# Author: Vinicius Azevedo <github.com/vynazevedo>
# ─────────────────────────────────────────

set -e

echo "yara-boost — instalando YARA + rule sets..."

# ─── Instalar YARA ────────────────────────────────────────
if command -v yara &>/dev/null; then
  echo "  YARA já instalado: $(yara --version)"
else
  echo "  Instalando YARA..."
  sudo apt update -q
  sudo apt install -y yara
fi

# ─── Instalar yara-python (opcional) ──────────────────────
echo ""
read -rp "  Instalar yara-python (bindings Python)? (s/n): " INSTALL_PY

if [[ "$INSTALL_PY" =~ ^[sS]$ ]]; then
  if python3 -c "import yara" 2>/dev/null; then
    echo "  yara-python já instalado"
  else
    if command -v pipx &>/dev/null; then
      pipx install yara-python 2>/dev/null || \
        pip3 install --user yara-python 2>/dev/null || \
        echo "  Aviso: falha ao instalar yara-python"
    else
      pip3 install --user yara-python 2>/dev/null || \
        echo "  Aviso: pip3 não disponível"
    fi
  fi
fi

# ─── Diretório de rules ──────────────────────────────────
RULES_DIR="$HOME/.yara/rules"
mkdir -p "$RULES_DIR"

# ─── Baixar rule sets curados ────────────────────────────
echo ""
echo "  Baixando rule sets..."

# YARA-Forge (Florian Roth + outros) - rules consolidadas
echo "    YARA-Forge core rules..."
if [ ! -d "$RULES_DIR/yara-forge" ]; then
  curl -fsSL "https://github.com/YARAHQ/yara-forge/releases/latest/download/yara-forge-rules-core.zip" \
    -o /tmp/yara-forge.zip 2>/dev/null

  if [ -f /tmp/yara-forge.zip ]; then
    unzip -q /tmp/yara-forge.zip -d "$RULES_DIR/yara-forge" 2>/dev/null && \
      rm -f /tmp/yara-forge.zip
  else
    echo "    Aviso: falha ao baixar YARA-Forge"
  fi
fi

# Reversing Labs (open rules)
echo "    Reversing Labs rules..."
if [ ! -d "$RULES_DIR/reversinglabs" ]; then
  git clone --depth=1 https://github.com/reversinglabs/reversinglabs-yara-rules.git \
    "$RULES_DIR/reversinglabs" 2>/dev/null || \
    echo "    Aviso: falha ao clonar reversinglabs"
fi

# Elastic protections-artifacts
echo "    Elastic protections..."
if [ ! -d "$RULES_DIR/elastic" ]; then
  git clone --depth=1 https://github.com/elastic/protections-artifacts.git \
    "$RULES_DIR/elastic" 2>/dev/null || \
    echo "    Aviso: falha ao clonar elastic"
fi

# ─── Scanner template ────────────────────────────────────
SCANNER="$HOME/.local/bin/yara-scan"
mkdir -p "$HOME/.local/bin"

cat > "$SCANNER" << 'SCANNER_EOF'
#!/usr/bin/env bash
# yara-scan — scanner wrapper para YARA
# Uso: yara-scan <path> [rules-dir]

set -e

TARGET="${1:-}"
RULES_DIR="${2:-$HOME/.yara/rules}"

if [ -z "$TARGET" ]; then
  echo "Uso: yara-scan <path> [rules-dir]"
  echo ""
  echo "Exemplos:"
  echo "  yara-scan /tmp                    # scan default rules"
  echo "  yara-scan ~/Downloads /custom     # rules custom"
  exit 1
fi

if [ ! -e "$TARGET" ]; then
  echo "Erro: $TARGET não existe"
  exit 1
fi

# Coleta todas as .yar/.yara recursivamente
RULES_FILES=$(find "$RULES_DIR" -type f \( -name '*.yar' -o -name '*.yara' \) 2>/dev/null)

if [ -z "$RULES_FILES" ]; then
  echo "Erro: nenhuma rule encontrada em $RULES_DIR"
  echo "Rode: bash <(curl -fsSL https://raw.githubusercontent.com/vynazevedo/dotfiles/main/scripts/yara.sh)"
  exit 1
fi

RULES_COUNT=$(echo "$RULES_FILES" | wc -l)
echo "Scanning $TARGET com $RULES_COUNT rule files..."
echo ""

HITS=0
echo "$RULES_FILES" | while IFS= read -r rule; do
  yara -r -s "$rule" "$TARGET" 2>/dev/null || true
done | tee /tmp/yara-scan.log

if [ -s /tmp/yara-scan.log ]; then
  HITS=$(wc -l < /tmp/yara-scan.log)
  echo ""
  echo "Total hits: $HITS"
  echo "Log salvo em /tmp/yara-scan.log"
else
  echo "Nenhum hit."
fi

rm -f /tmp/yara-scan.log
SCANNER_EOF

chmod +x "$SCANNER"

# ─── Aliases ──────────────────────────────────────────────
ALIAS_FILE="$HOME/.yara_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# YARA aliases — gerado por dotfiles
# ─────────────────────────────────────────

# Scan
alias yarscan='yara-scan'
alias yara-list='find ~/.yara/rules -type f \( -name "*.yar" -o -name "*.yara" \) | sort'
alias yara-count='find ~/.yara/rules -type f \( -name "*.yar" -o -name "*.yara" \) | wc -l'

# Update rule sets
yara-update() {
  echo "Atualizando rule sets..."

  for repo in reversinglabs elastic; do
    if [ -d "$HOME/.yara/rules/$repo" ]; then
      echo "  $repo..."
      cd "$HOME/.yara/rules/$repo" && git pull --rebase --quiet
      cd - > /dev/null
    fi
  done

  echo "  YARA-Forge..."
  curl -fsSL "https://github.com/YARAHQ/yara-forge/releases/latest/download/yara-forge-rules-core.zip" \
    -o /tmp/yara-forge.zip 2>/dev/null
  if [ -f /tmp/yara-forge.zip ]; then
    rm -rf "$HOME/.yara/rules/yara-forge"
    unzip -q /tmp/yara-forge.zip -d "$HOME/.yara/rules/yara-forge"
    rm -f /tmp/yara-forge.zip
  fi

  echo "Concluído. Total de rules: $(yara-count)"
}

# Validate rule
yara-test() {
  if [ -z "$1" ]; then
    echo "Uso: yara-test <rule.yar>"
    return 1
  fi
  yara "$1" /etc/hostname 2>&1 || echo "Rule tem erros."
}

# Scan rápido em diretórios sensíveis
yara-quick() {
  for path in /tmp /var/tmp ~/Downloads; do
    [ -d "$path" ] && yara-scan "$path"
  done
}

# IOC search (extrai strings/hashes de um file)
yara-ioc() {
  if [ -z "$1" ]; then
    echo "Uso: yara-ioc <file>"
    return 1
  fi
  echo "=== Strings ==="
  strings "$1" | grep -E '(http://|https://|\.exe|\.dll|@[a-zA-Z0-9.-]+)' | sort -u | head -50
  echo ""
  echo "=== Hashes ==="
  md5sum "$1"
  sha1sum "$1"
  sha256sum "$1"
}
ALIASES

for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "yara_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# YARA aliases" >> "$RC"
    echo "[ -f ~/.yara_aliases ] && source ~/.yara_aliases" >> "$RC"
  fi
done

echo ""
echo "YARA configurado com sucesso!"
echo ""
echo "Rule sets baixados:"
echo "  - YARA-Forge (core, ~10k rules consolidadas)"
echo "  - ReversingLabs (open rules)"
echo "  - Elastic protections-artifacts"
echo ""
echo "Comandos:"
echo "  yara-scan <path>     Scan recursivo com todas as rules"
echo "  yara-quick           Scan rápido em /tmp, ~/Downloads"
echo "  yara-list            Lista todas as rule files"
echo "  yara-count           Conta total de rules"
echo "  yara-update          Atualiza todas as rule sets"
echo "  yara-test <rule>     Valida sintaxe de uma rule"
echo "  yara-ioc <file>      Extrai IOCs (URLs, hashes) de um file"
echo ""
echo "Rules em: ~/.yara/rules/"
echo "Scanner em: ~/.local/bin/yara-scan"
