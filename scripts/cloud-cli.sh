#!/usr/bin/env bash
# ─────────────────────────────────────────
# cloud-cli.sh
# AWS CLI + Google Cloud SDK + Azure CLI
# Author: Vinicius Azevedo <github.com/vynazevedo>
# ─────────────────────────────────────────

set -e

echo "cloud-cli — instalando CLIs de cloud..."

# ─── Detecção de arquitetura ──────────────────────────────
ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
case "$ARCH" in
  amd64) AWS_ARCH="x86_64" ;;
  arm64) AWS_ARCH="aarch64" ;;
  *)     AWS_ARCH="x86_64" ;;
esac

# ─── Dependências ─────────────────────────────────────────
echo "  Instalando dependências..."
sudo apt update -q
sudo apt install -y curl unzip gnupg apt-transport-https ca-certificates

sudo install -m 0755 -d /etc/apt/keyrings

# ─── Seleção ──────────────────────────────────────────────
echo ""
echo "┌──────────────────────────────────────────────────┐"
echo "│  Quais clouds instalar?                            │"
echo "│                                                    │"
echo "│  1) AWS        apenas AWS CLI v2                   │"
echo "│  2) GCP        apenas Google Cloud SDK             │"
echo "│  3) Azure      apenas Azure CLI                    │"
echo "│  4) todas      AWS + GCP + Azure                   │"
echo "│                                                    │"
echo "└──────────────────────────────────────────────────┘"

read -rp "  Escolha [1-4]: " CHOICE

INSTALL_AWS=false
INSTALL_GCP=false
INSTALL_AZURE=false

case "$CHOICE" in
  1) INSTALL_AWS=true ;;
  2) INSTALL_GCP=true ;;
  3) INSTALL_AZURE=true ;;
  4) INSTALL_AWS=true; INSTALL_GCP=true; INSTALL_AZURE=true ;;
  *) echo "  Opção inválida."; exit 1 ;;
esac

# ─── AWS CLI v2 ───────────────────────────────────────────
if [ "$INSTALL_AWS" = true ]; then
  echo ""
  if command -v aws &>/dev/null; then
    echo "  AWS CLI já instalado: $(aws --version 2>&1 | awk '{print $1}')"
  else
    echo "  Instalando AWS CLI v2..."
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o /tmp/awscli.zip
    unzip -q /tmp/awscli.zip -d /tmp
    sudo /tmp/aws/install --update
    rm -rf /tmp/awscli.zip /tmp/aws
  fi
fi

# ─── Google Cloud SDK ────────────────────────────────────
if [ "$INSTALL_GCP" = true ]; then
  echo ""
  if command -v gcloud &>/dev/null; then
    echo "  gcloud já instalado: $(gcloud --version 2>/dev/null | head -1)"
  else
    echo "  Instalando Google Cloud SDK..."
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
      sudo gpg --dearmor -o /etc/apt/keyrings/cloud.google.gpg
    sudo chmod a+r /etc/apt/keyrings/cloud.google.gpg
    echo "deb [signed-by=/etc/apt/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
      sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
    sudo apt update -q
    sudo apt install -y google-cloud-cli
  fi
fi

# ─── Azure CLI ───────────────────────────────────────────
if [ "$INSTALL_AZURE" = true ]; then
  echo ""
  if command -v az &>/dev/null; then
    echo "  Azure CLI já instalado: $(az version 2>/dev/null | grep azure-cli | head -1)"
  else
    echo "  Instalando Azure CLI..."
    curl -fsSL https://aka.ms/InstallAzureCLIDeb | sudo bash
  fi
fi

# ─── Aliases ──────────────────────────────────────────────
ALIAS_FILE="$HOME/.cloud_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# Cloud CLI aliases — gerado por dotfiles
# ─────────────────────────────────────────

# AWS
alias awswho='aws sts get-caller-identity'
alias awsls='aws s3 ls'
alias awsprofile='echo "AWS_PROFILE=$AWS_PROFILE"'
alias awsregion='aws configure get region'

aws-use() {
  export AWS_PROFILE="$1"
  echo "AWS_PROFILE definido: $1"
  aws sts get-caller-identity 2>/dev/null || echo "Profile inválido ou sem credenciais"
}

aws-ec2() {
  aws ec2 describe-instances \
    --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType,IP:PublicIpAddress,Name:Tags[?Key==`Name`]|[0].Value}' \
    --output table
}

# GCP
alias gcwho='gcloud auth list'
alias gcproject='gcloud config get-value project'
alias gcprojects='gcloud projects list'

gc-use() {
  gcloud config set project "$1"
  echo "GCP project definido: $1"
}

# Azure
alias azwho='az account show'
alias azlist='az account list --output table'

az-use() {
  az account set --subscription "$1"
  echo "Azure subscription definida: $1"
}

# Geral: mostra contexto de todas as clouds
cloud-ctx() {
  echo "=== AWS ==="
  command -v aws &>/dev/null && (aws sts get-caller-identity 2>/dev/null || echo "não autenticado")
  echo ""
  echo "=== GCP ==="
  command -v gcloud &>/dev/null && gcloud config get-value project 2>/dev/null
  echo ""
  echo "=== Azure ==="
  command -v az &>/dev/null && (az account show --query name -o tsv 2>/dev/null || echo "não autenticado")
}
ALIASES

# ─── Source ───────────────────────────────────────────────
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "cloud_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# Cloud CLI aliases" >> "$RC"
    echo "[ -f ~/.cloud_aliases ] && source ~/.cloud_aliases" >> "$RC"
  fi
done

echo ""
echo "Cloud CLIs instaladas com sucesso!"
echo ""
[ "$INSTALL_AWS" = true ]   && echo "  AWS CLI    → aws configure"
[ "$INSTALL_GCP" = true ]   && echo "  gcloud     → gcloud init"
[ "$INSTALL_AZURE" = true ] && echo "  Azure CLI  → az login"
echo ""
echo "Aliases:"
echo "  awswho / gcwho / azwho     identidade atual"
echo "  aws-use / gc-use / az-use  trocar profile/project/subscription"
echo "  cloud-ctx                  contexto de todas as clouds"
echo ""
echo "Próximo passo: autentique-se em cada cloud (ver acima)."
