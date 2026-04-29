-- ============================================================================
-- lua/plugins/bufferline.lua
-- Верхняя полоса с табами по числу открытых буферов.
-- ============================================================================

return {
  {
    "akinsho/bufferline.nvim",
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
            text = "Explorer",
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
  },
}