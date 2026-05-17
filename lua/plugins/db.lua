-- lua/plugins/db.lua
-- PostgreSQL-клиент в Neovim на связке vim-dadbod.

return {
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      {
        "kristijanhusak/vim-dadbod-completion",
        ft = { "sql", "mysql", "plsql" },
        lazy = true,
      },
    },

    cmd = {
      "DBUI", "DBUIToggle", "DBUIAddConnection",
      "DBUIFindBuffer", "DBUIRenameBuffer", "DBUILastQueryInfo",
    },

    keys = {
      { "<leader>Bb", "<cmd>DBUIToggle<CR>",        desc = "DB: панель (drawer)" },
      { "<leader>Bf", "<cmd>DBUIFindBuffer<CR>",    desc = "DB: найти query-буфер" },
      { "<leader>Br", "<cmd>DBUIRenameBuffer<CR>",  desc = "DB: переименовать буфер" },
      { "<leader>Bq", "<cmd>DBUILastQueryInfo<CR>", desc = "DB: инфо о последнем запросе" },
      { "<leader>Ba", "<cmd>DBUIAddConnection<CR>", desc = "DB: добавить подключение" },
    },

    init = function()
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_win_position = "right"
      vim.g.db_ui_winwidth = 35
      vim.g.db_ui_show_help = 0
      vim.g.db_ui_use_nvim_notify = 1
      vim.g.db_ui_execute_on_save = 1
    end,

    config = function()
      local group = vim.api.nvim_create_augroup("dadbod_ui_cleanup", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "dbui", "dbout" },
        callback = function()
          vim.opt_local.foldcolumn     = "0"
          vim.opt_local.signcolumn     = "no"
          vim.opt_local.number         = false
          vim.opt_local.relativenumber = false
          vim.opt_local.statuscolumn   = ""
        end,
      })
    end,
  },
}