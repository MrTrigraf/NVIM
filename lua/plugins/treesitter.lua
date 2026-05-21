-- ============================================================================
-- lua/plugins/treesitter.lua
-- Treesitter — современная подсветка синтаксиса через парсинг кода в AST.
-- Также даёт текстовые объекты для редактирования (vaf, vif, etc).
--
-- ВАЖНО: используем ВЕТКУ `main`, не `master`. В Neovim 0.12 ядро ввело
-- новый decoration provider `conceal_line`, и старая ветка master падает
-- на любом файле с predicate `(#set! "conceal_lines" "")` — это видно как
-- ошибка `attempt to call method 'range' (a nil value)` в :messages.
--
-- Ветка `main` — это будущий v1.0 nvim-treesitter, с переписанным API:
--   - нет таблицы opts с `ensure_installed`/`highlight.enable`/`indent`;
--   - парсеры ставятся через `require("nvim-treesitter").install({...})`;
--   - подсветка/индент включаются АВТОКОМАНДОЙ FileType, не в setup'е.
--   - ТРЕБУЕТСЯ системный CLI `tree-sitter` в PATH
--     (pacman -S tree-sitter-cli).
-- ============================================================================

return {
  -- =========================================================================
  -- nvim-treesitter (ветка main — будущий v1.0)
  -- =========================================================================
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false, -- грузим сразу, чтобы FileType-автокоманда успела
                  -- зарегистрироваться до открытия первого файла
    build = ":TSUpdate",
    cmd = { "TSUpdate", "TSInstall", "TSInstallInfo", "TSUpdateSync" },

    config = function()
      -- Список нужных парсеров.
      -- ПРИМЕЧАНИЕ: jsonc (JSON с комментариями) пока не поддерживается
      -- main-веткой — для tsconfig/devcontainer.json временно используется
      -- обычный json-парсер; jsonls LSP-сервер всё равно понимает комментарии.
      local parsers = {
        -- Группа A: основа
        "go", "gomod", "gosum", "gowork",
        "lua", "luadoc",
        "vim", "vimdoc",
        "bash",
        "query",
        "regex",
        "markdown", "markdown_inline",
        "comment",
        "printf",

        -- Группа B: бэкенд
        "yaml",
        "json",
        "toml",
        "dockerfile",
        "sql",
        "proto",
        "http",

        -- Группа C: DevOps
        "make",
        "gitcommit", "gitignore", "gitattributes", "git_rebase", "diff",
        "terraform", "hcl",
        "ssh_config",

        -- Группа D: системное
        "c", "cpp",

        -- Группа E: fish
        "fish",
      }

      -- ─── Установка недостающих парсеров ────────────────────────────────
      -- В новом API нет "ensure_installed" — сравниваем список нужных с
      -- уже установленными и докачиваем недостающее. Установка асинхронная,
      -- не блокирует UI.
      local ts = require("nvim-treesitter")
      local installed = ts.get_installed("parsers")
      local installed_set = {}
      for _, name in ipairs(installed) do
        installed_set[name] = true
      end

      local missing = {}
      for _, name in ipairs(parsers) do
        if not installed_set[name] then
          table.insert(missing, name)
        end
      end

      if #missing > 0 then
        vim.notify(
          "Treesitter: устанавливаю парсеры (" .. #missing .. "): "
            .. table.concat(missing, ", "),
          vim.log.levels.INFO
        )
        ts.install(missing)
      end

      -- ─── Включение подсветки и индента ─────────────────────────────────
      -- В новом API нет глобального `highlight.enable = true` — каждый
      -- буфер включает подсветку САМ через автокоманду FileType.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user-treesitter-start", { clear = true }),
        callback = function(args)
          -- Подсветка (highlight).
          local ok = pcall(vim.treesitter.start, args.buf)
          if not ok then return end

          -- Индент по AST.
          pcall(function()
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end)

          -- Folds от treesitter (fallback для nvim-ufo).
          vim.wo.foldmethod = "expr"
          vim.wo.foldexpr   = "v:lua.vim.treesitter.foldexpr()"
        end,
      })

      -- ─── Маппинг filetype для .env-файлов ──────────────────────────────
      -- Подсветка через bash-парсер: .env по сути shell-переменные.
      vim.filetype.add({
        filename = {
          [".env"] = "sh",
        },
        pattern = {
          ["%.env%.[%w_.-]+"] = "sh",
        },
      })
    end,
  },

  -- =========================================================================
  -- nvim-treesitter-textobjects (тоже ветка main).
  -- Даёт vaf/vif, dia, ]f/[f, ]c/[c.
  -- =========================================================================
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      local ok, ts_to = pcall(require, "nvim-treesitter-textobjects")
      if not ok then
        vim.notify("nvim-treesitter-textobjects not found", vim.log.levels.ERROR)
        return
      end

      ts_to.setup({
        select = {
          lookahead = true,
          include_surrounding_whitespace = false,
        },
        move = {
          set_jumps = true,
        },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move   = require("nvim-treesitter-textobjects.move")

      -- ── текстовые объекты select ───────────────────────────────────────
      -- Работают в Visual (x) и Operator-pending (o) режимах:
      -- vaf / daf / yaf / caf — выделить/удалить/копировать/изменить функцию
      local function map_select(lhs, capture)
        for _, mode in ipairs({ "x", "o" }) do
          vim.keymap.set(mode, lhs, function()
            select.select_textobject(capture, "textobjects")
          end, { silent = true, desc = capture })
        end
      end

      map_select("af", "@function.outer")
      map_select("if", "@function.inner")
      map_select("ac", "@class.outer")
      map_select("ic", "@class.inner")
      map_select("aa", "@parameter.outer")
      map_select("ia", "@parameter.inner")
      map_select("al", "@loop.outer")
      map_select("il", "@loop.inner")
      map_select("a/", "@comment.outer")
      map_select("i/", "@comment.inner")

      -- ── навигация по AST: ]f / [f к функциям, ]c / [c к классам ───────
      local function map_move(lhs, dir, capture)
        vim.keymap.set({ "n", "x", "o" }, lhs, function()
          move["goto_" .. dir](capture, "textobjects")
        end, { silent = true, desc = dir .. " " .. capture })
      end

      map_move("]f", "next_start",     "@function.outer")
      map_move("[f", "previous_start", "@function.outer")
      map_move("]c", "next_start",     "@class.outer")
      map_move("[c", "previous_start", "@class.outer")
      map_move("]a", "next_start",     "@parameter.inner")
      map_move("[a", "previous_start", "@parameter.inner")
    end,
  },

  -- =========================================================================
  -- nvim-ts-autotag — автозакрытие XML/HTML тегов.
  -- =========================================================================
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
      },
    },
  },
}