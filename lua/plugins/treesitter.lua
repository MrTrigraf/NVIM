-- ============================================================================
-- lua/plugins/treesitter.lua
-- Treesitter — современная подсветка синтаксиса через парсинг кода в AST.
-- Также даёт текстовые объекты для редактирования (vaf, vif, etc).
-- ============================================================================

return {
  -- =========================================================================
  -- nvim-treesitter (master ветка — стабильный API)
  -- highlight, indent, incremental_selection
  -- =========================================================================
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSUpdate", "TSInstall", "TSInstallInfo", "TSUpdateSync" },
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
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
        "json", "jsonc",
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
      },
      sync_install = false,
      auto_install = true,

      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },

      indent = {
        enable = true,
      },

      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection    = "<C-Space>",
          node_incremental  = "<C-Space>",
          scope_incremental = "<C-s>",
          node_decremental  = "<BS>",
        },
      },
    },
    config = function(_, opts)
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then
        vim.notify("nvim-treesitter.configs not found", vim.log.levels.ERROR)
        return
      end
      configs.setup(opts)

      -- Маппинг filetype для .env-файлов — подсветка через bash-парсер.
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
  -- nvim-treesitter-textobjects (main ветка — новый API)
  -- даёт vaf/vif, dia, ]f/[f, ]c/[c
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
          lookahead = true,                  -- если объект не под курсором — прыгнуть к ближайшему
          include_surrounding_whitespace = false,
        },
        move = {
          set_jumps = true,                  -- движения попадают в jumplist (Ctrl-O возвращает)
        },
      })

      -- В новом API биндинги делаются вручную через select_textobject и goto_*
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

      map_select("af", "@function.outer")    -- around function
      map_select("if", "@function.inner")    -- inside function
      map_select("ac", "@class.outer")       -- around class/struct
      map_select("ic", "@class.inner")
      map_select("aa", "@parameter.outer")   -- around argument
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
  -- nvim-ts-autotag — автозакрытие XML/HTML тегов
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