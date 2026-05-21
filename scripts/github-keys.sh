#!/usr/bin/env bash
# ─────────────────────────────────────────
# github-keys.sh
# GitHub CLI + chave SSH ED25519 + cadastro automático
# Author: Vinicius Azevedo <github.com/vynazevedo>
# ─────────────────────────────────────────

set -e

echo "github-keys — configurando acesso seguro ao GitHub..."

# ─── Detecção de arquitetura ──────────────────────────────
ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")

# ─── Dependências ─────────────────────────────────────────
echo "  Instalando dependências..."
sudo apt update -q
sudo apt install -y curl git openssh-client

# ─── GitHub CLI ───────────────────────────────────────────
echo ""
if command -v gh &>/dev/null; then
  echo "  gh já instalado: $(gh --version | head -1)"
else
  echo "  Instalando GitHub CLI..."
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update -q
  sudo apt install -y gh
fi

# ─── Clipboard helper ─────────────────────────────────────
copy_clipboard() {
  local content="$1"
  if command -v clip.exe &>/dev/null; then
    printf '%s' "$content" | clip.exe && return 0
  elif [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy &>/dev/null; then
    printf '%s' "$content" | wl-copy && return 0
  elif command -v xclip &>/dev/null; then
    printf '%s' "$content" | xclip -selection clipboard && return 0
  elif command -v xsel &>/dev/null; then
    printf '%s' "$content" | xsel --clipboard --input && return 0
  fi
  return 1
}

# ─── E-mail ───────────────────────────────────────────────
echo ""
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
if [ -z "$GIT_EMAIL" ]; then
  read -rp "  Seu e-mail (usado no comentário da chave): " GIT_EMAIL
  if [ -n "$GIT_EMAIL" ]; then
    git config --global user.email "$GIT_EMAIL"
  fi
fi

GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
if [ -z "$GIT_NAME" ]; then
  read -rp "  Seu nome (para o git): " GIT_NAME
  if [ -n "$GIT_NAME" ]; then
    git config --global user.name "$GIT_NAME"
  fi
fi

# ─── Diretório ~/.ssh ─────────────────────────────────────
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# ─── Definir chave ────────────────────────────────────────
KEY_NAME="id_ed25519"
KEY_PATH="$HOME/.ssh/$KEY_NAME"
GENERATE=true

if [ -f "$KEY_PATH" ]; then
  echo ""
  echo "  Já existe uma chave em $KEY_PATH"
  read -rp "  Usar a existente (u) ou criar nova com outro nome (n)? [u/n]: " CHOICE
  if [[ "$CHOICE" =~ ^[nN]$ ]]; then
    read -rp "  Nome da nova chave (ex: id_ed25519_github): " KEY_NAME
    KEY_NAME="${KEY_NAME:-id_ed25519_github}"
    KEY_PATH="$HOME/.ssh/$KEY_NAME"
    if [ -f "$KEY_PATH" ]; then
      echo "  Erro: $KEY_PATH também já existe. Abortando."
      exit 1
    fi
  else
    GENERATE=false
    echo "  Usando chave existente."
  fi
fi

# ─── Gerar chave ED25519 ──────────────────────────────────
if [ "$GENERATE" = true ]; then
  echo ""
  echo "  Gerando chave ED25519..."
  echo "  RECOMENDADO: defina uma passphrase forte quando solicitado."
  echo ""

  KEY_COMMENT="${GIT_EMAIL:-$(whoami)} $(hostname) $(date +%Y-%m-%d)"
  ssh-keygen -t ed25519 -a 100 -C "$KEY_COMMENT" -f "$KEY_PATH"
fi

# ─── Permissões ───────────────────────────────────────────
chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"
echo "  Permissões ajustadas (600 privada, 644 pública)"

# ─── ssh-agent ────────────────────────────────────────────
echo ""
echo "  Adicionando chave ao ssh-agent..."
if [ -z "${SSH_AUTH_SOCK:-}" ]; then
  eval "$(ssh-agent -s)" > /dev/null
fi
ssh-add "$KEY_PATH" 2>/dev/null || \
  echo "  Aviso: não foi possível adicionar ao agent agora (faça ssh-add depois)"

# ─── ~/.ssh/config ────────────────────────────────────────
echo ""
echo "  Configurando ~/.ssh/config..."

SSH_CONFIG="$HOME/.ssh/config"
MARKER_BEGIN="# >>> github-keys managed block >>>"
MARKER_END="# <<< github-keys managed block <<<"

touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

if [ -s "$SSH_CONFIG" ]; then
  cp "$SSH_CONFIG" "$SSH_CONFIG.backup.$(date +%Y%m%d%H%M%S)"
  echo "  Backup do ssh/config salvo"
fi

if grep -q "Host github.com" "$SSH_CONFIG" && ! grep -q "$MARKER_BEGIN" "$SSH_CONFIG"; then
  echo "  AVISO: já existe um bloco 'Host github.com' não gerenciado."
  echo "  O bloco gerenciado será adicionado mesmo assim — revise duplicatas."
fi

MANAGED_BLOCK=$(cat << BLOCK
Host github.com
  HostName github.com
  User git
  IdentityFile ${KEY_PATH}
  IdentitiesOnly yes
  AddKeysToAgent yes
  PreferredAuthentications publickey
BLOCK
)

if grep -q "$MARKER_BEGIN" "$SSH_CONFIG" 2>/dev/null; then
  sed -i "/$MARKER_BEGIN/,/$MARKER_END/d" "$SSH_CONFIG"
fi

{
  echo "$MARKER_BEGIN"
  echo "$MANAGED_BLOCK"
  echo "$MARKER_END"
  echo ""
  cat "$SSH_CONFIG"
} > "$SSH_CONFIG.tmp" && mv "$SSH_CONFIG.tmp" "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

echo "  Bloco github.com configurado (IdentitiesOnly, AddKeysToAgent)"

# ─── Copiar chave pública ────────────────────────────────
PUB_KEY=$(cat "$KEY_PATH.pub")
echo ""
if copy_clipboard "$PUB_KEY"; then
  echo "  Chave pública copiada para o clipboard!"
else
  echo "  (Sem ferramenta de clipboard — copie manualmente abaixo)"
  if [ -z "${WAYLAND_DISPLAY:-}" ] && ! command -v clip.exe &>/dev/null; then
    sudo apt install -y xclip 2>/dev/null && copy_clipboard "$PUB_KEY" && \
      echo "  xclip instalado — chave copiada!"
  fi
fi

echo ""
echo "  ─── Sua chave pública ───"
echo "$PUB_KEY"
echo "  ─────────────────────────"

# ─── Cadastro no GitHub ──────────────────────────────────
echo ""
echo "  Cadastrando a chave no GitHub..."

KEY_TITLE="$(hostname) ($(date +%Y-%m-%d))"

if gh auth status &>/dev/null; then
  echo "  gh já autenticado."
else
  echo ""
  echo "  Você precisa autenticar o gh. Abrindo gh auth login..."
  echo "  (escolha GitHub.com > autentique pelo browser)"
  echo ""
  gh auth login --scopes "admin:public_key,admin:ssh_signing_key"
fi

# Garante os escopos necessários para cadastrar chaves
ensure_gh_scope() {
  local scope="$1"
  if ! gh auth status 2>&1 | grep -q "$scope"; then
    echo "  Escopo '$scope' ausente — solicitando via gh auth refresh..."
    gh auth refresh -h github.com -s "$scope"
  fi
}

# Auth key
if gh auth status &>/dev/null; then
  ensure_gh_scope "admin:public_key"

  echo "  Registrando chave de autenticação..."
  if gh ssh-key add "$KEY_PATH.pub" --title "$KEY_TITLE"; then
    echo "  Chave de autenticação cadastrada!"
  else
    echo "  Aviso: falha ao cadastrar (pode já existir). Verifique com: gh ssh-key list"
  fi

  # Signing key
  echo ""
  read -rp "  Configurar SSH commit signing (assinar commits)? (s/n): " SIGN
  if [[ "$SIGN" =~ ^[sS]$ ]]; then
    ensure_gh_scope "admin:ssh_signing_key"

    if gh ssh-key add "$KEY_PATH.pub" --type signing --title "$KEY_TITLE (signing)"; then
      echo "  Chave de signing cadastrada no GitHub!"
    else
      echo "  Aviso: falha ao cadastrar chave de signing (pode já existir)."
    fi

    # Git config para SSH signing
    git config --global gpg.format ssh
    git config --global user.signingkey "$KEY_PATH.pub"
    git config --global commit.gpgsign true
    git config --global tag.gpgsign true

    # allowed_signers
    ALLOWED_SIGNERS="$HOME/.ssh/allowed_signers"
    SIGNER_LINE="${GIT_EMAIL:-$(whoami)} namespaces=\"git\" $PUB_KEY"
    if [ -f "$ALLOWED_SIGNERS" ] && grep -qF "$PUB_KEY" "$ALLOWED_SIGNERS"; then
      :
    else
      echo "$SIGNER_LINE" >> "$ALLOWED_SIGNERS"
    fi
    chmod 644 "$ALLOWED_SIGNERS"
    git config --global gpg.ssh.allowedSignersFile "$ALLOWED_SIGNERS"

    echo "  Commits agora são assinados com a chave SSH (sem GPG)."
  fi
else
  echo ""
  echo "  gh não autenticado. Cadastre a chave manualmente:"
  echo "    1. Acesse: https://github.com/settings/ssh/new"
  echo "    2. Title: $KEY_TITLE"
  echo "    3. Cole a chave pública (já está no clipboard)"
fi

# ─── Testar conexão ──────────────────────────────────────
echo ""
echo "  Testando conexão SSH com o GitHub..."
TEST_OUTPUT=$(ssh -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 || true)

if echo "$TEST_OUTPUT" | grep -q "successfully authenticated"; then
  echo "  Conexão OK — autenticado com sucesso!"
else
  echo "  Resposta do GitHub:"
  echo "    $TEST_OUTPUT"
  echo "  (Se a chave foi recém-cadastrada, aguarde alguns segundos e teste:"
  echo "   ssh -T git@github.com)"
fi

# ─── Resumo ───────────────────────────────────────────────
echo ""
echo "github-keys concluído com sucesso!"
echo ""
echo "O que foi configurado:"
echo "  - GitHub CLI (gh) instalado"
echo "  - Chave ED25519: $KEY_PATH"
echo "  - Permissões corretas (~/.ssh 700, chave 600)"
echo "  - ~/.ssh/config com bloco github.com (IdentitiesOnly)"
echo "  - Chave adicionada ao ssh-agent"
echo "  - Chave cadastrada no GitHub (auth + signing opcional)"
echo ""
echo "Boas práticas aplicadas:"
echo "  - ED25519 (mais seguro e rápido que RSA)"
echo "  - Passphrase na chave privada"
echo "  - IdentitiesOnly yes (não vaza outras chaves)"
echo "  - Chave dedicada por host"
echo ""
echo "Dica: clone repos via SSH com  git clone git@github.com:user/repo.git"
