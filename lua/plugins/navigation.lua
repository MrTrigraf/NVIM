-- lua/plugins/navigation.lua
-- Три плагина для навигации + statuscol для fold-колонки

return {
  -- ============================================================================
  -- 0. STATUSCOL — правильная fold‑колонка без цифр (рекомендовано nvim-ufo)
  -- ============================================================================

  {
  "luukvbaal/statuscol.nvim",
  lazy = false,
  config = function()
    local builtin = require("statuscol.builtin")

    require("statuscol").setup({
      ft_ignore = { "neo-tree", "aerial" },
      segments = {
        {
          text = { builtin.foldfunc, " " },
          hl = "FoldColumn",
          click = "v:lua.ScFa",
        },
        {
          sign = { namespace = { "diagnostic/signs", "gitsigns" }, maxwidth = 1, auto = true },
          click = "v:lua.ScSa",
        },
        {
          text = { builtin.lnumfunc, " " },
          click = "v:lua.ScLa",
        },
      },
    })
  end,
},

  -- ============================================================================
  -- 1. AERIAL — список функций/классов/методов файла в боковой панели
  -- ============================================================================

  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
    keys = {
      { "<leader>o", "<cmd>AerialToggle!<cr>", desc = "Outline (aerial)" },
      { "<leader>fO", "<cmd>AerialNavToggle<cr>", desc = "Outline navigator" },
    },
    opts = {
      backends = { "treesitter", "lsp", "markdown", "man" },
      layout = {
        max_width = { 40, 0.2 },
        min_width = 28,
        default_direction = "right",
        placement = "window",
      },
      highlight_on_hover = true,
      close_on_select = false,
      show_guides = true,
      guides = {
        mid_item = "├─",
        last_item = "└─",
        nested_top = "│ ",
        whitespace = " ",
      },
      keymaps = {
        ["<CR>"] = "actions.jump",
        ["<2-LeftMouse>"] = "actions.jump",
        ["o"] = "actions.jump",
        ["q"] = "actions.close",
        ["<Tab>"] = "actions.tree_toggle",
        ["zM"] = "actions.tree_close_all",
        ["zR"] = "actions.tree_open_all",
      },
      filter_kind = {
        "Class",
        "Constructor",
        "Enum",
        "Function",
        "Interface",
        "Module",
        "Method",
        "Struct",
      },
    },
  },

  -- ============================================================================
  -- 2. NVIM-UFO — продвинутое сворачивание кода
  -- ============================================================================

  {
    "kevinhwang91/nvim-ufo",
    dependencies = {
      "kevinhwang91/promise-async",
      "luukvbaal/statuscol.nvim",
    },
    event = "BufReadPost",
    keys = {
      { "zR", function() require("ufo").openAllFolds() end, desc = "Open all folds" },
      { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
      { "zr", function() require("ufo").openFoldsExceptKinds() end, desc = "Open folds (except kinds)" },
      { "zm", function() require("ufo").closeFoldsWith() end, desc = "Close folds with level" },
      {
        "K",
        function()
          local winid = require("ufo").peekFoldedLinesUnderCursor()
          if not winid then
            vim.lsp.buf.hover()
          end
        end,
        desc = "Peek fold or LSP hover",
      },
    },
    init = function()
      vim.opt.foldcolumn = "1"
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99
      vim.opt.foldenable = true

      vim.opt.fillchars:append({
        fold = " ",
        foldopen = "",
        foldsep = " ",
        foldclose = "",
      })

      local fold_fg = "#7A8382"
      vim.api.nvim_set_hl(0, "FoldColumn", { fg = fold_fg, bg = "NONE" })
      vim.api.nvim_set_hl(0, "Folded", { fg = fold_fg, bg = "NONE" })

      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.api.nvim_set_hl(0, "FoldColumn", { fg = fold_fg, bg = "NONE" })
          vim.api.nvim_set_hl(0, "Folded", { fg = fold_fg, bg = "NONE" })
        end,
      })
    end,
    opts = {
      provider_selector = function(_, _, _)
        return { "treesitter", "indent" }
      end,
      close_fold_kinds_for_ft = {
        default = { "imports", "comment" },
      },
    },
  },

  -- ============================================================================
  -- 3. HARPOON — закладки на 2-5 любимых файлов проекта
  -- ============================================================================

  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "ha", function() require("harpoon"):list():add() end, desc = "Harpoon: add file" },
      {
        "hh",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon: menu",
      },
      { "1", function() require("harpoon"):list():select(1) end, desc = "Harpoon: file 1" },
      { "2", function() require("harpoon"):list():select(2) end, desc = "Harpoon: file 2" },
      { "3", function() require("harpoon"):list():select(3) end, desc = "Harpoon: file 3" },
      { "4", function() require("harpoon"):list():select(4) end, desc = "Harpoon: file 4" },
      { "5", function() require("harpoon"):list():select(5) end, desc = "Harpoon: file 5" },
      { "hn", function() require("harpoon"):list():next() end, desc = "Harpoon: next" },
      { "hp", function() require("harpoon"):list():prev() end, desc = "Harpoon: prev" },
    },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup({
        settings = {
          save_on_toggle = true,
          sync_on_ui_close = true,
        },
      })
    end,
  },
}