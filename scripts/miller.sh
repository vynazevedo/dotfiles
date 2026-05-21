#!/usr/bin/env bash
# ─────────────────────────────────────────
# miller.sh
# Miller (mlr) — processador de dados CSV/TSV/JSON
# Author: Vinicius Azevedo <github.com/vynazevedo>
# ─────────────────────────────────────────

set -e

echo "miller-boost — instalando Miller (mlr)..."

# ─── Detecção de arquitetura ──────────────────────────────
ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
case "$ARCH" in
  amd64|arm64) ;;
  *) echo "  Aviso: arquitetura '$ARCH' — usando fallback do apt." ;;
esac

# ─── Dependências ─────────────────────────────────────────
echo "  Instalando dependências..."
sudo apt update -q
sudo apt install -y curl ca-certificates

# ─── Instalar Miller ──────────────────────────────────────
echo ""
if command -v mlr &>/dev/null; then
  echo "  Miller já instalado: $(mlr --version)"
else
  echo "  Instalando Miller (última versão do GitHub)..."

  MLR_TAG=$(curl -s https://api.github.com/repos/johnkerl/miller/releases/latest \
    | grep tag_name | cut -d'"' -f4)
  MLR_VER="${MLR_TAG#v}"

  INSTALLED=false

  if [ -n "$MLR_VER" ] && { [ "$ARCH" = "amd64" ] || [ "$ARCH" = "arm64" ]; }; then
    TARBALL="miller-${MLR_VER}-linux-${ARCH}.tar.gz"
    TMP=$(mktemp -d)

    if curl -fsSL "https://github.com/johnkerl/miller/releases/download/${MLR_TAG}/${TARBALL}" \
        -o "$TMP/$TARBALL" 2>/dev/null; then
      tar -xzf "$TMP/$TARBALL" -C "$TMP"

      MLR_BIN=$(find "$TMP" -name mlr -type f | head -1)
      if [ -n "$MLR_BIN" ]; then
        sudo install -m 0755 "$MLR_BIN" /usr/local/bin/mlr
        INSTALLED=true

        # Man page, se vier no tarball
        MLR_MAN=$(find "$TMP" -name 'mlr.1' -type f | head -1)
        if [ -n "$MLR_MAN" ]; then
          sudo install -m 0644 -D "$MLR_MAN" /usr/local/share/man/man1/mlr.1
        fi
      fi
    fi

    rm -rf "$TMP"
  fi

  # Fallback: apt
  if [ "$INSTALLED" = false ]; then
    echo "  Download do GitHub falhou — instalando via apt..."
    sudo apt install -y miller
  fi
fi

echo "  Versão instalada: $(mlr --version 2>/dev/null || echo 'erro')"

# ─── Aliases ──────────────────────────────────────────────
ALIAS_FILE="$HOME/.miller_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# Miller aliases — gerado por dotfiles
# ─────────────────────────────────────────

# Pretty-print (formato visual alinhado)
alias mlrp='mlr --c2p'
alias mlrt='mlr --t2p'
alias mlrjp='mlr --j2p'

# Conversões de formato
alias csv2json='mlr --icsv --ojson cat'
alias json2csv='mlr --ijson --ocsv cat'
alias csv2tsv='mlr --icsv --otsv cat'
alias tsv2csv='mlr --itsv --ocsv cat'
alias csv2md='mlr --icsv --omd cat'

# Visualizar CSV pretty-print
csvview() {
  if [ -z "$1" ]; then
    echo "Uso: csvview <arquivo.csv> [linhas]"
    return 1
  fi
  mlr --icsv --opprint head -n "${2:-20}" "$1"
}

# Colunas de um CSV (primeiro registro em formato chave:valor)
csvcols() {
  if [ -z "$1" ]; then
    echo "Uso: csvcols <arquivo.csv>"
    return 1
  fi
  mlr --icsv --oxtab head -n 1 "$1"
}

# Estatísticas de uma coluna numérica
csvstats() {
  if [ -z "$2" ]; then
    echo "Uso: csvstats <arquivo.csv> <coluna>"
    return 1
  fi
  mlr --icsv --opprint stats1 -a count,sum,mean,min,max,stddev -f "$2" "$1"
}

# Contagem de linhas (registros, sem header)
csvcount() {
  if [ -z "$1" ]; then
    echo "Uso: csvcount <arquivo.csv>"
    return 1
  fi
  mlr --icsv --ojson count "$1"
}

# Valores únicos de uma coluna
csvuniq() {
  if [ -z "$2" ]; then
    echo "Uso: csvuniq <arquivo.csv> <coluna>"
    return 1
  fi
  mlr --icsv --opprint count-distinct -f "$2" "$1"
}
ALIASES

# ─── Source ───────────────────────────────────────────────
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "miller_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# Miller aliases" >> "$RC"
    echo "[ -f ~/.miller_aliases ] && source ~/.miller_aliases" >> "$RC"
  fi
done

echo ""
echo "Miller instalado com sucesso!"
echo ""
echo "Miller (mlr) processa CSV, TSV, JSON e mais — como awk/sed/cut/join,"
echo "mas ciente do formato dos dados."
echo ""
echo "Aliases:"
echo "  mlrp <file>            CSV em pretty-print"
echo "  csv2json / json2csv    conversão de formato"
echo "  csv2tsv / csv2md       CSV para TSV / Markdown"
echo "  csvview <file> [n]     visualiza CSV alinhado"
echo "  csvcols <file>         lista colunas"
echo "  csvstats <file> <col>  estatísticas de uma coluna"
echo "  csvcount <file>        conta registros"
echo "  csvuniq <file> <col>   valores únicos de uma coluna"
echo ""
echo "Exemplos:"
echo "  mlr --c2p cat dados.csv"
echo "  mlr --icsv --ojson filter '\$idade > 30' dados.csv"
echo "  mlr --c2p sort -nr valor then head -n 5 vendas.csv"
echo ""
echo "Docs: https://miller.readthedocs.io"
