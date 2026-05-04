-- ============================================================================
-- lua/plugins/project.lua
-- project.nvim — автоопределение и переключение между проектами.
-- При открытии любого файла плагин ищет вверх по дереву маркеры (.git, go.mod
-- и т.д.) и при обнаружении проекта меняет cwd Neovim на его root. Это даёт:
--  • lualine "buffers" фильтрует строго по активному проекту;
--  • neo-tree автоматически следует за активным проектом (через наш
--    умный follow в explorer.lua, который читает живой getcwd());
--  • <leader>fp — picker последних проектов через telescope.
--
-- В VS Code аналог: "Recent Workspaces" в File menu.
-- ============================================================================

return {
  {
    "ahmedkhalf/project.nvim",
    -- main = "project_nvim" нужно явно — у плагина имя репо отличается от
    -- имени Lua-модуля.
    main = "project_nvim",

    -- VeryLazy — грузим после старта, не блокируя его. project.nvim сам
    -- цепляется на autocmd BufEnter, поэтому работает с первого же буфера.
    event = "VeryLazy",

    opts = {
      detection_methods = { "lsp", "pattern" },

      patterns = {
        ".git",
        "go.mod",
        "go.work",
        "package.json",
        "Cargo.toml",
        "pyproject.toml",
        "Makefile",
      },

      -- false = плагин сам делает :cd при обнаружении проекта.
      manual_mode = false,

      -- Пути, в которых cwd НЕ менять. Используем abs paths
      -- через vim.fn.expand, потому что project.nvim не разворачивает
      -- тильду самостоятельно.
      exclude_dirs = {
        vim.fn.expand("~"),
        vim.fn.expand("~/Downloads"),
        vim.fn.expand("~/Documents"),
        "/tmp",
        "/etc",
        "/usr",
      },

      -- НЕ показывать уведомление "Set CWD to ..." при каждой смене.
      silent_chdir = true,

      -- :cd на root проекта (не на папку с маркером).
      scope_chdir = "global",

      -- НЕ показывать скрытые файлы в picker'е <leader>fp.
      show_hidden = false,

      datapath = vim.fn.stdpath("data"),
    },

    config = function(_, opts)
      require("project_nvim").setup(opts)
    end,
  },
}