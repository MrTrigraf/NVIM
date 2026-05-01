-- lua/plugins/navigation.lua
-- Три плагина для навигации:
--   aerial   — outline (структура текущего файла)
--   nvim-ufo — продвинутое сворачивание кода (folding)
--   harpoon  — быстрые закладки на часто используемые файлы

return {
  -- ============================================================================
  -- 1. AERIAL — список функций/классов/методов файла в боковой панели
  -- В VS Code: Ctrl+Shift+O (Outline)
  -- ============================================================================
  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
    keys = {
      -- Toggle панели outline справа
      { "<leader>o", "<cmd>AerialToggle!<cr>", desc = "Outline (aerial)" },
      -- Telescope-подобный быстрый поиск по символам файла
      { "<leader>fO", "<cmd>AerialNavToggle<cr>", desc = "Outline navigator" },
    },
    opts = {
      -- Источники данных для outline (в порядке приоритета).
      -- Сейчас работает treesitter; lsp заработает в Блоке 6.
      backends = { "treesitter", "lsp", "markdown", "man" },

      layout = {
        max_width        = { 40, 0.2 }, -- макс. 40 столбцов или 20% экрана
        min_width        = 28,
        default_direction = "right",     -- панель справа (как Outline в VS Code)
        placement        = "window",     -- привязана к текущему окну
      },

      -- Подсвечивать текущий символ под курсором в outline
      highlight_on_hover = true,

      -- Автоматически закрывать aerial если он остался последним окном
      close_on_select = false,

      -- Показывать guides (палочки иерархии) как в neo-tree
      show_guides = true,
      guides = {
        mid_item   = "├─",
        last_item  = "└─",
        nested_top = "│ ",
        whitespace = "  ",
      },

      -- Биндинги внутри aerial-окна
      keymaps = {
        ["<cr>"] = "actions.jump",          -- перейти к символу
        ["<2-LeftMouse>"] = "actions.jump", -- двойной клик
        ["o"]    = "actions.jump",
        ["q"]    = "actions.close",
        ["<Tab>"] = "actions.tree_toggle",  -- свернуть/развернуть
        ["zM"]   = "actions.tree_close_all",
        ["zR"]   = "actions.tree_open_all",
      },

      -- Какие типы символов показывать (фильтр).
      -- Можно убирать ненужные: убрать "Variable" чтобы не засорять.
      filter_kind = {
        "Class", "Constructor", "Enum", "Function", "Interface",
        "Module", "Method", "Struct",
      },

      -- Иконки символов берутся из mini.icons автоматически
      -- (мы его подключили в ui.lua через mock devicons)
    },
  },

  -- ============================================================================
  -- 2. NVIM-UFO — продвинутое сворачивание кода
  -- В VS Code: стрелки сворачивания рядом с функциями
  -- ============================================================================
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "BufReadPost",
    keys = {
      { "zR", function() require("ufo").openAllFolds()  end, desc = "Open all folds" },
      { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
      { "zr", function() require("ufo").openFoldsExceptKinds() end, desc = "Open folds (except kinds)" },
      { "zm", function() require("ufo").closeFoldsWith()   end, desc = "Close folds with level" },
      -- zk/zj — стандартные vim-команды для сворачивания одного блока
      -- Для просмотра содержимого свёрнутого блока без разворачивания:
      {
        "K",
        function()
          local winid = require("ufo").peekFoldedLinesUnderCursor()
          if not winid then
            -- Если свёрнутого блока нет — показываем LSP hover (заработает в Блоке 6)
            vim.lsp.buf.hover()
          end
        end,
        desc = "Peek fold or LSP hover",
      },
    },
    init = function()
      vim.o.foldcolumn     = "1"
      vim.o.foldlevel      = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable     = true

      vim.opt.fillchars:append({
        fold      = " ",
        foldopen  = vim.fn.nr2char(0xeab4),
        foldsep   = " ",
        foldclose = vim.fn.nr2char(0xeab6),
      })

      -- Цвет стрелочек сворачивания (foldopen/foldclose) как в VS Code
      local fold_fg = "#7A8382"
      vim.api.nvim_set_hl(0, "FoldColumn", { fg = fold_fg, bg = "NONE" })
      vim.api.nvim_set_hl(0, "Folded",     { fg = fold_fg, bg = "NONE" })

      -- При смене темы обновляем цвет, чтобы не сбился
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.api.nvim_set_hl(0, "FoldColumn", { fg = fold_fg, bg = "NONE" })
          vim.api.nvim_set_hl(0, "Folded",     { fg = fold_fg, bg = "NONE" })
        end,
      })
    end,
    opts = {
      -- Провайдеры folding'а в порядке приоритета.
      -- treesitter даёт лучшие результаты для языков с парсерами.
      -- indent — fallback для файлов без treesitter (текстовые файлы).
      provider_selector = function(_, filetype, _)
        -- Возвращаем список провайдеров для этого filetype.
        -- LSP добавится автоматически в Блоке 6, если LSP активен.
        return { "treesitter", "indent" }
      end,

      -- Какие типы блоков НЕ сворачивать по умолчанию (zr игнорирует их).
      -- Например, импорты в Go обычно стоит держать развёрнутыми.
      open_fold_hl_timeout = 400,
      close_fold_kinds_for_ft = {
        default = { "imports", "comment" }, -- сворачивать имп. и комментарии при открытии
      },

      -- Кастомный текст для свёрнутого блока: показывает первую строку + сколько свёрнуто
      fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local suffix = ("  󰁂 %d "):format(endLnum - lnum)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, "MoreMsg" })
        return newVirtText
      end,
    },
  },

  -- ============================================================================
  -- 3. HARPOON — закладки на 2-5 любимых файлов проекта
  -- Идея: добавил файл (<leader>ha) → прыгаешь на него цифрой (<leader>1..5)
  -- ============================================================================
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      -- Добавить текущий файл в список harpoon
      {
        "<leader>ha",
        function() require("harpoon"):list():add() end,
        desc = "Harpoon: add file",
      },
      -- Открыть UI со списком файлов (показывает все добавленные)
      {
        "<leader>hh",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon: menu",
      },
      -- Прыжки на 1-5 закладку. <leader>1 быстрее запоминается чем <leader>h1.
      { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon: file 1" },
      { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon: file 2" },
      { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon: file 3" },
      { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon: file 4" },
      { "<leader>5", function() require("harpoon"):list():select(5) end, desc = "Harpoon: file 5" },
      -- Циклическое переключение между файлами
      {
        "<leader>hn",
        function() require("harpoon"):list():next() end,
        desc = "Harpoon: next",
      },
      {
        "<leader>hp",
        function() require("harpoon"):list():prev() end,
        desc = "Harpoon: prev",
      },
    },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup({
        settings = {
          save_on_toggle  = true,    -- сохранять изменения при закрытии меню
          sync_on_ui_close = true,
        },
      })
    end,
  },
}