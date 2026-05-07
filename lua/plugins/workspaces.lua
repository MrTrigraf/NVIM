-- lua/plugins/workspaces.lua
-- natecraddock/workspaces.nvim — журнал workspace'ов с MRU-сортировкой.
return {
  {
    "natecraddock/workspaces.nvim",
    -- VeryLazy: грузим после UI, чтобы не блокировать стартап.
    event = "VeryLazy",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      -- Файл хранения. По умолчанию = ~/.local/share/nvim/workspaces.
      -- Указываем явно, чтобы не было сюрпризов при смене XDG-переменных.
      path = vim.fn.stdpath("data") .. "/workspaces",

      -- "global" — :cd для всего nvim. Аналог поведения VS Code.
      cd_type = "global",

      -- Сортировка в Telescope-пикере и при `:WorkspacesList`.
      sort = true,           -- сортировать список (без этого MRU не работает)
      mru_sort = true,       -- последний открытый — наверху

      -- НЕ открывать workspace автоматически при `nvim` без аргументов в зарегистрированной папке.
      -- Hooks триггерим только явно — через :WorkspacesOpen или нашу обвязку.
      auto_open = false,

      -- НЕ менять cwd автоматически при открытии файла в зарегистрированной папке.
      auto_dir = false,

      -- Hooks пустые. Логика переключения (closure буферов, neo-tree refresh) —
      hooks = {},

      -- :WorkspacesList и др. команды — все опции по дефолту.
      -- notify_info: показывать тосты "Workspace foo added/removed/opened".
      notify_info = false,
    },
    config = function(_, opts)
      require("workspaces").setup(opts)
      -- Подключаем telescope-расширение. pcall — на случай гонки загрузки telescope.
      pcall(require("telescope").load_extension, "workspaces")
    end,
  },
}