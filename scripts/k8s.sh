#!/usr/bin/env bash
# ─────────────────────────────────────────
# k8s.sh
# kubectl + helm + k9s + kubectx + kubens
# Author: Vinicius Azevedo <github.com/vynazevedo>
# ─────────────────────────────────────────

set -e

echo "k8s-boost — instalando toolkit Kubernetes..."

# ─── Detecção de arquitetura ──────────────────────────────
ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")

# ─── Dependências ─────────────────────────────────────────
echo "  Instalando dependências..."
sudo apt update -q
sudo apt install -y curl ca-certificates gnupg apt-transport-https

sudo install -m 0755 -d /etc/apt/keyrings

# ─── kubectl ──────────────────────────────────────────────
echo ""
if command -v kubectl &>/dev/null; then
  echo "  kubectl já instalado: $(kubectl version --client 2>/dev/null | head -1)"
else
  echo "  Instalando kubectl..."
  K8S_VERSION="v1.31"
  curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key" | \
    sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg
  sudo chmod a+r /etc/apt/keyrings/kubernetes.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
  sudo apt update -q
  sudo apt install -y kubectl
fi

# ─── helm ─────────────────────────────────────────────────
echo ""
if command -v helm &>/dev/null; then
  echo "  helm já instalado: $(helm version --short 2>/dev/null)"
else
  echo "  Instalando helm..."
  curl -fsSL https://baltocdn.com/helm/signing.asc | \
    sudo gpg --dearmor -o /etc/apt/keyrings/helm.gpg
  sudo chmod a+r /etc/apt/keyrings/helm.gpg
  echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | \
    sudo tee /etc/apt/sources.list.d/helm-stable-debian.list > /dev/null
  sudo apt update -q
  sudo apt install -y helm
fi

# ─── k9s ──────────────────────────────────────────────────
echo ""
if command -v k9s &>/dev/null; then
  echo "  k9s já instalado, pulando..."
else
  echo "  Instalando k9s..."
  K9S_DEB="k9s_linux_${ARCH}.deb"
  curl -fsSL "https://github.com/derailed/k9s/releases/latest/download/${K9S_DEB}" \
    -o "/tmp/${K9S_DEB}" 2>/dev/null

  if [ -f "/tmp/${K9S_DEB}" ]; then
    sudo dpkg -i "/tmp/${K9S_DEB}" 2>/dev/null || sudo apt install -f -y
    rm -f "/tmp/${K9S_DEB}"
  else
    echo "    Aviso: falha ao baixar k9s para ${ARCH}"
  fi
fi

# ─── kubectx + kubens ────────────────────────────────────
echo ""
if command -v kubectx &>/dev/null; then
  echo "  kubectx já instalado, pulando..."
else
  echo "  Instalando kubectx + kubens..."
  sudo apt install -y kubectx 2>/dev/null || {
    # Fallback: instalar do GitHub
    sudo git clone --depth=1 https://github.com/ahmetb/kubectx /opt/kubectx 2>/dev/null
    sudo ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
    sudo ln -sf /opt/kubectx/kubens /usr/local/bin/kubens
  }
fi

# ─── Completions ─────────────────────────────────────────
echo "  Configurando completions..."
mkdir -p "$HOME/.local/share/bash-completion/completions" 2>/dev/null || true

# ─── Aliases ──────────────────────────────────────────────
ALIAS_FILE="$HOME/.k8s_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# Kubernetes aliases — gerado por dotfiles
# ─────────────────────────────────────────

# kubectl
alias k='kubectl'
alias kg='kubectl get'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -A'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kge='kubectl get events --sort-by=.lastTimestamp'
alias kd='kubectl describe'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'
alias kap='kubectl apply -f'
alias kdel='kubectl delete'
alias kaf='kubectl apply -f'
alias kctx='kubectx'
alias kns='kubens'
alias ktop='kubectl top'

# Helm
alias h='helm'
alias hi='helm install'
alias hu='helm upgrade'
alias hun='helm uninstall'
alias hl='helm list'
alias hla='helm list -A'
alias hs='helm search repo'

# k9s
alias k9='k9s'

# Contexto atual
alias kcur='kubectl config current-context'
alias kcfg='kubectl config get-contexts'

# Shell num pod
kshell() {
  if [ -z "$1" ]; then
    echo "Uso: kshell <pod> [container]"
    return 1
  fi
  kubectl exec -it "$1" ${2:+-c "$2"} -- /bin/bash 2>/dev/null || \
    kubectl exec -it "$1" ${2:+-c "$2"} -- /bin/sh
}

# Logs com follow + tail
klog() {
  kubectl logs -f --tail=100 "$@"
}

# Watch de pods
kwatch() {
  watch -n 2 "kubectl get pods ${1:+-n $1}"
}

# Deletar pods em estado ruim
kclean() {
  kubectl delete pods --field-selector status.phase=Failed -A 2>/dev/null
  kubectl delete pods --field-selector status.phase=Succeeded -A 2>/dev/null
}
ALIASES

# ─── Source ───────────────────────────────────────────────
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "k8s_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# Kubernetes aliases" >> "$RC"
    echo "[ -f ~/.k8s_aliases ] && source ~/.k8s_aliases" >> "$RC"
  fi
done

# kubectl completion
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "kubectl completion" "$RC"; then
    SHELL_NAME=$(basename "$RC" | sed 's/^\.//;s/rc$//')
    echo "command -v kubectl &>/dev/null && source <(kubectl completion ${SHELL_NAME}) 2>/dev/null" >> "$RC"
    echo "command -v kubectl &>/dev/null && complete -o default -F __start_kubectl k 2>/dev/null" >> "$RC"
  fi
done

echo ""
echo "Kubernetes toolkit instalado com sucesso!"
echo ""
echo "Ferramentas:"
echo "  kubectl   $(kubectl version --client 2>/dev/null | head -1 | awk '{print $NF}')"
echo "  helm      $(helm version --short 2>/dev/null)"
echo "  k9s       TUI para clusters"
echo "  kubectx   troca de contexto"
echo "  kubens    troca de namespace"
echo ""
echo "Aliases principais:"
echo "  k         kubectl"
echo "  kgp/kgpa  get pods (namespace / all)"
echo "  klf       logs -f"
echo "  kex       exec -it"
echo "  kshell    shell interativo num pod"
echo "  k9        k9s (TUI)"
echo "  kctx/kns  trocar contexto/namespace"
