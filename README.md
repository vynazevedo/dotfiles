<!-- ANSI Shadow Font -->
```
 ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
 ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
 ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
 ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
 ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
 ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
```

<div align="center">

```
 ┌──────────────────────────────────────────────────────────────┐
 │  "The quieter you become, the more you are able to hear."   │
 │                                          — Kali Linux       │
 └──────────────────────────────────────────────────────────────┘
```

[![ShellCheck](https://github.com/vynazevedo/dotfiles/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/vynazevedo/dotfiles/actions/workflows/shellcheck.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/vynazevedo/dotfiles?style=social)](https://github.com/vynazevedo/dotfiles/stargazers)

[![Shell Script](https://img.shields.io/badge/Shell_Script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=green)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Kali](https://img.shields.io/badge/Kali_Linux-557C94?style=for-the-badge&logo=kalilinux&logoColor=white)](https://www.kali.org/)

**30+ scripts to turn any Linux box into a productivity machine.** 🇬🇧

**30+ scripts para transformar qualquer Linux numa máquina de guerra.** 🇧🇷

*Tested on Ubuntu 22.04+ / 24.04+, Kali Linux & WSL2.*

---

</div>

```
 ╔═══════════════════════════════════════════════════════╗
 ║                    T A B L E                          ║
 ║                 O F  C O N T E N T S                  ║
 ╠═══════════════════════════════════════════════════════╣
 ║                                                       ║
 ║  [0x01] .... Quick Install                            ║
 ║  [0x02] .... Estrutura do projeto                     ║
 ║  [0x03] .... Shell & Terminal                         ║
 ║  [0x04] .... Editor & Multiplexer                     ║
 ║  [0x05] .... Linguagens & Runtime                     ║
 ║  [0x06] .... DevOps & Containers                      ║
 ║  [0x07] .... Segurança & Hardening                    ║
 ║  [0x08] .... Rede & Pentest                           ║
 ║  [0x09] .... Utilitários                              ║
 ║  [0x0A] .... Compatibilidade                          ║
 ║  [0x0B] .... Contribuindo                             ║
 ║                                                       ║
 ╚═══════════════════════════════════════════════════════╝
```

---

## `[0x01]` Quick Install

Cada script roda direto via `curl` — instale só o que precisar:

```bash
URL="https://raw.githubusercontent.com/vynazevedo/dotfiles/main"
```

```
 ┌─ SHELL & TERMINAL ───────────────────────────────────────────────────────┐
 │                                                                           │
 │  bash <(curl -fsSL $URL/scripts/git-boost.sh)              # git aliases         │
 │  bash <(curl -fsSL $URL/scripts/zsh.sh)                    # zsh + p10k + tools  │
 │  bash <(curl -fsSL $URL/scripts/aliases-extra.sh)   # aliases produtivos  │
 │                                                                           │
 ├─ EDITOR & MULTIPLEXER ──────────────────────────────────────────────────┤
 │                                                                           │
 │  bash <(curl -fsSL $URL/scripts/neovim.sh)          # neovim + plugins   │
 │  bash <(curl -fsSL $URL/scripts/tmux.sh)            # tmux + config      │
 │                                                                           │
 ├─ LINGUAGENS ─────────────────────────────────────────────────────────────┤
 │                                                                           │
 │  bash <(curl -fsSL $URL/scripts/mise.sh)            # version manager universal│
 │  bash <(curl -fsSL $URL/scripts/node.sh)            # NVM + Node LTS     │
 │  bash <(curl -fsSL $URL/scripts/bun-deno.sh)        # Bun + Deno         │
 │  bash <(curl -fsSL $URL/scripts/golang.sh)          # Go + tools         │
 │  bash <(curl -fsSL $URL/scripts/rust.sh)            # Rust + cargo tools │
 │  bash <(curl -fsSL $URL/scripts/python.sh)          # pyenv + Python     │
 │                                                                           │
 ├─ DEVOPS & CLOUD ─────────────────────────────────────────────────────────┤
 │                                                                           │
 │  bash <(curl -fsSL $URL/scripts/docker.sh)          # Docker CE + aliases│
 │  bash <(curl -fsSL $URL/scripts/k8s.sh)             # kubectl + helm + k9s│
 │  bash <(curl -fsSL $URL/scripts/terraform.sh)       # Terraform + tflint │
 │  bash <(curl -fsSL $URL/scripts/ansible.sh)         # Ansible + lint     │
 │  bash <(curl -fsSL $URL/scripts/cloud-cli.sh)       # AWS + GCP + Azure  │
 │  bash <(curl -fsSL $URL/scripts/network-tools.sh)   # ferramentas rede   │
 │                                                                           │
 ├─ SEGURANÇA ──────────────────────────────────────────────────────────────┤
 │                                                                           │
 │  bash <(curl -fsSL $URL/scripts/ssh-hardening.sh)   # SSH hardening      │
 │  bash <(curl -fsSL $URL/scripts/firewall.sh)        # UFW setup          │
 │  bash <(curl -fsSL $URL/scripts/fail2ban.sh)        # anti brute force   │
 │  bash <(curl -fsSL $URL/scripts/sysctl.sh)          # kernel tuning      │
 │  bash <(curl -fsSL $URL/scripts/pentest.sh)         # toolkit pentest    │
 │  bash <(curl -fsSL $URL/scripts/gpg-yubikey.sh)     # GPG + YubiKey      │
 │  bash <(curl -fsSL $URL/scripts/wazuh.sh)           # Wazuh SIEM agent   │
 │  bash <(curl -fsSL $URL/scripts/yara.sh)            # YARA + rule sets   │
 │                                                                           │
 ├─ PRIVACIDADE & REDE ─────────────────────────────────────────────────────┤
 │                                                                           │
 │  bash <(curl -fsSL $URL/scripts/tor.sh)             # Tor + obfs4        │
 │  bash <(curl -fsSL $URL/scripts/pi-hole.sh)         # Pi-hole + unbound  │
 │                                                                           │
 ├─ UTILITÁRIOS ────────────────────────────────────────────────────────────┤
 │                                                                           │
 │  bash <(curl -fsSL $URL/scripts/security-audit.sh)  # audit de segurança │
 │  bash <(curl -fsSL $URL/scripts/system-info.sh)     # dashboard sistema  │
 │  bash <(curl -fsSL $URL/scripts/cleanup.sh)         # limpeza sistema    │
 │  bash <(curl -fsSL $URL/scripts/backup.sh)          # backup configs     │
 │  bash <(curl -fsSL $URL/scripts/wsl.sh)             # otimizações WSL2   │
 │                                                                           │
 └───────────────────────────────────────────────────────────────────────────┘
```

Ou clone o repo:

```bash
git clone https://github.com/vynazevedo/dotfiles.git
```

---

## `[0x02]` Estrutura do projeto

```
dotfiles/
└── scripts/
    ├── git-boost.sh         # git aliases & config
    ├── zsh.sh               # zsh + oh-my-zsh + p10k
    ├── neovim.sh            # neovim + lazy.nvim + LSP
    ├── tmux.sh              # tmux + TPM + tema hacker
    ├── mise.sh              # version manager universal
    ├── node.sh              # NVM + Node.js LTS + tools
    ├── bun-deno.sh          # Bun + Deno (runtimes JS modernos)
    ├── golang.sh            # Go + ferramentas
    ├── rust.sh              # Rust + cargo tools
    ├── python.sh            # pyenv + Python + tools
    ├── docker.sh            # docker CE + aliases
    ├── k8s.sh               # kubectl + helm + k9s + kubectx
    ├── terraform.sh         # Terraform + tflint + trivy
    ├── ansible.sh           # Ansible + lint + skeleton
    ├── cloud-cli.sh         # AWS + GCP + Azure CLIs
    ├── ssh-hardening.sh     # hardening do SSH server
    ├── firewall.sh          # UFW com profiles
    ├── fail2ban.sh          # proteção brute force
    ├── sysctl.sh            # kernel tuning
    ├── network-tools.sh     # ferramentas de rede
    ├── pentest.sh           # toolkit de pentest
    ├── aliases-extra.sh     # aliases de produtividade
    ├── wsl.sh               # otimizações WSL2
    ├── security-audit.sh    # auditoria de segurança
    ├── gpg-yubikey.sh       # GPG + YubiKey + signed commits
    ├── wazuh.sh             # Wazuh SIEM agent
    ├── yara.sh              # YARA + rule sets curados
    ├── tor.sh               # Tor + torsocks + obfs4
    ├── pi-hole.sh           # Pi-hole + unbound DNS
    ├── system-info.sh       # dashboard do sistema
    ├── cleanup.sh           # limpeza do sistema
    └── backup.sh            # backup de configs
```

---

## `[0x03]` Shell & Terminal

### git-boost.sh

> *Git aliases para quem não tem tempo a perder.*

```
 ┌─ COMMIT ──────────────────────────────────────────────┐
 │  git c  "msg"    commit -m                             │
 │  git ca "msg"    add . + commit -m                     │
 │  git amend       adiciona ao último commit             │
 │  git reword      edita mensagem do último commit       │
 │  git squash N    squash dos últimos N commits          │
 ├─ PUSH / PULL ─────────────────────────────────────────┤
 │  git p           push                                  │
 │  git pf          push --force-with-lease               │
 │  git pu          push -u origin <branch atual>         │
 │  git up          pull --rebase --autostash             │
 ├─ BRANCH ──────────────────────────────────────────────┤
 │  git b / recent  branch / ordenar por data             │
 │  git co / cob    checkout / checkout -b                │
 │  git sw / swc    switch / switch -c                    │
 │  git cleanup     remove branches mergeadas             │
 ├─ STATUS / LOG ────────────────────────────────────────┤
 │  git s           status resumido                       │
 │  git l / ll      log graph (20 / all)                  │
 ├─ OUTROS ──────────────────────────────────────────────┤
 │  git ss / sp     stash / stash pop                     │
 │  git d / ds      diff / diff --staged                  │
 │  git undo        desfaz último commit                  │
 │  git blame       blame detalhado (-w -C -C -C)        │
 └────────────────────────────────────────────────────────┘
```

### zsh.sh

> *De terminal padrão pra cockpit de nave em um comando.*

Instala Zsh + Oh My Zsh + Powerlevel10k (tema hacker) + plugins (syntax-highlighting, autosuggestions, completions) + ferramentas CLI (lsd, bat, btop, fastfetch) + JetBrainsMono Nerd Font.

Usa **bloco gerenciado** no `.zshrc` — suas customizações são preservadas.

### aliases-extra.sh

> *50+ atalhos e funções para o dia a dia.*

```
 ┌─ DESTAQUES ───────────────────────────────────────────┐
 │  extract <file>     extrair qualquer formato           │
 │  compress <dir>     comprimir diretório                │
 │  mkcd <dir>         criar e entrar no diretório        │
 │  genpass [len]      gerar senha segura                 │
 │  cheat <cmd>        cheat sheet do comando             │
 │  weather [city]     previsão do tempo                  │
 │  serve [port]       HTTP server rápido                 │
 │  calc <expr>        calculadora                        │
 │  note <texto>       notas rápidas                      │
 │  jwt <token>        decodificar JWT                    │
 │  b64encode/decode   Base64                             │
 │  urlencode/decode   URL encoding                       │
 │  psmem / pscpu      top processos por mem/CPU          │
 │  hg <text>          buscar no histórico                │
 └────────────────────────────────────────────────────────┘
```

---

## `[0x04]` Editor & Multiplexer

### neovim.sh

> *IDE no terminal com um único script.*

```
 ┌─ O QUE INSTALA ───────────────────────────────────────┐
 │                                                        │
 │  Plugin Manager ... lazy.nvim                          │
 │  Tema ............ tokyonight (transparente)           │
 │  Fuzzy finder .... telescope                           │
 │  Syntax .......... treesitter (17 linguagens)          │
 │  LSP ............. mason + lspconfig                   │
 │  Autocomplete .... nvim-cmp + luasnip                  │
 │  Git ............. gitsigns                            │
 │  Extras .......... autopairs, comment, surround,       │
 │                    which-key, indent-blankline          │
 │                                                        │
 ├─ KEYBINDINGS (leader = Space) ────────────────────────┤
 │                                                        │
 │  <leader>ff    buscar arquivos                         │
 │  <leader>fg    buscar texto (grep)                     │
 │  <leader>fb    listar buffers                          │
 │  <leader>e     file explorer                           │
 │  <leader>w     salvar                                  │
 │  gd / gr       go to definition / references           │
 │  K             hover docs                              │
 │  <leader>rn    rename                                  │
 │  <leader>ca    code action                             │
 │                                                        │
 └────────────────────────────────────────────────────────┘
```

### tmux.sh

> *Múltiplos terminais, uma tela.*

```
 ┌─ KEYBINDINGS (prefix = Ctrl+A) ──────────────────────┐
 │                                                        │
 │  |           split horizontal                          │
 │  -           split vertical                            │
 │  h/j/k/l     navegar panes (vim-style)                │
 │  H/J/K/L     resize panes                             │
 │  Shift+←/→   navegar janelas                           │
 │  Enter       copy mode (vi)                            │
 │  r           reload config                             │
 │  S           nova session                              │
 │                                                        │
 │  Plugins: sensible, resurrect, continuum, yank         │
 │                                                        │
 └────────────────────────────────────────────────────────┘
```

---

## `[0x05]` Linguagens & Runtime

```
 ┌─ NODE.JS ─────────────────────────────────────────────┐
 │  NVM + Node LTS + typescript, tsx, eslint, prettier,   │
 │  nodemon, pm2, http-server, tldr                       │
 ├─ GO ──────────────────────────────────────────────────┤
 │  Última versão estável + gopls, dlv, golangci-lint,    │
 │  air (live reload), swag, gotestsum                    │
 ├─ RUST ────────────────────────────────────────────────┤
 │  rustup + stable + rustfmt, clippy, rust-analyzer      │
 │  cargo-watch, cargo-edit, cargo-audit, cargo-nextest,  │
 │  bacon, tokei, hyperfine, zoxide, du-dust, procs       │
 ├─ PYTHON ──────────────────────────────────────────────┤
 │  pyenv + latest Python 3 + ruff, black, mypy, poetry,  │
 │  httpie, ipython, pre-commit, cookiecutter             │
 └────────────────────────────────────────────────────────┘
```

```bash
bash <(curl -fsSL $URL/scripts/node.sh)
bash <(curl -fsSL $URL/scripts/golang.sh)
bash <(curl -fsSL $URL/scripts/rust.sh)
bash <(curl -fsSL $URL/scripts/python.sh)
```

---

## `[0x06]` DevOps & Containers

### docker.sh

> *Docker CE + o melhor set de aliases que existe.*

```
 ┌─ ALIASES DOCKER ──────────────────────────────────────┐
 │                                                        │
 │  CONTAINERS         COMPOSE          CLEANUP           │
 │  dps   (running)    dc  (compose)    dprune (tudo)     │
 │  dpsa  (all)        dcu (up -d)      drmi   (images)   │
 │  dex   (exec -it)   dcd (down)       drm    (stopped)  │
 │  dsh   (shell)      dcr (restart)    dvol   (volumes)  │
 │  dl    (logs)       dcl (logs -f)                      │
 │  dip   (IP)         dcp (pull)                         │
 │  dtop  (stats)      dcb (build)                        │
 │  dstopall           dce (exec)                         │
 │                                                        │
 └────────────────────────────────────────────────────────┘
```

---

## `[0x07]` Segurança & Hardening

### ssh-hardening.sh

```
 ┌─ O QUE FAZ ───────────────────────────────────────────┐
 │                                                        │
 │  ✗ Root login via SSH                                  │
 │  ✗ Password authentication                             │
 │  ✗ X11 / TCP forwarding                               │
 │  ✓ Apenas chaves ED25519                               │
 │  ✓ Ciphers modernos (chacha20, aes-gcm)               │
 │  ✓ Max 3 tentativas                                    │
 │  ✓ Timeout 5 min                                       │
 │  ✓ Gera chave ED25519 + config do cliente              │
 │                                                        │
 └────────────────────────────────────────────────────────┘
```

### firewall.sh

```
 ┌─ PROFILES ────────────────────────────────────────────┐
 │                                                        │
 │  1) minimal    SSH only (rate-limited)                 │
 │  2) webserver  SSH + HTTP + HTTPS                      │
 │  3) dev        + portas dev (3000,5173,8080,5432,6379) │
 │  4) custom     escolha manual                          │
 │                                                        │
 └────────────────────────────────────────────────────────┘
```

### fail2ban.sh

Proteção automática contra brute force no SSH (e nginx/apache opcionais). Ban progressivo: 3h no SSH, 24h para DDoS.

### sysctl.sh

```
 ┌─ PROFILES ────────────────────────────────────────────┐
 │                                                        │
 │  1) desktop   swap=10, BBR, inotify alto, Docker ok    │
 │  2) server    + mais conexões, port range, ARP cache   │
 │  3) hardened  ASLR=2, no forwarding, dmesg restrito,   │
 │               ptrace restrito, no core dumps            │
 │                                                        │
 └────────────────────────────────────────────────────────┘
```

### security-audit.sh

> *Scan completo de segurança do sistema com score.*

Verifica: usuários, SSH, firewall, portas abertas, filesystem (SUID, permissões), kernel (ASLR, syncookies), serviços desnecessários. Output colorido com PASS/WARN/FAIL e score percentual.

```bash
bash <(curl -fsSL $URL/scripts/security-audit.sh)
```

---

## `[0x08]` Rede & Pentest

### network-tools.sh

```
 ┌─ FERRAMENTAS ─────────────────────────────────────────┐
 │  nmap, netcat, tcpdump, tshark, masscan, mtr,          │
 │  traceroute, iperf3, socat, jq, httpie                 │
 ├─ ALIASES ─────────────────────────────────────────────┤
 │  myip / localip / ips    info de IP                    │
 │  ports / listening       portas abertas                │
 │  quickscan <subnet>      host discovery                │
 │  portscan <host>         scan + versão                 │
 │  scanlocal               scan rede local               │
 │  certinfo <host>         info SSL cert                 │
 │  dnsall <host>           todos registros DNS           │
 │  whichip <ip>            info do IP (ipinfo.io)        │
 │  trace <host>            traceroute visual             │
 │  sniff / sniffhttp       tcpdump rápido                │
 └────────────────────────────────────────────────────────┘
```

### pentest.sh

> *As ferramentas do Kali em qualquer Ubuntu.*

```
 ┌─ TOOLKIT ─────────────────────────────────────────────┐
 │                                                        │
 │  RECON ......... nmap, gobuster, nikto, enum4linux     │
 │  EXPLOIT ....... sqlmap, hydra, john, hashcat          │
 │  WIRELESS ...... aircrack-ng                           │
 │  AD ............ bloodhound, crackmapexec, responder,  │
 │                  impacket, evil-winrm                   │
 │  POST-EXPLOIT .. linpeas, pspy                         │
 │  WORDLISTS ..... rockyou, seclists                     │
 │                                                        │
 ├─ ALIASES ─────────────────────────────────────────────┤
 │  nmapfull <ip>      scan completo                      │
 │  nmapvuln <ip>      scan de vulns                      │
 │  dirscan <url>      directory bruteforce               │
 │  webscan <url>      nikto scan                         │
 │  listener <port>    nc listener                        │
 │  tun0               IP da VPN (HTB/THM)                │
 │                                                        │
 └────────────────────────────────────────────────────────┘
```

---

## `[0x09]` Utilitários

```
 ┌─ SCRIPTS ─────────────────────────────────────────────┐
 │                                                        │
 │  --info       Dashboard do sistema (CPU, RAM, disco,   │
 │               rede, serviços, toolchain, segurança)    │
 │               com barras de progresso coloridas         │
 │                                                        │
 │  --cleanup    Limpa APT cache, kernels antigos, logs,  │
 │               thumbnails, lixeira, snaps, tmp files    │
 │               + cleanup Docker opcional                │
 │                                                        │
 │  --backup     Backup de dotfiles, configs do sistema,  │
 │               lista de pacotes (apt/pip/npm/cargo),    │
 │               crontab. Suporta restore.                │
 │               Uso: bash scripts/backup.sh               │
 │               Ou:  bash scripts/backup.sh [dotfiles|   │
 │                    full|configs|custom|restore]         │
 │                                                        │
 │  --wsl        Otimizações para WSL2: wsl.conf,         │
 │               .wslconfig, DNS fix, aliases (clipboard, │
 │               explorer, VS Code)                       │
 │                                                        │
 └────────────────────────────────────────────────────────┘
```

---

## `[0x0A]` Compatibilidade

```
 DISTRO              VERSÃO       STATUS
 ──────              ──────       ──────
 Ubuntu              22.04 LTS    ✔ testado
 Ubuntu              24.04 LTS    ✔ testado
 Kali Linux          2024.x+      ✔ testado
 Debian              12+          ✔ compatível
 WSL2 (Ubuntu)       qualquer     ✔ testado
```

```
 ARCH                STATUS
 ────                ──────
 amd64 (x86_64)     ✔ testado
 arm64 (aarch64)    ✔ suportado
```

---

## `[0x0B]` Contribuindo

```
 1. Fork o repo
 2. Crie uma branch (git swc minha-feature)
 3. Commit (git c "add: minha feature")
 4. Push (git pu)
 5. Abre um PR
```

PRs com novos scripts, fixes ou melhorias são bem-vindos.

---

<div align="center">

```
 ┌──────────────────────────────────────────────────────────────┐
 │                                                              │
 │   "Talk is cheap. Show me the code." — Linus Torvalds       │
 │                                                              │
 └──────────────────────────────────────────────────────────────┘
```

**[@vynazevedo](https://github.com/vynazevedo)**

</div>
