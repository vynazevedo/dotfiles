#!/usr/bin/env bash
# ─────────────────────────────────────────
# git-boost.sh
# Git aliases & productivity shortcuts
# Author: Vinicius Azevedo <github.com/vynazevedo>
# ─────────────────────────────────────────

set -e

echo "git-boost — configurando aliases de produtividade..."

# ─── Identidade ───────────────────────────────────────────
GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -z "$GIT_NAME" ]; then
  read -rp "Seu nome: " GIT_NAME
  git config --global user.name "$GIT_NAME"
fi

if [ -z "$GIT_EMAIL" ]; then
  read -rp "Seu e-mail: " GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
fi

# ─── Configurações gerais ─────────────────────────────────
if ! git config --global core.editor &>/dev/null; then
  git config --global core.editor "nano"
fi
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global color.ui auto
git config --global rebase.autostash true

# ─── Commit ───────────────────────────────────────────────
git config --global alias.c      'commit -m'
git config --global alias.ca     '!git add . && git commit -m'
git config --global alias.cm     'commit -m'
git config --global alias.amend  'commit --amend --no-edit'
git config --global alias.reword 'commit --amend'
git config --global alias.squash '!f(){ if [ -z "$1" ] || ! [ "$1" -ge 1 ] 2>/dev/null; then echo "Uso: git squash <N> (N >= 1)"; return 1; fi; git reset --soft HEAD~"$1"; }; f'

# ─── Push / Pull ──────────────────────────────────────────
git config --global alias.p      'push'
git config --global alias.pf     'push --force-with-lease'
git config --global alias.pu     '!git push -u origin $(git branch --show-current)'
git config --global alias.up     'pull --rebase --autostash'

# ─── Status / Log ─────────────────────────────────────────
git config --global alias.s      'status --short --branch'
git config --global alias.l      'log --oneline --graph --decorate -20'
git config --global alias.ll     'log --oneline --graph --decorate --all'

# ─── Branch ───────────────────────────────────────────────
git config --global alias.b      'branch'
git config --global alias.recent 'branch --sort=-committerdate'
git config --global alias.co     'checkout'
git config --global alias.cob    'checkout -b'
git config --global alias.sw     'switch'
git config --global alias.swc    'switch -c'
git config --global alias.cleanup '!git branch --merged | grep -v main | grep -v master | grep -v "\\*" | xargs git branch -d'

# ─── Stash ────────────────────────────────────────────────
git config --global alias.ss     'stash'
git config --global alias.sp     'stash pop'

# ─── Diff ─────────────────────────────────────────────────
git config --global alias.d      'diff'
git config --global alias.ds     'diff --staged'
git config --global alias.bdiff  '!f(){ git diff "$1".."$2" -- "$3"; }; f'

# ─── Utilitários ──────────────────────────────────────────
git config --global alias.undo   'reset HEAD~1 --mixed'
git config --global alias.blame  'blame -w -C -C -C'

# ─── Summary ──────────────────────────────────────────────
echo ""
echo "git-boost instalado com sucesso!"
echo ""
echo "Aliases disponíveis:"
echo ""
echo "  COMMIT"
echo "  git c \"msg\"        → commit -m"
echo "  git ca \"msg\"       → add . + commit -m"
echo "  git cm \"msg\"       → commit -m"
echo "  git amend          → adiciona ao último commit"
echo "  git reword         → edita mensagem do último commit"
echo "  git squash <N>     → squash dos últimos N commits"
echo ""
echo "  PUSH / PULL"
echo "  git p              → push"
echo "  git pf             → push --force-with-lease"
echo "  git pu             → push -u origin <branch atual>"
echo "  git up             → pull --rebase --autostash"
echo ""
echo "  STATUS / LOG"
echo "  git s              → status resumido com branch"
echo "  git l              → log visual (-20)"
echo "  git ll             → log visual (todas branches)"
echo ""
echo "  BRANCH"
echo "  git b              → branch"
echo "  git recent         → branches por data"
echo "  git co <branch>    → checkout"
echo "  git cob <branch>   → checkout -b"
echo "  git sw <branch>    → switch"
echo "  git swc <branch>   → switch -c"
echo "  git cleanup        → remove branches mergeadas"
echo ""
echo "  STASH"
echo "  git ss             → stash"
echo "  git sp             → stash pop"
echo ""
echo "  DIFF"
echo "  git d              → diff"
echo "  git ds             → diff --staged"
echo "  git bdiff b1 b2 f  → diff de arquivo entre branches"
echo ""
echo "  UTILS"
echo "  git undo           → desfaz último commit"
echo "  git blame          → blame detalhado"
