<a id="top"></a>

<!-- ============================================================
     Language switcher (заглушка под будущую EN-версию).
     README.en.md пока не создан — ссылка ведёт в 404.
     Когда добавишь EN-версию, файл появится по этому пути и
     ссылка заработает автоматически.
     ============================================================ -->

<sub>🇷🇺 **Русский** &middot; [🇬🇧 English](README.en.md)</sub>

<!-- ============================================================
     SHAPKA (centered).
     ============================================================ -->

<div align="center">

# 🥷 NVIM

**Лично собранная IDE для Go-бэкенда на Neovim** &middot;
LSP, debug, тесты, HTTP, PostgreSQL, lazygit, lazydocker — всё под одной крышей.

![Neovim](https://img.shields.io/badge/Neovim-0.11+-57A143?logo=neovim&logoColor=white)
![Lua](https://img.shields.io/badge/Lua-5.1-2C2D72?logo=lua&logoColor=white)
![Go](https://img.shields.io/badge/Go-1.26-00ADD8?logo=go&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-Arch-1793D1?logo=arch-linux&logoColor=white)

<br>

<!-- ============================================================
     SCREENSHOT #0 (hero) — Dashboard.
     ============================================================ -->

![Главный экран — Dashboard](assets/screenshots/00-dashboard.png)

<sub><i>Стартовый экран при запуске <code>nvim</code> без аргументов: ASCII-логотип, закреплённые проекты.</i></sub>

</div>

---

## 📑 Оглавление

- [Скриншоты](#скриншоты)
- [Что внутри](#что-внутри)
- [Требования](#требования)
- [Установка](#установка)
- [Раскладка клавиш](#раскладка-клавиш)
- [Структура проекта](#структура-проекта)
- [Troubleshooting](#troubleshooting)

---

<a id="скриншоты"></a>
## 📸 Скриншоты

<!-- ============================================================
     GALERY 3x2 на HTML-таблице — единственный способ
     получить две колонки в Markdown на GitHub.
     6 ячеек = 6 скриншотов.
     ============================================================ -->

<table>
<tr>
  <td width="50%" valign="top">
    <!-- SCREENSHOT #1 — Coding (Go + LSP) -->
    <img src="assets/screenshots/01-coding.png" alt="Coding: Go + LSP" />
    <p align="center"><sub><i>Go-файл: completion с docstring, inlay hints, diagnostics, treesitter-подсветка.</i></sub></p>
  </td>
  <td width="50%" valign="top">
    <!-- SCREENSHOT #2 — Debug (nvim-dap-ui) -->
    <img src="assets/screenshots/02-debug.png" alt="Debug: nvim-dap-ui" />
    <p align="center"><sub><i>Отладка через Delve: variables, call stack, watch, REPL, stop-on-breakpoint.</i></sub></p>
  </td>
</tr>
<tr>
  <td width="50%" valign="top">
    <!-- SCREENSHOT #3 — Testing (neotest) -->
    <img src="assets/screenshots/03-testing.png" alt="Testing: neotest" />
    <p align="center"><sub><i>neotest summary справа, статусы тестов в gutter, можно дебажить тест прямо отсюда.</i></sub></p>
  </td>
  <td width="50%" valign="top">
    <!-- SCREENSHOT #4 — Search (telescope live_grep) -->
    <img src="assets/screenshots/04-search.png" alt="Search: telescope live_grep" />
    <p align="center"><sub><i>Telescope live_grep: fuzzy-поиск по содержимому файлов, превью с подсветкой совпадения справа.</i></sub></p>
  </td>
</tr>
<tr>
  <td width="50%" valign="top">
    <!-- SCREENSHOT #5 — HTTP (kulala) -->
    <img src="assets/screenshots/05-http.png" alt="HTTP: kulala.nvim" />
    <p align="center"><sub><i>kulala.nvim: запрос в <code>.http</code>-файле, ответ — справа. JetBrains HTTP Client прямо в редакторе.</i></sub></p>
  </td>
  <td width="50%" valign="top">
    <!-- SCREENSHOT #6 — Database (vim-dadbod-ui) -->
    <img src="assets/screenshots/06-db.png" alt="DB: vim-dadbod-ui" />
    <p align="center"><sub><i>vim-dadbod-ui: PostgreSQL подключение, дерево схемы, SQL с автодополнением, таблица результата.</i></sub></p>
  </td>
</tr>
</table>

<sub><a href="#top">⬆ Наверх</a></sub>

---

<a id="что-внутри"></a>
## ✨ Что внутри

Полнофункциональная IDE для Go-разработки. Цель — догнать GoLand и VS Code по возможностям, оставаясь быстрым, прозрачным и полностью под контролем.

### Языковая интеллектика
- **LSP**: `gopls`, `yaml-language-server` (+ SchemaStore), `json-lsp`, `taplo`, `dockerfile-language-server`, `docker-compose-language-service`, `lua-language-server`, `bash-language-server`, `marksman`
- **Diagnostics**: real-time подчёркивания ошибок, плавающее окно при наведении, workspace-список через `trouble.nvim`
- **Inlay hints**, **code lens**, **semantic tokens**, **signature help** — всё включено
- **Completion**: `blink.cmp` (Rust fuzzy) + `LuaSnip` + `friendly-snippets`
- **Formatting on save**: `conform.nvim` → `gofumpt` + `goimports`
- **Linting**: `nvim-lint` → `golangci-lint` (Go) + `hadolint` (Docker)

### Workflows
- **Debug**: `nvim-dap` + `nvim-dap-go` + `nvim-dap-ui` — breakpoints, variables, call stack, REPL, watch
- **Testing**: `neotest` + `neotest-golang` — запуск ближайшего теста, файла, всего пакета, debug-режим
- **Git**: `gitsigns.nvim` + `lazygit` (плавающий) + `diffview.nvim`
- **Docker**: `lazydocker` в плавающем терминале
- **HTTP-клиент**: `kulala.nvim` — исполнение `.http`-файлов прямо из редактора (как JetBrains HTTP Client)
- **База данных**: `vim-dadbod` + UI + completion — PostgreSQL подключения, SQL с автодополнением таблиц/колонок
- **Hot reload**: `air` запускается в именованном терминале (`<leader>Ta`)

### Навигация и UI
- **Picker**: `telescope.nvim` + `fzf-native` (Rust)
- **File explorer**: `neo-tree.nvim` v3
- **Pinned files**: `harpoon.nvim` — прыжки между ключевыми файлами проекта
- **Symbol outline**: `aerial.nvim`
- **Folding**: `nvim-ufo` (treesitter/LSP-aware)
- **Find & replace**: `grug-far.nvim` (regex, preview, selective apply)
- **Sessions**: `persistence.nvim` — авто-сохранение/восстановление по проекту
- **Workspaces**: `workspaces.nvim` + кастомный pinned-projects-меню в дашборде

### Внешний вид
- **Colorscheme**: `kanagawa-paper` (ink, transparent)
- **Statusline**: `lualine.nvim`
- **Treesitter**: 34 парсера (Go, YAML, JSON, TOML, Docker, Markdown, SQL, HTTP, ...)
- **Icons**: `nvim-web-devicons` + `mini.icons` (требуется Nerd Font)
- **Indent guides**: `indent-blankline.nvim`
- **TODO highlight**: `todo-comments.nvim`
- **Color preview**: `nvim-colorizer.lua` (квадратик слева от hex-кода)
- **Markdown render**: `render-markdown.nvim` (как в Obsidian)
- **Smooth scroll**: `snacks.scroll`
- **Dashboard, notifier, input**: `snacks.nvim`

<sub><a href="#top">⬆ Наверх</a></sub>

---

<a id="требования"></a>
## 🛠 Требования

### Минимум

| Что | Версия | Зачем |
|---|---|---|
| **Neovim** | `≥ 0.11` (рекомендуется 0.12+) | Используется `vim.lsp.config()` / `vim.lsp.enable()` (API 0.11+) |
| **Git** | любая свежая | Lazy.nvim клонирует плагины |
| **Nerd Font** | JetBrainsMono Nerd Font v3+ | Иконки в дашборде, neo-tree, lualine |
| **ripgrep** (`rg`) | любая | Telescope live_grep, grug-far |
| **fd** | любая | Telescope find_files |
| **gcc** + **make** | base-devel | Сборка treesitter-парсеров и jsregexp |
| **tree-sitter-cli** | любая | Treesitter (ветка `main`) |
| **curl**, **unzip**, **tar** | системные | Mason скачивает LSP-серверы |
| **node** + **npm** | актуальная | Часть LSP-серверов (yamlls, jsonls) на Node |
| **Go** | `≥ 1.21` | `gopls`, `gofumpt`, `goimports`, `dlv`, `air` |

### Для дополнительных фич

| Что | Зачем |
|---|---|
| **lazygit** | git-workflow (`<leader>gg`) |
| **lazydocker** | docker-workflow (`<leader>D`) |
| **psql** (PostgreSQL client) | подключения через `vim-dadbod` |
| **air** | hot-reload (`<leader>Ta`) |
| **delve** (`dlv`) | debug Go-кода |
| **noto-fonts-emoji** | цветные emoji в `:checkhealth` |

<sub><a href="#top">⬆ Наверх</a></sub>

---

<a id="установка"></a>
## 🚀 Установка

### Автоматическая (Arch Linux)

```fish
git clone https://github.com/MrTrigraf/NVIM.git ~/.config/nvim
cd ~/.config/nvim
./bootstrap.sh
```

`bootstrap.sh` идемпотентен — поставит системные пакеты через `pacman`, Go-инструменты через `go install`, скачает все плагины и LSP-серверы. Подробности — внутри скрипта.

> Если у тебя настроен SSH-ключ для GitHub — можно использовать `git@github.com:MrTrigraf/NVIM.git` вместо HTTPS-URL.

### Ручная (любой Linux/macOS)

**1. Системные зависимости** (для Arch — пример; для другого дистрибутива замени на свой менеджер пакетов):

```fish
sudo pacman -S --needed neovim git ripgrep fd tree-sitter-cli \
                       lazygit lazydocker postgresql nodejs npm \
                       gcc make unzip curl noto-fonts-emoji \
                       ttf-jetbrains-mono-nerd
```

**2. Go-инструменты** (попадут в `~/go/bin` — добавь его в `$PATH`):

```fish
go install github.com/go-delve/delve/cmd/dlv@latest
go install github.com/air-verse/air@latest
go install mvdan.cc/gofumpt@latest
go install golang.org/x/tools/cmd/goimports@latest
```

**3. Бэкап существующего конфига Neovim** (если есть):

```fish
mv ~/.config/nvim ~/.config/nvim.bak.(date +%Y%m%d)
mv ~/.local/share/nvim ~/.local/share/nvim.bak.(date +%Y%m%d)
mv ~/.local/state/nvim ~/.local/state/nvim.bak.(date +%Y%m%d)
mv ~/.cache/nvim ~/.cache/nvim.bak.(date +%Y%m%d)
```

**4. Клонирование и первый запуск**:

```fish
git clone https://github.com/MrTrigraf/NVIM.git ~/.config/nvim
nvim --headless "+Lazy! sync" +qa
nvim --headless "+MasonInstallAll" +qa
```

Первый запуск займёт 1–3 минуты: lazy.nvim скачает все плагины, treesitter скомпилирует парсеры, mason скачает LSP-серверы и линтеры.

**5. Открой Neovim:**

```fish
nvim
```

Должен открыться дашборд. Если выскакивают ошибки — см. [Troubleshooting](#troubleshooting).

<sub><a href="#top">⬆ Наверх</a></sub>

---

<a id="раскладка-клавиш"></a>
## ⌨️ Раскладка клавиш

**Leader-клавиша** — `<Space>` (пробел).

Ниже — выжимка самых частых клавиш. Полную раскладку (~250 биндингов) см. в [NVIM_CHEATSHEET.md](NVIM_CHEATSHEET.md).

### Базовое

| Клавиша | Действие | VS Code |
|---|---|---|
| `<Space>ff` | Найти файл | `Ctrl+P` |
| `<Space>fg` | Live grep по проекту | `Ctrl+Shift+F` |
| `<Space>fb` | Переключить буфер | `Ctrl+Tab` |
| `<Space>e` | Открыть/закрыть neo-tree | `Ctrl+B` |
| `<Space>sr` | Find & replace (grug-far) | `Ctrl+Shift+H` |
| `<Space>cs` | Symbol outline (aerial) | `Ctrl+Shift+O` |
| `<Space>cf` | Форматировать буфер | `Shift+Alt+F` |

### LSP

| Клавиша | Действие |
|---|---|
| `gd` | Go to definition |
| `gr` | References |
| `gI` | Implementation |
| `K` | Hover documentation |
| `<C-k>` (Insert) | Signature popup |
| `<Space>la` | Code action |
| `<Space>lr` | Rename symbol |
| `<Space>li` | Toggle inlay hints |
| `]d` / `[d` | Следующий / предыдущий диагностик |

### Debug

| Клавиша | Действие |
|---|---|
| `<Space>db` | Toggle breakpoint |
| `<Space>dc` | Continue |
| `<Space>do` | Step over |
| `<Space>di` | Step into |
| `<Space>du` | Toggle dap-ui |

### Testing

| Клавиша | Действие |
|---|---|
| `<Space>tt` | Test nearest |
| `<Space>tf` | Test file |
| `<Space>ta` | Test all |
| `<Space>td` | Debug test |
| `<Space>tp` | Toggle summary |

### Terminal

| Клавиша | Действие |
|---|---|
| `<C-/>` | Toggle terminal (shell) |
| `<Space>Tf` | Floating terminal |
| `<Space>Ta` | term-watch + auto-air |
| `<Esc><Esc>` | Выйти из terminal-режима |

### Git / Docker

| Клавиша | Действие |
|---|---|
| `<Space>gg` | Lazygit (плавающий) |
| `<Space>gd` | Diffview |
| `<Space>D` | Lazydocker (плавающий) |
| `]h` / `[h` | Следующий / предыдущий hunk |

### HTTP & Database

| Клавиша | Действие |
|---|---|
| `<Space>rr` | Run HTTP request (kulala, в `.http`) |
| `<Space>Bb` | Toggle dadbod-ui |
| `<Space>Bf` | Find buffer (dadbod) |

### Sessions

| Клавиша | Действие |
|---|---|
| `<Space>qq` | Закрыть окно |
| `<Space>qs` | Restore session (текущий проект) |
| `<Space>ql` | Restore last session |

<sub><a href="#top">⬆ Наверх</a></sub>

---

<a id="структура-проекта"></a>
## 📁 Структура проекта

```
~/.config/nvim/
├── init.lua                          точка входа, leader = <Space>
├── lazy-lock.json                    зафиксированные версии плагинов
├── lua/
│   ├── config/
│   │   ├── lazy.lua                  bootstrap lazy.nvim
│   │   ├── options.lua               vim.opt.* (undofile, clipboard, ...)
│   │   ├── keymaps.lua               глобальные биндинги
│   │   ├── autocmds.lua              автокоманды (yank highlight, cursor restore, ...)
│   │   ├── diagnostics.lua           vim.diagnostic.config
│   │   └── filetypes.lua             vim.filetype.add
│   ├── plugins/
│   │   ├── colorscheme.lua           kanagawa-paper
│   │   ├── ui.lua                    lualine + which-key + icons
│   │   ├── dashboard.lua             snacks.dashboard + notifier
│   │   ├── editor.lua                indent-blankline + todo-comments + mini.pairs
│   │   ├── visuals.lua               nvim-colorizer + render-markdown
│   │   ├── explorer.lua              neo-tree
│   │   ├── picker.lua                telescope + fzf-native
│   │   ├── navigation.lua            aerial + ufo + harpoon + statuscol
│   │   ├── search-replace.lua        grug-far
│   │   ├── lsp.lua                   mason + lspconfig + signature + fidget
│   │   ├── completion.lua            blink.cmp + LuaSnip
│   │   ├── formatting.lua            conform.nvim
│   │   ├── linting.lua               nvim-lint
│   │   ├── trouble.lua               trouble.nvim
│   │   ├── terminal.lua              snacks.terminal
│   │   ├── git.lua                   gitsigns + lazygit + diffview
│   │   ├── docker.lua                lazydocker
│   │   ├── dap.lua                   nvim-dap + dap-go + dap-ui
│   │   ├── neotest.lua               neotest + neotest-golang
│   │   ├── http.lua                  kulala
│   │   ├── db.lua                    vim-dadbod + ui + completion
│   │   ├── session.lua               persistence.nvim
│   │   └── workspaces.lua            workspaces.nvim
│   └── util/                         вспомогательные модули (workspaces, pinned, ...)
├── assets/
│   └── screenshots/                  скриншоты для README
├── README.md                         этот файл
├── NVIM_CHEATSHEET.md                полная шпаргалка по клавишам
├── bootstrap.sh                      скрипт первой установки
└── .gitignore
```

<sub><a href="#top">⬆ Наверх</a></sub>

---

<a id="troubleshooting"></a>
## 🩺 Troubleshooting

### Общая диагностика

```vim
:checkhealth
```

Открывает большой отчёт о состоянии Neovim и всех плагинов. Жёлтые `WARN` — обычно информационные, красные `ERROR` — требуют внимания.

### Проблемы с плагинами

```vim
:Lazy
```

— главный экран lazy.nvim. На нём видно: какие плагины загружены, какие нет, есть ли ошибки. Полезные команды:

- `:Lazy sync` — обновить все плагины и применить изменения lockfile
- `:Lazy update` — обновить плагины и записать новые версии в lockfile
- `:Lazy restore` — откатиться к версиям из lockfile
- `:Lazy clean` — удалить плагины, которых больше нет в конфиге
- `:Lazy log <plugin>` — git-лог изменений конкретного плагина

### LSP не работает

```vim
:checkhealth vim.lsp
:Mason
```

Mason-окно показывает, какие серверы установлены и в каком статусе. Если сервера нет — `i` (install) на нужном.

### Конкретный плагин ломает редактор

Самый быстрый способ изолировать проблему — запустить Neovim без конфига:

```fish
nvim --clean
```

Если в `--clean` всё работает — дело в конфиге. Потом по бинарному поиску отключаешь плагины в `lua/plugins/*.lua` (`enabled = false` в спеке), перезапускаешь, проверяешь.

### Полный сброс

```fish
rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
nvim --headless "+Lazy! sync" +qa
```

Удаляет всё, что lazy и mason скачали; конфиг (`~/.config/nvim`) остаётся. При следующем запуске всё переустановится.

<sub><a href="#top">⬆ Наверх</a></sub>

---