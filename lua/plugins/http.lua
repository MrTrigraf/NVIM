-- lua/plugins/http.lua
-- HTTP-клиент kulala.nvim: выполнение HTTP-запросов из .http файлов
-- прямо внутри Neovim. Аналог JetBrains HTTP Client.

return {
  {
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest" },

    init = function()
      vim.filetype.add({
        extension = {
          http = "http",
          rest = "http",
        },
      })
    end,

    keys = {
      { "<leader>r", group = "http" },
      { "<leader>rr", function() require("kulala").run() end,              desc = "HTTP: run request under cursor" },
      { "<leader>ra", function() require("kulala").run_all() end,          desc = "HTTP: run all requests in file" },
      { "<leader>rl", function() require("kulala").replay() end,           desc = "HTTP: replay last request" },
      { "<leader>ro", function() require("kulala").open() end,             desc = "HTTP: open response window" },
      { "<leader>rt", function() require("kulala").toggle_view() end,      desc = "HTTP: toggle body / headers" },
      { "<leader>rc", function() require("kulala").copy() end,             desc = "HTTP: copy as curl" },
      { "<leader>re", function() require("kulala").set_selected_env() end, desc = "HTTP: select environment" },
      { "<leader>rq", function() require("kulala").close() end,            desc = "HTTP: close kulala windows" },
      { "]r",         function() require("kulala").jump_next() end,        desc = "HTTP: next request" },
      { "[r",         function() require("kulala").jump_prev() end,        desc = "HTTP: previous request" },
    },

    opts = {
      global_keymaps = false,
      ui = {
        display_mode    = "split",
        split_direction = "vertical",
        default_view    = "body",
      },
    },
  },
}