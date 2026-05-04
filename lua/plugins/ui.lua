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

      win = {
        no_overlap = true,  -- не перекрывает курсор
        border = "single",  -- или "rounded" для стиля темы
        padding = {1, 2},
        title_pos = "center",
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
        -- Тема задаётся в config, чтобы использовать встроенные цвета kanagawa-paper.
        -- Здесь можно оставить заглушку.
        globalstatus = true,
        icons_enabled = true,
        component_separators = { left = "│", right = "│" },
        section_separators   = { left = "",  right = "" },
        disabled_filetypes = {
          statusline = { "dashboard", "alpha", "snacks_dashboard" },
        },
      },
      sections = {
        lualine_a = {
          {
            "mode",
            fmt = function(str)
              local abbreviations = {
                ["NORMAL"]       = " NO",
                ["INSERT"]       = " IN",
                ["VISUAL"]       = "󰉂 VI",
                ["V-LINE"]       = "󰉁 VL",
                ["V-BLOCK"]      = "⬒ VB",
                ["V-REPLACE"]    = "󱓳 VR",
                ["REPLACE"]      = "󱓳 RE",
                ["COMMAND"]      = " CO",
                ["SHELL"]        = " SH",
                ["SELECT"]       = "󰉃 SE",
                ["S-LINE"]       = "󰉂 SL",
                ["S-BLOCK"]      = "SB",
                ["TERMINAL"]     = " TE",
                ["OP-PENDING"]   = "󰅂 OP",
              }
              -- Если режим есть в таблице — вернуть сокращение, иначе первые две буквы заглавными
              return abbreviations[str] or str:sub(1, 2):upper()
            end,
          },
        },
        lualine_b = {
          { "branch", icon = "" },
        },
        lualine_c = {
          {
            "buffers",
            mode                    = 0,
            show_filename_only      = true,
            hide_filename_extension = false,
            show_modified_status    = true,

            -- ── Фильтр: только буферы текущего проекта ─────────────────
            -- Запоминаем root активного буфера (папку с .git/go.mod) при
            -- первом вызове и фильтруем все буферы по нему. Если открыл
            -- файл из другого проекта — он не попадёт в полосу.
            -- Фильтр: только буферы, чей путь начинается с текущей cwd.
            -- cwd Neovim — стабильнее vim.fs.root, потому что не зависит
            -- от наличия .git в домашней папке. + проверки buftype/buflisted
            -- отсекают служебные буферы (neo-tree, terminal, mini.icons).
            filter = function(bufnr)
              if not vim.bo[bufnr].buflisted then return false end
              if vim.bo[bufnr].buftype ~= "" then return false end

              local bufname = vim.api.nvim_buf_get_name(bufnr)
              if bufname == "" then return false end

              local cwd = vim.fn.getcwd()
              if not cwd:match("/$") then cwd = cwd .. "/" end

              return vim.startswith(bufname, cwd)
            end,
            -- ── Спец-имена для всё-таки попавших buftype-буферов ─────
            filetype_names = {
              TelescopePrompt  = "Telescope",
              snacks_dashboard = "Dashboard",
              lazy             = "Lazy",
              mason            = "Mason",
            },

            max_length = function() return math.floor(vim.o.columns * 2 / 3) end,

            symbols = {
              modified       = " ●",
              alternate_file = "",
              directory      = "",
            },

            -- ── Цвета: прозрачный фон, через named highlight-группы ──
            buffers_color = {
              active   = "LualineBufferActive",
              inactive = "LualineBufferInactive",
            },
          },
        },
        lualine_x = { },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
    config = function(_, opts)
      local theme_name = vim.o.background == "light" and "kanagawa-paper-canvas" or "kanagawa-paper-ink"
      local ok, theme = pcall(require, "lualine.themes." .. theme_name)
      opts.options.theme = ok and theme or "auto"
      require("lualine").setup(opts)

      -- Принудительный redraw статуслайна при смене cwd через project.nvim
      -- или ручного :cd. Без этого buffers-фильтр не пересчитывает старые
      -- буферы — буферы из прошлого проекта остаются в полосе до тех пор,
      -- пока сами не активируются.
      vim.api.nvim_create_autocmd("DirChanged", {
        callback = function() vim.cmd.redrawstatus() end,
      })
    end,
  },
}