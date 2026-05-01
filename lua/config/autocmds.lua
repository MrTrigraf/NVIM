-- ============================================================================
-- lua/config/autocmds.lua
-- Автокоманды — реакции на события Neovim.
--
-- Шпаргалка:
--   vim.api.nvim_create_autocmd(events, opts)
--     events — строка или список событий ("BufWritePre", {"BufRead", ...}).
--     opts.pattern — фильтр по имени файла или filetype ("*.go", "yaml").
--     opts.callback — Lua-функция, выполняемая при событии.
--     opts.command — альтернатива callback: команда Vim в виде строки.
--     opts.group — группа автокоманд (важно для идемпотентности при reload).
-- ============================================================================

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Все наши автокоманды кладём в одну группу с clear = true.
-- Это значит: при каждой загрузке файла группа сначала ОЧИЩАЕТСЯ, затем
-- автокоманды регистрируются заново. Без этого после <leader>R автокоманды
-- регистрировались бы повторно, и одно событие срабатывало бы 2-3-N раз.
local group = augroup("user_autocmds", { clear = true })

-- ──────────────────────────────────────────────────────────────────────
-- Подсветка скопированного текста (yank highlight)
-- ──────────────────────────────────────────────────────────────────────
-- Когда копируешь yy/y — на 200мс подсвечивается то, что взято в
-- регистр. Видно, что именно скопировал, без угадывания.
-- В VS Code похоже на короткую вспышку выделения после Ctrl+C.
autocmd("TextYankPost", {
  group = group,
  desc = "Highlight yanked text",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- ──────────────────────────────────────────────────────────────────────
-- Восстановление позиции курсора при открытии файла
-- ──────────────────────────────────────────────────────────────────────
-- Когда снова открываешь файл, который уже редактировал, курсор
-- ставится туда, где ты его оставил в прошлый раз. Очень удобно.
-- Исключения: коммит-сообщения git и xxd-дампы — там старая позиция
-- бессмысленна.
autocmd("BufReadPost", {
  group = group,
  desc = "Restore last cursor position",
  callback = function(args)
    local exclude = { "gitcommit", "gitrebase", "xxd" }
    local buf = args.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- ──────────────────────────────────────────────────────────────────────
-- Отступы для конкретных файлтайпов
-- ──────────────────────────────────────────────────────────────────────
-- В options.lua глобально стоит expandtab=false (для Go — табы).
-- Но YAML, JSON, Lua, Markdown, Dockerfile, fish — все они
-- предпочитают пробелы, и YAML вообще ломается на табах.
-- Здесь точечно переключаем эти языки на пробелы.
autocmd("FileType", {
  group = group,
  desc = "Use spaces for specific filetypes",
  pattern = {
    "yaml", "yml",
    "json", "jsonc",
    "lua",
    "markdown",
    "dockerfile",
    "fish",
    "sh", "bash",
    "toml",
    "html", "css", "scss",
  },
  callback = function()
    vim.bo.expandtab = true
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.softtabstop = 2
  end,
})

-- Go-файлы — наоборот, явно фиксируем табы и ширину 4. Дублирует
-- глобальные опции, но защищает на случай если что-то их перебьёт.
autocmd("FileType", {
  group = group,
  desc = "Use tabs for Go files",
  pattern = "go",
  callback = function()
    vim.bo.expandtab = false
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.softtabstop = 4
  end,
})

-- ──────────────────────────────────────────────────────────────────────
-- Удаление пробелов в конце строк при сохранении
-- ──────────────────────────────────────────────────────────────────────
-- Перед записью файла на диск Neovim прогоняет команду :%s — она
-- находит все пробелы в конце строк и удаляет их. Чисто косметика,
-- но git-diff'ы чище.
-- Исключаем markdown — там два пробела в конце строки означают
-- перенос строки, это синтаксис языка.
autocmd("BufWritePre", {
  group = group,
  desc = "Trim trailing whitespace on save",
  callback = function()
    if vim.bo.filetype == "markdown" then
      return
    end
    local save = vim.fn.winsaveview()
    vim.cmd([[silent! %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- ──────────────────────────────────────────────────────────────────────
-- Авто-создание директорий при сохранении
-- ──────────────────────────────────────────────────────────────────────
-- Если сохраняешь файл по пути, в котором ещё нет всех родительских
-- папок — Neovim создаст их автоматически. Без этой автокоманды
-- ":w foo/bar/baz.txt" сразу падает с ошибкой E212.
autocmd("BufWritePre", {
  group = group,
  desc = "Auto-create parent directories on save",
  callback = function(args)
    if args.match:match("^%w%w+:[\\/][\\/]") then
      -- Это URL (oil://, fugitive:// и т.п.), пропускаем.
      return
    end
    local file = vim.uv.fs_realpath(args.match) or args.match
    local dir = vim.fn.fnamemodify(file, ":p:h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})

-- ──────────────────────────────────────────────────────────────────────
-- Автоматическое выравнивание сплитов при изменении размера окна
-- ──────────────────────────────────────────────────────────────────────
-- Когда меняешь размер kitty/терминала — открытые сплиты по умолчанию
-- остаются с прежними пропорциями, и часть их может уехать за экран.
-- Эта команда говорит "перерасчитай всё равномерно".
autocmd("VimResized", {
  group = group,
  desc = "Equalize splits on terminal resize",
  command = "tabdo wincmd =",
})

-- ──────────────────────────────────────────────────────────────────────
-- Автоматический вход в Insert-режим при открытии терминала
-- ──────────────────────────────────────────────────────────────────────
-- Когда открываешь :terminal или плагин-терминал, курсор по умолчанию
-- появляется в Normal-режиме (надо жать i). Делаем сразу Insert.
-- Также убираем номера строк и signcolumn — в терминале они мешают.
autocmd("TermOpen", {
  group = group,
  desc = "Tweak terminal buffers",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.cmd("startinsert")
  end,
})

-- ──────────────────────────────────────────────────────────────────────
-- Закрытие "вспомогательных" окон по q
-- ──────────────────────────────────────────────────────────────────────
-- В Neovim есть тип буферов "help", "qf" (quickfix), вывод checkhealth
-- и ряд других — это окна-просмотровщики, не файлы. По умолчанию из
-- них надо выходить через :q. Делаем удобнее: одна клавиша q закроет.
autocmd("FileType", {
  group = group,
  desc = "Close helper windows with q",
  pattern = {
        "help", "man", "qf", "checkhealth", "lspinfo", "notify",
    "startuptime", "tsplayground", "PlenaryTestPopup", "neotest-output",
    "neotest-summary", "neotest-output-panel",
    "snacks_dashboard", 
  },
  callback = function(args)
    vim.bo[args.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", {
      buffer = args.buf,
      silent = true,
      desc = "Close window",
    })
  end,
})

-- Авто-открытие/обновление neo-tree при смене корня проекта
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("auto_open_neotree", { clear = true }),
  callback = function(args)
    local buftype = vim.bo[args.buf].buftype
    if buftype ~= "" then return end

    local bufname = vim.api.nvim_buf_get_name(args.buf)
    if bufname == "" or vim.fn.filereadable(bufname) ~= 1 then return end

    local root = vim.fs.root(bufname, {
      ".git", "go.mod", "package.json", "Cargo.toml", "pyproject.toml", "Makefile",
    }) or vim.fn.fnamemodify(bufname, ":h")

    if vim.fn.getcwd() == root then return end

    vim.schedule(function()
      vim.cmd("tcd " .. vim.fn.fnameescape(root))

      local manager = require("neo-tree.sources.manager")
      pcall(manager.close_all)

      require("neo-tree.command").execute({
        action   = "show",
        source   = "filesystem",
        position = "left",
        dir      = root,
        reveal   = false,
      })

      vim.cmd("wincmd p")
    end)
  end,
})