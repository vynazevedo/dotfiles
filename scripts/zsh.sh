#!/usr/bin/env bash
# ─────────────────────────────────────────
# zsh-boost.sh
# Zsh + Oh My Zsh + Powerlevel10k setup
# Suporta: Ubuntu 22.04+, Ubuntu 24.04+, Kali Linux
# Author: Vinicius Azevedo <github.com/vynazevedo>
# ─────────────────────────────────────────

set -e

echo "zsh-boost — configurando terminal..."

# ─── Detecção de distro e arquitetura ────────────────────
if [ -f /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  DISTRO_ID="${ID}"
else
  echo "Erro: /etc/os-release não encontrado."
  echo "Este script suporta apenas Ubuntu e Kali Linux."
  exit 1
fi

ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")

case "$DISTRO_ID" in
  ubuntu|kali|debian)
    echo "  Distro detectada: ${PRETTY_NAME}"
    echo "  Arquitetura: ${ARCH}"
    ;;
  *)
    echo "Aviso: distro '${DISTRO_ID}' não testada. Continuando mesmo assim..."
    ;;
esac

has_native_pkg() {
  apt-cache show "$1" &>/dev/null 2>&1
}

# ─── Dependências ──────────────────────────────────────────
echo ""
echo "Instalando dependências..."
sudo apt update -q
sudo apt install -y zsh curl git unzip fontconfig

# ─── Oh My Zsh ────────────────────────────────────────────
echo ""
echo "Instalando Oh My Zsh..."

if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "  Oh My Zsh já instalado, pulando..."
else
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ─── Powerlevel10k ────────────────────────────────────────
echo ""
echo "Instalando Powerlevel10k..."

if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  echo "  Powerlevel10k já instalado, pulando..."
else
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# ─── Plugins ──────────────────────────────────────────────
echo ""
echo "Instalando plugins..."

declare -A PLUGINS=(
  [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions.git"
  [zsh-completions]="https://github.com/zsh-users/zsh-completions.git"
)

for plugin in "${!PLUGINS[@]}"; do
  if [ -d "$ZSH_CUSTOM/plugins/$plugin" ]; then
    echo "  $plugin já instalado, pulando..."
  else
    git clone "${PLUGINS[$plugin]}" "$ZSH_CUSTOM/plugins/$plugin"
  fi
done

# ─── Ferramentas visuais ──────────────────────────────────
echo ""
echo "Instalando ferramentas..."

# btop
if command -v btop &>/dev/null; then
  echo "  btop já instalado, pulando..."
else
  sudo apt install -y btop
fi

# bat
if command -v bat &>/dev/null || command -v batcat &>/dev/null; then
  echo "  bat já instalado, pulando..."
else
  sudo apt install -y bat 2>/dev/null || sudo apt install -y batcat 2>/dev/null || true
fi
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
  mkdir -p ~/.local/bin
  ln -sf "$(command -v batcat)" ~/.local/bin/bat
fi

# lsd
echo "  Instalando lsd..."
if command -v lsd &>/dev/null; then
  echo "  lsd já instalado, pulando..."
elif has_native_pkg lsd; then
  sudo apt install -y lsd
else
  LSD_VERSION=$(curl -s https://api.github.com/repos/lsd-rs/lsd/releases/latest \
    | grep tag_name | cut -d'"' -f4)
  LSD_DEB="lsd_${LSD_VERSION#v}_${ARCH}.deb"
  curl -fsSL "https://github.com/lsd-rs/lsd/releases/latest/download/${LSD_DEB}" \
    -o "/tmp/${LSD_DEB}"
  sudo dpkg -i "/tmp/${LSD_DEB}"
  rm -f "/tmp/${LSD_DEB}"
fi

# fastfetch
echo "  Instalando fastfetch..."
if command -v fastfetch &>/dev/null; then
  echo "  fastfetch já instalado, pulando..."
elif has_native_pkg fastfetch; then
  sudo apt install -y fastfetch
elif [ "$DISTRO_ID" = "ubuntu" ]; then
  sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch 2>/dev/null || true
  sudo apt update -q
  sudo apt install -y fastfetch
else
  echo "  Aviso: fastfetch não disponível nos repositórios. Pulando..."
fi

# ─── Nerd Font (JetBrainsMono) ────────────────────────────
echo ""
echo "Instalando JetBrainsMono Nerd Font..."

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

if fc-list | grep -qi "JetBrainsMono"; then
  echo "  JetBrainsMono já instalada, pulando..."
else
  TMP=$(mktemp -d)
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
    -o "$TMP/JetBrainsMono.zip"
  unzip -q "$TMP/JetBrainsMono.zip" -d "$FONT_DIR"
  fc-cache -fv > /dev/null
  rm -rf "$TMP"
  echo "  JetBrainsMono Nerd Font instalada!"
fi

# ─── .zshrc (bloco gerenciado) ────────────────────────────
echo ""
echo "Configurando .zshrc..."

ZSHRC="$HOME/.zshrc"
MARKER_BEGIN="# >>> zsh-boost managed block >>>"
MARKER_END="# <<< zsh-boost managed block <<<"

touch "$ZSHRC"

if [ -f "$ZSHRC" ] && [ -s "$ZSHRC" ]; then
  cp "$ZSHRC" "$ZSHRC.backup.$(date +%Y%m%d%H%M%S)"
  echo "  Backup salvo em $ZSHRC.backup.*"
fi

MANAGED_BLOCK=$(cat << 'BLOCK'
# ─────────────────────────────────────────
# .zshrc — bloco gerenciado por zsh-boost.sh
# Não edite entre os marcadores.
# Suas customizações vão ABAIXO do bloco.
# ─────────────────────────────────────────

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
  zsh-completions
  docker
  npm
  golang
)

source $ZSH/oh-my-zsh.sh

# ─── Aliases ──────────────────────────────────────────────

# Navegação
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# ls (lsd se disponível)
if command -v lsd &>/dev/null; then
  alias ls='lsd'
  alias ll='lsd -la'
  alias lt='lsd --tree'
else
  alias ll='ls -la --color=auto'
fi

# bat — descomente para substituir cat por bat
# if command -v bat &>/dev/null; then
#   alias cat='bat'
# fi

# top
if command -v btop &>/dev/null; then
  alias top='btop'
fi

# Git rápido
alias g='git'
alias gs='git s'
alias gl='git l'

# Sistema
alias update='sudo apt update && sudo apt upgrade -y'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me'
alias path='echo $PATH | tr ":" "\n"'
alias reload='source ~/.zshrc'
alias zshrc='${EDITOR:-nano} ~/.zshrc'

# Dev
alias py='python3'
alias serve='python3 -m http.server'

# ─── Exports ──────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
export LANG=en_US.UTF-8

# ─── Histórico ────────────────────────────────────────────
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ─── Autosuggestions ──────────────────────────────────────
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ─── Powerlevel10k config ─────────────────────────────────
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ─── Fastfetch no início ──────────────────────────────────
# Descomente para mostrar info do sistema ao abrir o terminal
# fastfetch
BLOCK
)

if grep -q "$MARKER_BEGIN" "$ZSHRC" 2>/dev/null; then
  sed -i "/$MARKER_BEGIN/,/$MARKER_END/d" "$ZSHRC"
fi

{
  echo "$MARKER_BEGIN"
  echo "$MANAGED_BLOCK"
  echo "$MARKER_END"
  echo ""
  cat "$ZSHRC"
} > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"

echo "  .zshrc configurado (bloco gerenciado inserido)"

# ─── Powerlevel10k hacker config ─────────────────────────
echo ""
echo "Aplicando tema hacker no Powerlevel10k..."

[ -f "$HOME/.p10k.zsh" ] && cp "$HOME/.p10k.zsh" "$HOME/.p10k.zsh.backup.$(date +%Y%m%d%H%M%S)"

cat > "$HOME/.p10k.zsh" << 'P10K'
# Gerado por zsh-boost.sh — tema hacker

'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  autoload -Uz is-at-least && is-at-least 5.1 || return

  # Segmentos da esquerda
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    dir
    vcs
    newline
    prompt_char
  )

  # Segmentos da direita
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status
    command_execution_time
    background_jobs
    node_version
    go_version
    python_version
    time
  )

  # Geral
  typeset -g POWERLEVEL9K_MODE=nerdfont-complete
  typeset -g POWERLEVEL9K_ICON_PADDING=moderate
  typeset -g POWERLEVEL9K_BACKGROUND=                   # transparente
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  # Prompt char — verde se ok, vermelho se erro
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=076
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='>'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=false

  # Diretório — verde neon
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=076
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER=
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=040
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=076
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true

  # Git — cores hacker
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=076
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=220
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=196
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND=196
  typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND=240

  typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0
  typeset -g POWERLEVEL9K_VCS_{STAGED,UNSTAGED,UNTRACKED,CONFLICTED,COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=-1

  typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_COLOR=076
  typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)

  # Status
  typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=076
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=196
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=196

  # Tempo de execução — só mostra se > 3s
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=101
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'

  # Jobs em background
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=076

  # Node
  typeset -g POWERLEVEL9K_NODE_VERSION_FOREGROUND=070
  typeset -g POWERLEVEL9K_NODE_VERSION_PROJECT_ONLY=true

  # Go
  typeset -g POWERLEVEL9K_GO_VERSION_FOREGROUND=039
  typeset -g POWERLEVEL9K_GO_VERSION_PROJECT_ONLY=true

  # Python
  typeset -g POWERLEVEL9K_PYTHON_VERSION_FOREGROUND=039
  typeset -g POWERLEVEL9K_PYTHON_VERSION_PROJECT_ONLY=true

  # Hora — discreta
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=240
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'
  typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=false

  # Instant prompt
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

  (( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
} always {
  'builtin' 'unset' 'p10k_config_opts'
}
P10K

echo "  .p10k.zsh gerado!"

# ─── Shell padrão ─────────────────────────────────────────
echo ""
echo "Definindo Zsh como shell padrão..."
sudo usermod -s "$(command -v zsh)" "$USER"

# ─── Summary ──────────────────────────────────────────────
echo ""
echo "zsh-boost instalado com sucesso!"
echo ""
echo "O que foi instalado:"
echo "  - Zsh + Oh My Zsh"
echo "  - Powerlevel10k (tema hacker pré-configurado)"
echo "  - zsh-syntax-highlighting"
echo "  - zsh-autosuggestions"
echo "  - zsh-completions"
echo "  - btop, lsd, bat, fastfetch"
echo "  - JetBrainsMono Nerd Font"
echo ""
echo "Próximos passos:"
echo "  1. Configure a fonte 'JetBrainsMono Nerd Font' no seu terminal"
echo "  2. Rode: exec zsh"
echo ""
echo "  Para ajustar o tema: p10k configure"
echo "  Para ativar o fastfetch: descomente a linha no final do ~/.zshrc"
echo "  Para alias cat=bat: descomente a linha no bloco gerenciado do ~/.zshrc"
