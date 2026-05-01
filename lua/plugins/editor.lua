-- ============================================================================
-- lua/plugins/editor.lua
-- Плагины, улучшающие сам процесс редактирования: визуальные подсказки,
-- TODO-комментарии, мелкие движения. По одному плагину на блок.
-- ============================================================================

return {
  -- ==========================================================================
  -- indent-blankline.nvim — вертикальные направляющие отступов.
  -- Аналог editor.renderIndentGuides в VS Code.
  -- ==========================================================================
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",                          -- модуль для setup() — у плагина короткое имя
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = {
        char = "▏",                        -- символ линии (тонкая вертикальная)
        tab_char = "▏",                    -- та же линия для табов (Go использует табы)
      },
      scope = {
        enabled    = true,
        show_start = false,                -- НЕ подчёркивать первую строку scope
        show_end   = false,                -- НЕ подчёркивать последнюю
        char       = "▎",                  -- scope (текущий блок) — обычная сплошная
        highlight  = "IblScope",
      },
      exclude = {
        -- НЕ показывать линии в этих типах буферов и filetype'ов
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "Trouble",
          "trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "lazyterm",
          "snacks_dashboard",
        },
      },
    },
    config = function(_, opts)
      require("ibl").setup(opts)
      -- IblScope ссылается на эту highlight-группу — задаём цвет явно,
      -- чтобы scope-линия (вертикальная палочка текущего блока) была видна
      --vim.api.nvim_set_hl(0, "IblScope", { fg = "#7aa2f7" })
    end,
  },

  -- ==========================================================================
  -- todo-comments.nvim — подсветка TODO/FIXME/NOTE/HACK/WARNING.
  -- ==========================================================================
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      signs = true,
      sign_priority = 8,
      keywords = {
        FIX  = { icon = " ", color = "error",   alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
        TODO = { icon = " ", color = "info"   },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        PERF = { icon = " ", color = "default", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = " ", color = "hint",    alt = { "INFO" } },
        TEST = { icon = "⏲ ", color = "test",    alt = { "TESTING", "PASSED", "FAILED" } },
      },
      highlight = {
        before        = "",                  -- пустая плашка перед tag
        keyword       = "fg",                -- цвет текста tag, без плашки
        after         = "fg",                -- текст после tag тоже окрашен
        pattern       = [[.*<(KEYWORDS)\s*:]],
        comments_only = true,                -- подсвечивать только в комментариях
      },
      colors = {
        error   = { "DiagnosticError", "ErrorMsg",   "#DC2626" },
        warning = { "DiagnosticWarn",  "WarningMsg", "#FBBF24" },
        info    = { "DiagnosticInfo",                "#2563EB" },
        hint    = { "DiagnosticHint",                "#10B981" },
        default = { "Identifier",                    "#7C3AED" },
        test    = { "Identifier",                    "#FF00FF" },
      },
    },
    keys = {
      { "]t",         function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
      { "[t",         function() require("todo-comments").jump_prev() end, desc = "Previous todo comment" },
      { "<leader>xt", "<cmd>TodoQuickFix<cr>",                             desc = "Todo (quickfix)" },
    },
    config = function(_, opts)
      require("todo-comments").setup(opts)
      -- Сбрасываем дефолтные подсветки, чтобы плашки не перебивали наши настройки
      vim.api.nvim_set_hl(0, "Todo",            {})
      vim.api.nvim_set_hl(0, "@comment.error",  {})
      vim.api.nvim_set_hl(0, "@comment.warning", {})
      vim.api.nvim_set_hl(0, "@comment.note",   {})
      vim.api.nvim_set_hl(0, "@comment.todo",   {})
    end,
  },
}