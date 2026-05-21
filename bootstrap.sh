#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — развернуть Neovim-IDE для Go на чистой машине Arch Linux.
#
# Идемпотентно: можно запускать сколько угодно раз. Если что-то уже стоит —
# пропустит. Если посередине упало — запусти снова, продолжит.
#
# Что делает (6 этапов):
#   1. Sanity check (Arch ли это, не root ли запускает).
#   2. Backup существующего ~/.config/nvim (если он не наш репо).
#   3. Системные пакеты через pacman (Neovim, git, rg, fd, gcc, lazygit, Go, ...).
#   4. Go-инструменты через go install (dlv, air, gofumpt, goimports).
#   5. Клон/обновление репо ~/.config/nvim.
#   6. Headless установка плагинов (Lazy) и LSP-серверов (Mason).
#
# Использование:
#   ./bootstrap.sh
# =============================================================================

set -euo pipefail
# set -e — упасть на первой же ошибке (не игнорировать silent failures).
# set -u — упасть при использовании необъявленной переменной (защита от опечаток).
# set -o pipefail — если в pipeline x | y | z упало любое звено, весь pipeline = failed.

# -----------------------------------------------------------------------------
# Цветной вывод. Делает скрипт читаемым в большом потоке логов pacman.
# -----------------------------------------------------------------------------
COLOR_RESET='\033[0m'
COLOR_BLUE='\033[1;34m'
COLOR_GREEN='\033[1;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[1;31m'

step()    { echo -e "\n${COLOR_BLUE}==>${COLOR_RESET} ${COLOR_GREEN}$*${COLOR_RESET}"; }
info()    { echo -e "    $*"; }
warn()    { echo -e "${COLOR_YELLOW}WARN:${COLOR_RESET} $*"; }
fail()    { echo -e "${COLOR_RED}ERROR:${COLOR_RESET} $*" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Константы.
# -----------------------------------------------------------------------------
REPO_URL="https://github.com/MrTrigraf/NVIM.git"
REPO_DIR="$HOME/.config/nvim"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# Системные пакеты — всё, что ставится через pacman.
# Сгруппированы по назначению для читаемости.
SYSTEM_PACKAGES=(
  # Core
  neovim git curl unzip tar
  # Search & file tools
  ripgrep fd
  # Treesitter compilation
  tree-sitter-cli gcc make
  # Node-based LSP servers (yamlls, jsonls, ...)
  nodejs npm
  # Go (для gopls, dlv, air, gofumpt, goimports)
  go
  # TUI tools
  lazygit lazydocker
  # PostgreSQL client (для vim-dadbod)
  postgresql
  # Fonts
  ttf-jetbrains-mono-nerd noto-fonts-emoji
)

# Go-инструменты — то, что ставится через `go install` уже после Go.
GO_TOOLS=(
  "github.com/go-delve/delve/cmd/dlv@latest"
  "github.com/air-verse/air@latest"
  "mvdan.cc/gofumpt@latest"
  "golang.org/x/tools/cmd/goimports@latest"
)

# -----------------------------------------------------------------------------
# Этап 1. Sanity check.
# -----------------------------------------------------------------------------
step "Step 1/6: Sanity check"

if [[ "$EUID" -eq 0 ]]; then
  fail "Don't run as root. The script will ask for sudo when needed."
fi

if ! command -v pacman &>/dev/null; then
  fail "pacman not found. This script targets Arch Linux only."
fi

info "OK: Arch Linux, non-root user '$USER'."

# -----------------------------------------------------------------------------
# Этап 2. Backup существующего конфига.
# -----------------------------------------------------------------------------
step "Step 2/6: Backup existing Neovim config (if any)"

# Проверяем — не наш ли это уже репо. Если наш — backup не нужен, обновим позже.
backup_if_foreign() {
  local target="$1"
  if [[ ! -e "$target" ]]; then
    return 0
  fi
  # Если это симлинк на наш репо или каталог с нашим .git/config — пропускаем.
  if [[ -d "$target/.git" ]] && (cd "$target" && git remote get-url origin 2>/dev/null | grep -qE "MrTrigraf/NVIM(\.git)?$"); then
    info "Skip backup: $target is already our repo."
    return 0
  fi
  local backup="${target}.bak.${TIMESTAMP}"
  info "Moving $target → $backup"
  mv "$target" "$backup"
}

backup_if_foreign "$HOME/.config/nvim"
backup_if_foreign "$HOME/.local/share/nvim"
backup_if_foreign "$HOME/.local/state/nvim"
backup_if_foreign "$HOME/.cache/nvim"

# -----------------------------------------------------------------------------
# Этап 3. Системные пакеты.
# -----------------------------------------------------------------------------
step "Step 3/6: Install system packages via pacman"

info "Packages: ${SYSTEM_PACKAGES[*]}"
# --needed: пропустить пакеты, которые уже установлены той же версией или новее.
# --noconfirm НЕ ставим: pacman должен спросить пароль и подтверждение,
# это безопаснее, чем молча накатывать всё подряд.
sudo pacman -S --needed "${SYSTEM_PACKAGES[@]}"

# -----------------------------------------------------------------------------
# Этап 4. Go-инструменты.
# -----------------------------------------------------------------------------
step "Step 4/6: Install Go tools (dlv, air, gofumpt, goimports)"

if ! command -v go &>/dev/null; then
  fail "go not in PATH. Something went wrong on step 3."
fi

# Проверяем, что $GOPATH/bin (обычно ~/go/bin) есть в PATH.
# Иначе после установки go install бинарники окажутся "в никуда".
GOBIN="$(go env GOPATH)/bin"
if [[ ":$PATH:" != *":$GOBIN:"* ]]; then
  warn "$GOBIN is NOT in your PATH."
  warn "Add this line to your shell config (~/.bashrc, ~/.config/fish/config.fish, etc.):"
  warn "    set -gx PATH \$PATH $GOBIN     # fish"
  warn "    export PATH=\"\$PATH:$GOBIN\"  # bash/zsh"
fi

for tool in "${GO_TOOLS[@]}"; do
  info "go install $tool"
  go install "$tool"
done

# -----------------------------------------------------------------------------
# Этап 5. Клонирование / обновление репо.
# -----------------------------------------------------------------------------
step "Step 5/6: Clone or update the Neovim config repo"

if [[ -d "$REPO_DIR/.git" ]]; then
  info "Repo already exists at $REPO_DIR — pulling latest."
  git -C "$REPO_DIR" pull --ff-only
else
  info "Cloning $REPO_URL → $REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR"
fi

# -----------------------------------------------------------------------------
# Этап 6. Плагины (Lazy) + LSP/линтеры/форматтеры (Mason).
# -----------------------------------------------------------------------------
step "Step 6/6: Install plugins (Lazy) and LSP servers (Mason)"

info "Running Lazy sync — this will download all plugins (~30-60 sec)."
# Используем Lua-API напрямую с wait=true — это блокирует Neovim
# до полного завершения установки. Просто "+Lazy! sync +qa" не годится:
# Lazy ставит плагины асинхронно, и при +qa процесс может оборваться
# до того, как mason-tool-installer успеет зарегистрировать свои команды.
nvim --headless +"lua require('lazy').sync({ wait = true, show = false })" +qa

info "Running Mason — installing LSP servers, linters, formatters (~1-2 min)."
# MasonToolsInstallSync — команда от mason-tool-installer, ставит ВСЁ
# из ensure_installed в нашем lsp.lua, синхронно (ждёт завершения).
# Теперь команда гарантированно зарегистрирована (см. выше).
nvim --headless "+MasonToolsInstallSync" +qa

# -----------------------------------------------------------------------------
# Финал.
# -----------------------------------------------------------------------------
step "Done!"
echo -e "${COLOR_GREEN}Everything installed.${COLOR_RESET}"
echo
echo "Next steps:"
echo "  1. Open Neovim:    nvim"
echo "  2. Verify health:  :checkhealth"
echo "  3. Read shortcuts: cat ~/.config/nvim/NVIM_CHEATSHEET.md"
echo