-- ============================================================================
-- lua/plugins/ui.lua
-- UI-плагины: статус-строка, попап-подсказка по биндингам, иконки файлов.
-- ============================================================================

return {
  -- Плагин 1: mini.icons
{
    "nvim-mini/mini.icons",
    lazy = true,
    opts = {},
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },

  -- Плагин 2: nvim-web-devicons (fallback)
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    opts = {
      color_icons = true,
      default = true,
      strict = true,
    },
  },

  -- Плагин 3: which-key
  {
    "folke/which-key.nvim",
    event = "VeryLazy",           -- грузится сразу после старта, но не блокируя его
    opts = {
      -- preset "modern" — современный компактный вид с рамкой
      preset = "modern",

      -- задержка перед показом попапа (мс). 300 — стандарт.
      delay = 300,

      -- отключаем встроенные подсказки для базовых vim-команд (z, g, ', `, " и т.п.) —
      -- они забивают экран. Свои <leader>-биндинги по-прежнему показываются.
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>d", group = "debug" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>h", group = "harpoon" },
        { "<leader>l", group = "lsp" },
        { "<leader>o", group = "outline" },
        { "<leader>s", group = "search/replace" },
        { "<leader>t", group = "tests" },
        { "<leader>x", group = "diagnostics" },
      },

      icons = {
        rules = false,
      },
    },
    keys = {
      -- <leader>fk — показать все биндинги (полный список)
      {
        "<leader>fk",
        function() require("which-key").show({ global = false }) end,
        desc = "Buffer keymaps (which-key)",
      },
    },
  },

   -- Плагин 4: lualine
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "kanagawa",                 -- единая палитра с colorscheme
        globalstatus = true,                -- одна общая statusline на все сплиты
        icons_enabled = true,
        component_separators = { left = "│", right = "│" },
        section_separators   = { left = "",  right = "" },
        disabled_filetypes = {
          statusline = { "dashboard", "alpha", "snacks_dashboard" },
        },
      },
      sections = {
        -- слева направо: a → b → c
        lualine_a = { "mode" },             -- NORMAL/INSERT/VISUAL и т.п.
        lualine_b = {
          { "branch", icon = "" },        -- git-ветка
          {
            "diff",                          -- +добавлено / ~изменено / -удалено
            symbols = { added = " ", modified = " ", removed = " " },
          },
        },
        lualine_c = {
          {
            "diagnostics",                   -- LSP-диагностики
            symbols = {
              error = " ",
              warn  = " ",
              info  = " ",
              hint  = " ",
            },
          },
          {
            "filename",
            path = 1,                        -- 0=имя, 1=относительный путь, 2=абсолютный
            symbols = {
              modified = "●",
              readonly = "",
              unnamed  = "[No Name]",
            },
          },
        },
        -- справа налево: x → y → z
        lualine_x = {
          "encoding",                        -- utf-8 и т.п.
          {
            "fileformat",                    -- unix / dos / mac
            symbols = { unix = "", dos = "", mac = "" },
          },
          "filetype",
        },
        lualine_y = { "progress" },          -- 35% — прокрутка по файлу
        lualine_z = { "location" },          -- 19:4 — строка:колонка
      },
    },
  },
}