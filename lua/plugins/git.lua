-- ~/.config/nvim/lua/plugins/git.lua
-- Git workflow.
-- Шаг 1: gitsigns.nvim — знаки изменений в gutter, навигация по hunk'ам,
--        stage/reset/preview hunk, inline-blame текущей строки.
-- Шаг 2: lazygit (Snacks.terminal) + telescope git_status picker
--        + diffview.nvim (полноэкранный diff и file history).
--
-- Hunk = связанный блок изменённых соседних строк. git считает hunk
-- атомарной единицей стейджинга (git add -p работает по hunk'ам).
--
-- Раскладка <leader>g*:
--   gg  — lazygit (плавающее окно через snacks.terminal)
--   gs  — telescope git_status (picker изменённых файлов)
--   gb  — toggle inline-blame (gitsigns)
--   gd  — DiffviewOpen (полноэкранный diff рабочего дерева)
--   gD  — DiffviewClose
--   gf  — DiffviewFileHistory % (история текущего файла)
--   gF  — DiffviewFileHistory  (история всего репо)
--   gh* — операции с hunk'ами (gitsigns):
--         ghp превью, ghs stage, ghr reset, ghu undo-stage,
--         ghS stage-buffer, ghR reset-buffer,
--         ghd diff-vs-index, ghD diff-vs-HEAD, ghb full-blame
--
-- Внутри lazygit:
--   <C-q> — скрыть окно (lazygit-процесс продолжает жить).
--           Снова показать: <leader>gg. Перехватывается Neovim'ом
--           ДО lazygit, так что сам lazygit этой клавиши не видит.
--   q     — закрыть lazygit полностью (нативная клавиша lazygit).
--
-- Внутри diffview:
--   q     — закрыть diffview (переопределено через opts.keymaps).

return {
  -------------------------------------------------------------------------
  -- 1) gitsigns.nvim (Шаг 1)
  -------------------------------------------------------------------------
  {
    "lewis6991/gitsigns.nvim",
    -- грузим как только открыт реальный файл (а не пустой стартовый буфер)
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- знаки в gutter (sign column слева от номеров).
      -- Все глифы — стандартный Unicode (block elements), не Nerd Font.
      -- Через \u{} — на случай если копипаста съест символ.
      signs = {
        add          = { text = "\u{258E}" }, -- ▎ тонкая вертикальная черта
        change       = { text = "\u{258E}" }, -- ▎
        delete       = { text = "\u{2581}" }, -- ▁ нижняя восьмушка
        topdelete    = { text = "\u{2594}" }, -- ▔ верхняя восьмушка
        changedelete = { text = "\u{258E}" }, -- ▎
        untracked    = { text = "\u{2506}" }, -- ┆ пунктирная вертикальная
      },
      -- те же символы, но для уже staged hunk'ов (после git add).
      -- gitsigns показывает их отдельно — видно, что отстейджено, а что нет.
      signs_staged = {
        add          = { text = "\u{258E}" },
        change       = { text = "\u{258E}" },
        delete       = { text = "\u{2581}" },
        topdelete    = { text = "\u{2594}" },
        changedelete = { text = "\u{258E}" },
      },
      signs_staged_enable = true,

      -- inline-blame: серый виртуальный текст в конце текущей строки
      -- с автором и сообщением последнего коммита. По умолчанию выключен,
      -- включается тогглом <leader>gb (см. on_attach ниже).
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 500,
        ignore_whitespace = false,
      },
      current_line_blame_formatter = "<author>, <author_time:%R> \u{2022} <summary>",

      -- стиль всплывающего окна для preview_hunk (<leader>ghp)
      preview_config = {
        border = "rounded",
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1,
      },

      -- on_attach срабатывает на каждый буфер, к которому подключается
      -- gitsigns. Маппинги навешиваем здесь — так они buffer-local
      -- (не работают вне git-буферов) и не засоряют глобальное пространство.
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
        end

        -- Навигация по hunk'ам. ]X / [X — vim-конвенция "следующий/предыдущий".
        map("n", "]h", function() gs.nav_hunk("next") end, "Git: next hunk")
        map("n", "[h", function() gs.nav_hunk("prev") end, "Git: previous hunk")

        -- Операции с hunk'ами под префиксом <leader>gh* (h = hunk).
        map("n", "<leader>ghp", gs.preview_hunk,    "Hunk: preview")
        map("n", "<leader>ghs", gs.stage_hunk,      "Hunk: stage")
        map("n", "<leader>ghr", gs.reset_hunk,      "Hunk: reset (discard change)")
        map("n", "<leader>ghu", gs.undo_stage_hunk, "Hunk: undo stage")
        map("n", "<leader>ghS", gs.stage_buffer,    "Hunk: stage whole buffer")
        map("n", "<leader>ghR", gs.reset_buffer,    "Hunk: reset whole buffer")
        map("n", "<leader>ghd", gs.diffthis,        "Hunk: diff against index")
        map("n", "<leader>ghD", function() gs.diffthis("~") end, "Hunk: diff against HEAD~")
        map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end,
          "Hunk: full line blame (popup)")

        -- Visual-режим: stage/reset для конкретно выделенных строк
        -- (а не всего hunk'а целиком).
        map("v", "<leader>ghs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Hunk: stage selection")
        map("v", "<leader>ghr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Hunk: reset selection")

        -- Тоггл inline-blame у текущей строки.
        map("n", "<leader>gb", gs.toggle_current_line_blame, "Git: toggle inline blame")

        -- Text object "ih" = inner hunk. Работает с операторами:
        -- vih — выделить hunk visual'ом, dih — удалить hunk, cih — изменить.
        -- Аналога в VS Code нет — это vim-фишка.
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "inner hunk")
      end,
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)

      -- which-key: метки групп, чтобы попап показывал "git" / "hunk",
      -- а не голые буквы. Если which-key старой версии без add() — молча
      -- пропускаем, маппинги от этого не сломаются.
      local ok, wk = pcall(require, "which-key")
      if ok and wk.add then
        wk.add({
          { "<leader>g",  group = "git" },
          { "<leader>gh", group = "hunk" },
        })
      end
    end,
  },

  -------------------------------------------------------------------------
  -- 2) lazygit через Snacks.terminal.
  --    Расширяем уже существующую спеку snacks.nvim только полем keys.
  --    config-функцию snacks НЕ дублируем — она живёт в dashboard.lua,
  --    lazy.nvim сливает поля одноимённых спек.
  -------------------------------------------------------------------------
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>gg",
        function()
          require("snacks").terminal("lazygit", {
            -- стартуем в текущем cwd Neovim; с workspaces.nvim это всегда
            -- корень проекта.
            cwd = vim.fn.getcwd(),
            -- env-метка — для единообразия с конвенцией Блока 8
            -- (snacks различает терминалы по cmd+cwd+env).
            env = { NVIM_TERM = "lazygit" },
            win = {
              position = "float",
              width = 0.9,
              height = 0.9,
              border = "rounded",
              title = " lazygit ",
              title_pos = "center",
              keys = {
                -- Esc в lazygit — "back/cancel", двойной Esc нужен ему
                -- самому (выйти на уровень выше). Глобальный term_normal
                -- (<Esc><Esc> → normal-mode из Блока 8) тут мешал бы —
                -- отключаем именно для этого окна.
                term_normal = false,

                -- <C-q> — скрыть окно lazygit, НЕ убивая процесс.
                -- Маппинг buffer-local на уровне Neovim, перехватывается
                -- ДО того как клавиша уйдёт в lazygit (т.е. сам lazygit
                -- этого нажатия не видит, его "<C-q> quit immediately"
                -- не сработает). Снова показать — <leader>gg. Состояние
                -- lazygit-сессии сохраняется.
                hide_window = {
                  "<c-q>",
                  function(self) self:hide() end,
                  mode = { "n", "t" },
                  desc = "Git: hide lazygit (reopen: <leader>gg)",
                },
              },
            },
          })
        end,
        desc = "Git: lazygit",
      },
    },
  },

  -------------------------------------------------------------------------
  -- 3) telescope git_status — picker изменённых относительно индекса
  --    файлов. Расширяем спеку telescope только полем keys; основная
  --    конфигурация telescope живёт в picker.lua.
  -------------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>gs",
        function() require("telescope.builtin").git_status() end,
        desc = "Git: status (changed files picker)",
      },
    },
  },

  -------------------------------------------------------------------------
  -- 4) diffview.nvim — полноэкранный side-by-side diff и file history.
  --    Открывается в новой вкладке: слева список файлов, справа diff.
  --    Закрытие: <leader>gD, :tabclose или q (переопределено в opts).
  -------------------------------------------------------------------------
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewFileHistory",
      "DiffviewRefresh",
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>",          desc = "Diffview: open" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>",         desc = "Diffview: close" },
      { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: current file history" },
      { "<leader>gF", "<cmd>DiffviewFileHistory<cr>",   desc = "Diffview: whole repo history" },
    },
    opts = {
      enhanced_diff_hl = true, -- более контрастная подсветка diff'а
      view = {
        merge_tool = {
          -- "diff3_mixed" показывает base + ours + theirs одновременно —
          -- современный способ резолвить конфликты.
          layout = "diff3_mixed",
          -- LSP-варнинги во время merge — мусор, отключаем в diffview-окнах.
          disable_diagnostics = true,
        },
      },
      -- Переопределяем клавиши внутри окон diffview. По умолчанию у diffview
      -- q не закрывает — это неинтуитивно, поэтому вешаем q → DiffviewClose
      -- в трёх контекстах: основном view, панели файлов, панели истории.
      -- Остальные дефолтные диффвью-биндинги (<Tab>, gf, ge, и т.д.)
      -- остаются нетронутыми — мы не передаём disable_defaults.
      keymaps = {
        view = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Diffview: close" } },
        },
        file_panel = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Diffview: close" } },
        },
        file_history_panel = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Diffview: close" } },
        },
      },
    },
  },
}