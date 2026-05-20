#!/usr/bin/env bash
# ─────────────────────────────────────────
# ansible.sh
# Ansible + ansible-lint + estrutura de projeto
# Author: Vinicius Azevedo <github.com/vynazevedo>
# ─────────────────────────────────────────

set -e

echo "ansible-boost — instalando Ansible..."

# ─── Dependências ─────────────────────────────────────────
echo "  Instalando dependências..."
sudo apt update -q
sudo apt install -y python3 python3-pip sshpass

# ─── Ansible via pipx ────────────────────────────────────
echo ""
if command -v ansible &>/dev/null; then
  echo "  Ansible já instalado: $(ansible --version | head -1)"
else
  echo "  Instalando Ansible..."

  if ! command -v pipx &>/dev/null; then
    echo "  Instalando pipx..."
    sudo apt install -y pipx 2>/dev/null || pip3 install --user pipx
    python3 -m pipx ensurepath 2>/dev/null || true
  fi

  export PATH="$HOME/.local/bin:$PATH"

  pipx install --include-deps ansible 2>/dev/null || {
    echo "  pipx falhou, instalando via apt..."
    sudo apt install -y ansible
  }
fi

export PATH="$HOME/.local/bin:$PATH"

# ─── ansible-lint ────────────────────────────────────────
echo ""
if command -v ansible-lint &>/dev/null; then
  echo "  ansible-lint já instalado, pulando..."
else
  echo "  Instalando ansible-lint..."
  pipx install ansible-lint 2>/dev/null || \
    pip3 install --user ansible-lint 2>/dev/null || \
    echo "  Aviso: falha ao instalar ansible-lint"
fi

# ─── Estrutura de diretórios padrão ──────────────────────
ANSIBLE_HOME="$HOME/.ansible"
mkdir -p "$ANSIBLE_HOME"

# ─── ansible.cfg global ──────────────────────────────────
ANSIBLE_CFG="$HOME/.ansible.cfg"
if [ -f "$ANSIBLE_CFG" ]; then
  cp "$ANSIBLE_CFG" "$ANSIBLE_CFG.backup.$(date +%Y%m%d%H%M%S)"
  echo "  Backup do ansible.cfg salvo"
fi

cat > "$ANSIBLE_CFG" << 'CFG'
# ansible.cfg — gerado por dotfiles

[defaults]
host_key_checking = False
retry_files_enabled = False
interpreter_python = auto_silent
stdout_callback = yaml
bin_ansible_callbacks = True
nocows = 1
forks = 20
timeout = 30
gathering = smart
fact_caching = jsonfile
fact_caching_connection = ~/.ansible/fact_cache
fact_caching_timeout = 3600

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o ServerAliveInterval=30

[privilege_escalation]
become = False
become_method = sudo
CFG

mkdir -p "$ANSIBLE_HOME/fact_cache"

# ─── Skeleton de projeto ─────────────────────────────────
SKELETON="$ANSIBLE_HOME/skeleton"
if [ ! -d "$SKELETON" ]; then
  echo "  Criando skeleton de projeto..."
  mkdir -p "$SKELETON"/{inventory,group_vars,host_vars,roles,playbooks}

  cat > "$SKELETON/inventory/hosts.ini" << 'INV'
# Inventário de exemplo

[webservers]
# web1 ansible_host=192.168.1.10

[dbservers]
# db1 ansible_host=192.168.1.20

[all:vars]
ansible_user=admin
ansible_python_interpreter=/usr/bin/python3
INV

  cat > "$SKELETON/playbooks/site.yml" << 'PLAY'
---
- name: Exemplo de playbook
  hosts: all
  become: true
  gather_facts: true

  tasks:
    - name: Ping nos hosts
      ansible.builtin.ping:

    - name: Atualizar cache do apt
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"
PLAY

  cat > "$SKELETON/ansible.cfg" << 'PROJCFG'
[defaults]
inventory = inventory/hosts.ini
roles_path = roles
host_key_checking = False
stdout_callback = yaml
PROJCFG
fi

# ─── Aliases ──────────────────────────────────────────────
ALIAS_FILE="$HOME/.ansible_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# Ansible aliases — gerado por dotfiles
# ─────────────────────────────────────────

alias a='ansible'
alias ap='ansible-playbook'
alias ag='ansible-galaxy'
alias av='ansible-vault'
alias adoc='ansible-doc'
alias alint='ansible-lint'

# Playbook com syntax check antes
ap-check() {
  ansible-playbook --syntax-check "$@" && \
  ansible-playbook --check "$@"
}

# Ping em todos os hosts
a-ping() {
  ansible "${1:-all}" -m ping
}

# Fatos de um host
a-facts() {
  if [ -z "$1" ]; then
    echo "Uso: a-facts <host>"
    return 1
  fi
  ansible "$1" -m setup
}

# Novo projeto a partir do skeleton
ansible-new() {
  if [ -z "$1" ]; then
    echo "Uso: ansible-new <nome>"
    return 1
  fi
  cp -r "$HOME/.ansible/skeleton" "$1"
  cd "$1" || return
  echo "Projeto Ansible criado em $1/"
}

# Comando ad-hoc rápido
a-run() {
  ansible "${1:-all}" -m shell -a "$2"
}
ALIASES

# ─── Source ───────────────────────────────────────────────
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "ansible_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# Ansible aliases" >> "$RC"
    echo "[ -f ~/.ansible_aliases ] && source ~/.ansible_aliases" >> "$RC"
  fi
done

echo ""
echo "Ansible instalado com sucesso!"
echo "  $(ansible --version 2>/dev/null | head -1)"
echo ""
echo "Configuração:"
echo "  ~/.ansible.cfg          config global (pipelining, fact cache)"
echo "  ~/.ansible/skeleton/    skeleton de projeto"
echo ""
echo "Aliases:"
echo "  a / ap / ag / av        ansible, playbook, galaxy, vault"
echo "  alint                   ansible-lint"
echo "  ap-check <playbook>     syntax-check + dry-run"
echo "  a-ping [grupo]          ping nos hosts"
echo "  a-facts <host>          fatos de um host"
echo "  ansible-new <nome>      novo projeto do skeleton"
echo "  a-run <grupo> '<cmd>'   comando ad-hoc"
