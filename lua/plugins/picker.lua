-- lua/plugins/picker.lua
-- Telescope — фаззи-поиск файлов, текста, буферов, символов.
-- В VS Code аналог: Ctrl+P (файлы), Ctrl+Shift+F (grep), Ctrl+Shift+O (символы).

return {
  {
    "nvim-telescope/telescope.nvim",
    -- Грузится лениво: только когда нажата одна из клавиш ниже или вызвана :Telescope ...
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",   -- утилитарная библиотека, нужна telescope
      {
        -- Нативный C-сортировщик: значительно ускоряет фаззи-поиск.
        -- build = "make" запускается автоматически при :Lazy sync.
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          -- Загружать только если make доступен (на Arch — всегда)
          return vim.fn.executable("make") == 1
        end,
      },
    },

    keys = {
      -- Поиск файлов — главная фича, самый частый биндинг
      { "<leader>ff", "<cmd>Telescope find_files<cr>",            desc = "Find files" },
      -- Grep по всему проекту через ripgrep
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",             desc = "Live grep" },
      -- Список открытых буферов (аналог Ctrl+Tab в VS Code)
      { "<leader>fb", "<cmd>Telescope buffers<cr>",               desc = "Buffers" },
      -- Недавние файлы (аналог "Recently Opened" в VS Code)
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>",              desc = "Recent files" },
      -- Встроенная справка Neovim (огромная база, поиск по :help)
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",             desc = "Help tags" },
      -- Все активные биндинги — заглавная K чтобы не пересекаться с which-key
      { "<leader>fK", "<cmd>Telescope keymaps<cr>",               desc = "Keymaps" },
      -- Файлы конфига nvim (быстрый доступ из любого проекта)
      { "<leader>fc", "<cmd>Telescope find_files cwd=~/.config/nvim<cr>", desc = "Config files" },
      -- Символы LSP — заработают после Блока 6
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>",  desc = "Symbols (file)" },
      { "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Symbols (workspace)" },
      -- Grep слова под курсором (аналог Ctrl+Shift+F с prefill в VS Code)
      {
        "<leader>fw",
        function()
          require("telescope.builtin").grep_string({ word_match = "-w" })
        end,
        desc = "Grep word under cursor",
      },
    },

    opts = {
      defaults = {
        prompt_prefix   = "  ",   -- иконка лупы перед полем ввода
        selection_caret = " ",   -- стрелка у выбранной строки
        entry_prefix    = "  ",   -- отступ у невыбранных строк
        multi_icon      = "󰒆 ",   -- иконка мультиселекта

        -- Результаты идут сверху вниз — естественнее для VS Code пользователей
        sorting_strategy = "ascending",

        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width   = 0.55,   -- правая панель превью занимает 55%
            results_width   = 0.8,
          },
          width        = 0.87,        -- окно = 87% ширины терминала
          height       = 0.80,
          preview_cutoff = 120,       -- прятать превью если экран уже 120 символов
        },

        -- Файлы и папки, которые никогда не попадают в результаты
        file_ignore_patterns = {
          "%.git/", "node_modules/", "dist/", "build/",
          "%.lock$", "lazy%-lock%.json",
        },

        -- Аргументы ripgrep для live_grep: скрытые файлы включены, .git — нет
        vimgrep_arguments = {
          "rg", "--color=never", "--no-heading",
          "--with-filename", "--line-number", "--column",
          "--smart-case", "--hidden", "--glob", "!**/.git/*",
        },

        -- Клавиши внутри telescope (режим insert — пока окно открыто)
        mappings = {
          i = {
            ["<C-j>"] = "move_selection_next",      -- вниз по списку (не стрелки)
            ["<C-k>"] = "move_selection_previous",  -- вверх по списку
            ["<C-f>"] = "preview_scrolling_down",   -- скролл превью вниз
            ["<C-b>"] = "preview_scrolling_up",     -- скролл превью вверх
            ["<C-q>"] = "send_to_qflist",           -- перенести все результаты в quickfix
            ["<Esc>"] = "close",                    -- закрыть (не выходить в normal)
          },
          n = {
            ["q"] = "close",
          },
        },
      },

      pickers = {
        find_files = {
          hidden = true,   -- показывать скрытые файлы (dotfiles)
          -- fd быстрее find; если fd есть — использовать его
          find_command = vim.fn.executable("fd") == 1
            and { "fd", "--type", "f", "--hidden", "--exclude", ".git" }
            or nil,
        },
        buffers = {
          sort_mru              = true,   -- сначала недавно использованные буферы
          ignore_current_buffer = true,  -- не показывать текущий файл в списке
        },
      },

      extensions = {
        fzf = {
          fuzzy                   = true,          -- включить нечёткий поиск
          override_generic_sorter = true,          -- заменить встроенный сортировщик
          override_file_sorter    = true,
          case_mode               = "smart_case",  -- маленькие = нечувствительный регистр
        },
      },
    },

    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      -- pcall чтобы не упало если fzf-native не скомпилировался
      pcall(telescope.load_extension, "fzf")
    end,
  },
}