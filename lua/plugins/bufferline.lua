-- ============================================================================
-- lua/plugins/bufferline.lua
-- Верхняя полоса с табами по числу открытых буферов.
-- ============================================================================

return {
  {
    "akinsho/bufferline.nvim",
    enabled = false,           -- ← плагин временно отключён 
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        mode = "buffers",
        diagnostics = "nvim_lsp",
        show_buffer_close_icons = false,
        show_close_icon = false,
        separator_style = "thin",
        always_show_bufferline = true,
        offsets = {
          {
            filetype = "neo-tree",
            text = "",
            highlight = "Directory",
            text_align = "left",
            separator = true,
          },
        },
      },
    },
    keys = {
      { "<leader>bp", "<cmd>BufferLineTogglePin<cr>",            desc = "Pin buffer" },
      { "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", desc = "Close non-pinned" },
      { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>",          desc = "Close other buffers" },
      { "<leader>br", "<cmd>BufferLineCloseRight<cr>",           desc = "Close buffers to the right" },
      { "<leader>bl", "<cmd>BufferLineCloseLeft<cr>",            desc = "Close buffers to the left" },
      { "[b",         "<cmd>BufferLineCyclePrev<cr>",            desc = "Prev buffer (bufferline)" },
      { "]b",         "<cmd>BufferLineCycleNext<cr>",            desc = "Next buffer (bufferline)" },
      { "[B",         "<cmd>BufferLineMovePrev<cr>",             desc = "Move buffer left" },
      { "]B",         "<cmd>BufferLineMoveNext<cr>",             desc = "Move buffer right" },
    },
    config = function(_, opts)
      require("bufferline").setup(opts)

      -- Скрыть tabline на дашборде
      local group = vim.api.nvim_create_augroup("bufferline_hide_on_dashboard", { clear = true })

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "snacks_dashboard", "dashboard", "alpha" },
        callback = function()
          vim.opt.showtabline = 0
        end,
      })

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        group = group,
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          if ft == "snacks_dashboard" or ft == "dashboard" or ft == "alpha" then
            vim.opt.showtabline = 0
          else
            vim.opt.showtabline = 2
          end
        end,
      })
    end,
  },
}