-- lua/plugins/search-replace.lua
-- Grug-Far — мультифайловый поиск и замена.
-- В VS Code аналог: Ctrl+Shift+H (Replace in Files).

return {
  {
    "MagicDuck/grug-far.nvim",
    -- Ленивая загрузка: только при вызове команды или биндинга
    cmd = "GrugFar",
    keys = {
      {
        "<leader>sr",
        function()
          local bufname = vim.api.nvim_buf_get_name(0)
          local root = bufname ~= "" and vim.fs.root(bufname, {
            ".git", "go.mod", "package.json", "Cargo.toml", "pyproject.toml", "Makefile",
          }) or vim.fn.getcwd()
          require("grug-far").open({ prefills = { paths = root } })
        end,
        mode = { "n", "v" },
        desc = "Search & Replace (project-wide)",
      },
      {
        "<leader>sw",
        function()
          local bufname = vim.api.nvim_buf_get_name(0)
          local root = bufname ~= "" and vim.fs.root(bufname, {
            ".git", "go.mod", "package.json", "Cargo.toml", "pyproject.toml", "Makefile",
          }) or vim.fn.getcwd()
          require("grug-far").open({
            prefills = {
              search = vim.fn.expand("<cword>"),
              paths  = root,
            },
          })
        end,
        desc = "Search & Replace word under cursor",
      },
      {
        "<leader>sf",
        function()
          require("grug-far").open({
            prefills = { paths = vim.fn.expand("%") },
          })
        end,
        desc = "Search & Replace in current file",
      },
    },

    opts = {
      -- Используем ripgrep как поисковый движок (он у нас уже установлен).
      -- Альтернатива: "astgrep" — структурный поиск по AST, но требует sg.
      engine = "ripgrep",

      -- Где открывается окно поиска: split / horizontal_split / float
      windowCreationCommand = "vsplit",

      -- Настройки конкретно для движка ripgrep
      engines = {
        ripgrep = {
          extraArgs = "--hidden",
        },
      },

      -- Иконки полей в окне поиска
      icons = {
        enabled                  = true,
        actionEntryBullet        = " ",
        searchInput              = " ",
        replaceInput             = " ",
        filesFilterInput         = " ",
        flagsInput               = "󰮚 ",
        resultsStatusReady       = "󱋆 ",
        resultsStatusError       = " ",
        resultsStatusSuccess     = " ",
        resultsActionMessage     = "  ",
        resultsChangeIndicator   = "┃",
        resultsAddedIndicator    = "▒",
        resultsRemovedIndicator  = "▒",
        resultsDiffSeparatorIndicator = "┊",
        searchInputErrorIndicator = " ",
      },

      -- Биндинги внутри окна grug-far (помимо обычных vim-команд)
      keymaps = {
        replace          = { n = "<localleader>r" }, -- применить все замены
        qflist           = { n = "<localleader>q" }, -- результаты в quickfix
        syncLocations    = { n = "<localleader>s" }, -- синхронизировать буфер
        syncLine         = { n = "<localleader>l" }, -- синхронизировать строку
        close            = { n = "<localleader>c" }, -- закрыть окно
        historyOpen      = { n = "<localleader>t" }, -- история поисков
        historyAdd       = { n = "<localleader>a" }, -- добавить в историю
        refresh          = { n = "<localleader>f" }, -- обновить результаты
        gotoLocation     = { n = "<enter>" },        -- перейти к результату
        pickHistoryEntry = { n = "<enter>" },
        abort            = { n = "<localleader>b" }, -- прервать поиск
        help             = { n = "g?" },             -- справка по биндингам
        toggleShowCommand = { n = "<localleader>p" },
      },

      -- При запуске сразу ставим курсор в поле Search
      startInInsertMode = true,

      -- Переход между полями поиска
      transient = false,

      -- Подсветка совпадений в результатах
      resultsHighlight = true,
    },
  },
}