#!/usr/bin/env bash
# ─────────────────────────────────────────
# terraform.sh
# Terraform + tflint + tfsec + terraform-docs
# Author: Vinicius Azevedo <github.com/vynazevedo>
# ─────────────────────────────────────────

set -e

echo "terraform-boost — instalando toolkit IaC..."

# ─── Detecção de arquitetura ──────────────────────────────
ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")

# ─── Dependências ─────────────────────────────────────────
echo "  Instalando dependências..."
sudo apt update -q
sudo apt install -y curl gnupg software-properties-common unzip

sudo install -m 0755 -d /etc/apt/keyrings

# ─── Terraform (repo oficial HashiCorp) ──────────────────
echo ""
if command -v terraform &>/dev/null; then
  echo "  Terraform já instalado: $(terraform version | head -1)"
else
  echo "  Instalando Terraform..."
  curl -fsSL https://apt.releases.hashicorp.com/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
  sudo chmod a+r /etc/apt/keyrings/hashicorp.gpg

  CODENAME=$(grep VERSION_CODENAME /etc/os-release 2>/dev/null | cut -d= -f2)
  CODENAME="${CODENAME:-jammy}"

  echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com ${CODENAME} main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

  sudo apt update -q
  sudo apt install -y terraform 2>/dev/null || {
    echo "  Repo apt falhou (codename ${CODENAME}), instalando via binário..."
    TF_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d'"' -f4 | sed 's/v//')
    curl -fsSL "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_${ARCH}.zip" -o /tmp/tf.zip
    sudo unzip -o /tmp/tf.zip -d /usr/local/bin
    rm -f /tmp/tf.zip
  }
fi

# ─── tflint ───────────────────────────────────────────────
echo ""
if command -v tflint &>/dev/null; then
  echo "  tflint já instalado, pulando..."
else
  echo "  Instalando tflint..."
  curl -fsSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
fi

# ─── trivy (substituto do tfsec) ─────────────────────────
echo ""
if command -v trivy &>/dev/null; then
  echo "  trivy já instalado, pulando..."
else
  echo "  Instalando trivy (scan de segurança IaC)..."
  curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/trivy.gpg
  sudo chmod a+r /etc/apt/keyrings/trivy.gpg

  CODENAME=$(grep VERSION_CODENAME /etc/os-release 2>/dev/null | cut -d= -f2)
  CODENAME="${CODENAME:-jammy}"

  echo "deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb ${CODENAME} main" | \
    sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null
  sudo apt update -q
  sudo apt install -y trivy 2>/dev/null || echo "  Aviso: falha ao instalar trivy"
fi

# ─── terraform-docs ──────────────────────────────────────
echo ""
if command -v terraform-docs &>/dev/null; then
  echo "  terraform-docs já instalado, pulando..."
else
  echo "  Instalando terraform-docs..."
  TD_VERSION=$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep tag_name | cut -d'"' -f4)
  curl -fsSL "https://github.com/terraform-docs/terraform-docs/releases/download/${TD_VERSION}/terraform-docs-${TD_VERSION}-linux-${ARCH}.tar.gz" \
    -o /tmp/tfdocs.tar.gz 2>/dev/null

  if [ -f /tmp/tfdocs.tar.gz ]; then
    tar -xzf /tmp/tfdocs.tar.gz -C /tmp terraform-docs
    sudo install /tmp/terraform-docs /usr/local/bin/terraform-docs
    rm -f /tmp/tfdocs.tar.gz /tmp/terraform-docs
  else
    echo "  Aviso: falha ao baixar terraform-docs"
  fi
fi

# ─── Aliases ──────────────────────────────────────────────
ALIAS_FILE="$HOME/.terraform_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# Terraform aliases — gerado por dotfiles
# ─────────────────────────────────────────

alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfaa='terraform apply -auto-approve'
alias tfd='terraform destroy'
alias tfv='terraform validate'
alias tff='terraform fmt -recursive'
alias tfo='terraform output'
alias tfs='terraform state'
alias tfsl='terraform state list'
alias tfw='terraform workspace'
alias tfwl='terraform workspace list'
alias tfsh='terraform show'
alias tfg='terraform graph'

# Lint + security
alias tflint-all='tflint --recursive'
alias tfsec='trivy config'
alias tfscan='trivy config .'

# Plan salvando em arquivo
tfplan() {
  terraform plan -out=tfplan.out "$@"
}

# Apply do plan salvo
tfapply() {
  terraform apply tfplan.out && rm -f tfplan.out
}

# Init + validate + plan num comando
tfcheck() {
  terraform init -backend=false && \
  terraform validate && \
  terraform fmt -recursive -check
}

# Gerar docs do módulo
tfdocs() {
  terraform-docs markdown table --output-file README.md "${1:-.}"
}
ALIASES

# ─── Source ───────────────────────────────────────────────
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "terraform_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# Terraform aliases" >> "$RC"
    echo "[ -f ~/.terraform_aliases ] && source ~/.terraform_aliases" >> "$RC"
  fi
done

# Completion
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "terraform.*complete\|complete.*terraform" "$RC"; then
    echo "command -v terraform &>/dev/null && complete -C \"\$(command -v terraform)\" terraform tf 2>/dev/null" >> "$RC"
  fi
done

echo ""
echo "Terraform toolkit instalado com sucesso!"
echo ""
echo "Ferramentas:"
echo "  terraform       $(terraform version 2>/dev/null | head -1 | awk '{print $2}')"
echo "  tflint          linter de Terraform"
echo "  trivy           scan de segurança (config IaC)"
echo "  terraform-docs  gera docs de módulos"
echo ""
echo "Aliases:"
echo "  tf / tfi / tfp / tfa / tfd   terraform básico"
echo "  tff                          fmt -recursive"
echo "  tfcheck                      init + validate + fmt check"
echo "  tfplan / tfapply             plan salvo em arquivo"
echo "  tfscan                       trivy config scan"
echo "  tfdocs [dir]                 gera README do módulo"
