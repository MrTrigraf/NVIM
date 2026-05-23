#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — развернуть Neovim-IDE для Go на чистой машине Arch Linux.
#
# Идемпотентно: можно запускать сколько угодно раз. Если что-то уже стоит —
# пропустит. Если посередине упало — запусти снова, продолжит.
#
# Что делает (7 этапов):
#   1. Sanity check (Arch ли это, не root ли запускает).
#   2. Backup существующего ~/.config/nvim (если он не наш репо).
#   3. Системные пакеты через pacman (Neovim, git, rg, fd, gcc, lazygit,
#      Go, Docker, ...).
#   4. Docker setup (группа + автозапуск socket).
#   5. Go-инструменты через go install (dlv, air, gofumpt, goimports,
#      migrate с тегом postgres).
#   6. Клон/обновление репо ~/.config/nvim.
#   7. Headless установка плагинов (Lazy) и LSP-серверов (Mason).
#
# Использование:
#   ./bootstrap.sh
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Цветной вывод.
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

# Флаги для финального вывода.
RELOGIN_NEEDED=0

# Системные пакеты.
SYSTEM_PACKAGES=(
  # Core
  neovim git curl unzip tar
  # Search & file tools
  ripgrep fd
  # Treesitter compilation
  tree-sitter-cli gcc make
  # Node-based LSP servers (yamlls, jsonls, ...)
  nodejs npm
  # Go (для gopls, dlv, air, gofumpt, goimports, migrate)
  go
  # Docker — демон + CLI + compose v2 (отдельный пакет на Arch)
  docker docker-compose
  # TUI tools
  lazygit lazydocker
  # PostgreSQL client (для vim-dadbod)
  postgresql
  # Fonts
  ttf-jetbrains-mono-nerd noto-fonts-emoji
)

# Go-инструменты — простые, без build tags.
GO_TOOLS=(
  "github.com/go-delve/delve/cmd/dlv@latest"
  "github.com/air-verse/air@latest"
  "mvdan.cc/gofumpt@latest"
  "golang.org/x/tools/cmd/goimports@latest"
)

# -----------------------------------------------------------------------------
# Этап 1. Sanity check.
# -----------------------------------------------------------------------------
step "Step 1/7: Sanity check"

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
step "Step 2/7: Backup existing Neovim config (if any)"

backup_if_foreign() {
  local target="$1"
  if [[ ! -e "$target" ]]; then
    return 0
  fi
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
step "Step 3/7: Install system packages via pacman"

info "Packages: ${SYSTEM_PACKAGES[*]}"
sudo pacman -S --needed "${SYSTEM_PACKAGES[@]}"

# -----------------------------------------------------------------------------
# Этап 4. Docker setup.
# -----------------------------------------------------------------------------
step "Step 4/7: Docker setup (group + autostart)"

# 4.1. Группа docker. На Arch пакет docker обычно создаёт её сам через
#      systemd-sysusers, но подстраховываемся.
if getent group docker >/dev/null; then
  info "Group 'docker' already exists, skipping creation"
else
  info "Creating 'docker' group"
  sudo groupadd docker
fi

# 4.2. Добавляем пользователя в группу. usermod -aG идемпотентен по факту,
#      но проверяем явно, чтобы не дёргать sudo лишний раз и понимать,
#      нужен ли релогин.
if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
  info "User '$USER' already in 'docker' group"
else
  info "Adding '$USER' to 'docker' group (effective after re-login)"
  sudo usermod -aG docker "$USER"
  RELOGIN_NEEDED=1
fi

# 4.3. Автозапуск через docker.socket — ленивый, демон стартует при первом
#      обращении к /var/run/docker.sock. systemctl enable сам идемпотентен:
#      повторный вызов не создаёт второго симлинка.
info "Enabling docker.socket (lazy autostart)"
sudo systemctl enable docker.socket

# -----------------------------------------------------------------------------
# Этап 5. Go-инструменты.
# -----------------------------------------------------------------------------
step "Step 5/7: Install Go tools (dlv, air, gofumpt, goimports, migrate)"

if ! command -v go &>/dev/null; then
  fail "go not in PATH. Something went wrong on step 3."
fi

# Проверяем, что $GOPATH/bin есть в PATH.
GOBIN="$(go env GOPATH)/bin"

# 5.1. Простые тулзы без build tags.
for tool in "${GO_TOOLS[@]}"; do
  info "go install $tool"
  go install "$tool"
done

# 5.2. migrate — нужен -tags 'postgres', иначе бинарь соберётся без драйвера
#      и не сможет подключиться к Postgres. Без тега команда работает, но
#      на любую попытку open даёт "unknown driver".
info "go install -tags 'postgres' migrate@latest"
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# 5.3. PATH для fish — fish-native способ через универсальную переменную.
#      `set -U fish_user_paths` пишет в ~/.config/fish/fish_variables,
#      переменная живёт между сессиями. Используем `contains ...; or set ...`
#      чтобы не дублировать запись при повторных запусках.
#      ВАЖНО: одинарные кавычки вокруг `fish -c`, чтобы bash не раскрыл
#      $HOME и $fish_user_paths — это работа fish-а.
if command -v fish &>/dev/null; then
  info "Ensuring $GOBIN is in fish's universal PATH"
  fish -c 'contains $HOME/go/bin $fish_user_paths; or set -U fish_user_paths $HOME/go/bin $fish_user_paths'
elif [[ ":$PATH:" != *":$GOBIN:"* ]]; then
  warn "$GOBIN is NOT in your PATH (and fish not detected)."
  warn "Add to your shell config:"
  warn "    export PATH=\"\$PATH:$GOBIN\"   # bash/zsh"
fi

# -----------------------------------------------------------------------------
# Этап 6. Клонирование / обновление репо.
# -----------------------------------------------------------------------------
step "Step 6/7: Clone or update the Neovim config repo"

if [[ -d "$REPO_DIR/.git" ]]; then
  info "Repo already exists at $REPO_DIR — pulling latest."
  git -C "$REPO_DIR" pull --ff-only
else
  info "Cloning $REPO_URL → $REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR"
fi

# -----------------------------------------------------------------------------
# Этап 7. Плагины (Lazy) + LSP/линтеры/форматтеры (Mason).
# -----------------------------------------------------------------------------
step "Step 7/7: Install plugins (Lazy) and LSP servers (Mason)"

info "Running Lazy sync — this will download all plugins (~30-60 sec)."
nvim --headless +"lua require('lazy').sync({ wait = true, show = false })" +qa

info "Running Mason — installing LSP servers, linters, formatters (~1-2 min)."
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
echo "Verify migrate:"
echo "  migrate -version            # should print a version"
echo
echo "Verify Docker (after re-login):"
echo "  docker run --rm hello-world"
echo "  lazydocker                  # TUI overview"

if [[ "$RELOGIN_NEEDED" -eq 1 ]]; then
  echo
  echo -e "${COLOR_YELLOW}IMPORTANT:${COLOR_RESET} You were just added to the 'docker' group."
  echo "  Re-login (or run 'newgrp docker' in this shell) for it to take effect."
  echo "  Until then, 'docker ps' will fail with 'permission denied'."
fi