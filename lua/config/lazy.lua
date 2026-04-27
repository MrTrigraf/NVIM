-- ============================================================================
-- lua/config/lazy.lua
-- При первом запуске сам клонирует lazy.nvim (менеджер плагинов)
-- и настраивает его.
--
-- Зачем bootstrap: на свежей машине менеджера плагинов ещё нет.
-- Клонирование прямо отсюда делает конфиг самоустанавливающимся —
-- склонировал репо, запустил nvim, всё поднялось само.
-- ============================================================================

-- Путь, по которому будет жить lazy.nvim: ~/.local/share/nvim/lazy/lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- vim.uv (привязка к libuv) — современный API; vim.loop — старый алиас.
-- fs_stat возвращает nil, если путь не существует.
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    lazyrepo, lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

-- Добавляем lazy.nvim в runtimepath, чтобы заработал require("lazy").
-- runtimepath — это список директорий, где Neovim ищет плагины и модули.
vim.opt.rtp:prepend(lazypath)

-- Стартовая инициализация с пустым списком плагинов.
-- В Блоке 4 заменим `spec = {}` на `spec = { { import = "plugins" } }`
-- и начнём добавлять файлы в lua/plugins/.
require("lazy").setup({
  spec = {},
  install = {
    -- Запасная цветовая схема, используется во время первой установки,
    -- пока наша основная ещё не подгружена. habamax идёт в комплекте с Neovim.
    colorscheme = { "habamax" },
  },
  checker = {
    -- Не проверять обновления плагинов автоматически на каждом старте.
    -- Будем делать вручную через :Lazy update, когда сами захотим.
    enabled = false,
  },
})