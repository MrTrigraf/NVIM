-- lua/plugins/lsp.lua
-- LSP-инфраструктура: Mason + nvim-lspconfig + LspAttach с биндингами.

return {
  -- Mason: менеджер бинарников.
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
    build = ":MasonUpdate",
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed   = "\u{2713}",
          package_pending     = "\u{279C}",
          package_uninstalled = "\u{2717}",
        },
      },
    },
  },

  -- mason-tool-installer: декларативный список бинарников.
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    event = "VimEnter",
    opts = {
      ensure_installed = { "gopls" },
      auto_update  = false,
      run_on_start = true,
      start_delay  = 3000,
    },
  },

  -- nvim-lspconfig + LspAttach + gopls.
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {},
        automatic_enable = false,
      })

      -- ──────────────────────────────────────────────────────────────
      -- LspAttach: биндинги в момент приатачивания сервера к буферу.
      -- ──────────────────────────────────────────────────────────────
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true }),
        callback = function(ev)
          local bufnr = ev.buf
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if not client then return end

          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end

          -- ── Навигация по символам ────────────────────────────────
          map("n", "gd", vim.lsp.buf.definition,      "LSP: Go to definition")
          map("n", "gD", vim.lsp.buf.declaration,     "LSP: Go to declaration")
          map("n", "gr", vim.lsp.buf.references,      "LSP: References")
          map("n", "gI", vim.lsp.buf.implementation,  "LSP: Implementation")
          map("n", "gy", vim.lsp.buf.type_definition, "LSP: Type definition")

          -- ── Signature help в Insert (вручную, всегда работает) ───
          -- K биндится в navigation.lua через ufo (peek + LSP hover).
          map("i", "<C-k>", vim.lsp.buf.signature_help, "LSP: Signature help")

          -- ── Code actions ─────────────────────────────────────────
          --   <leader>la — полный список (refactor/source/all).
          --   <leader>lq — quickfix, apply=true применит молча
          --                единственный (привычный Apply Fix из VSCode).
          --   <leader>lr — rename во всём проекте.
          map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "LSP: Code action (all)")
          map("n", "<leader>lq", function()
            vim.lsp.buf.code_action({
              context = { only = { "quickfix" } },
              apply   = true,
            })
          end, "LSP: Quick fix")
          map("n", "<leader>lr", vim.lsp.buf.rename, "LSP: Rename symbol")

          -- ── Code lens ────────────────────────────────────────────
          -- <leader>lc — запустить code lens под курсором (Neovim
          -- показывает меню "▶ run | ▶ debug | ..."). Авто-refresh
          -- ниже периодически обновляет список lens'ов от сервера.
          if client:supports_method("textDocument/codeLens") then
            map("n", "<leader>lc", vim.lsp.codelens.run, "LSP: Run code lens")

            -- Авто-refresh code lens: на входе в буфер, выходе из
            -- insert-режима, и на CursorHold. Lens'ы устаревают при
            -- правках, поэтому refresh нужен регулярно.
            local cl_group = vim.api.nvim_create_augroup("user-lsp-codelens-" .. bufnr, { clear = true })
            vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "CursorHold" }, {
              group  = cl_group,
              buffer = bufnr,
              callback = function()
                pcall(vim.lsp.codelens.refresh, { bufnr = bufnr })
              end,
            })
            -- Первый refresh сразу при attach (асинхронно через schedule,
            -- чтобы дождаться полной готовности клиента).
            vim.schedule(function()
              pcall(vim.lsp.codelens.refresh, { bufnr = bufnr })
            end)
          end

          -- ── Inlay hints (выключены по умолчанию, toggle <leader>li) ─
          if client:supports_method("textDocument/inlayHint") then
            map("n", "<leader>li", function()
              local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
            end, "LSP: Toggle inlay hints")
          end

          -- ── Document highlight (подсветка вхождений на CursorHold) ─
          if client:supports_method("textDocument/documentHighlight") then
            local hl_group = vim.api.nvim_create_augroup("user-lsp-highlight-" .. bufnr, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              group  = hl_group,
              buffer = bufnr,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              group  = hl_group,
              buffer = bufnr,
              callback = vim.lsp.buf.clear_references,
            })
          end

          -- ── Авто signature help при наборе ( и , ─────────────────
          -- Эмулируем поведение VS Code: при наборе открывающей скобки
          -- или запятой внутри вызова функции автоматически открываем
          -- popup со списком параметров.
          --
          -- Реализация: ловим InsertCharPre — это событие, в котором
          -- Vim сообщает символ, ЕЩЁ НЕ вставленный в буфер. Если это
          -- "(" или "," — запускаем signature_help через vim.schedule
          -- (чтобы символ успел вставиться и LSP видел актуальный
          -- контекст).
          --
          -- Активные триггеры берём у самого сервера: для gopls это
          -- "(", ",". Если сервер не объявляет triggerCharacters —
          -- падаем к фиксированному списку.
          if client:supports_method("textDocument/signatureHelp") then
            local triggers = vim.tbl_get(client, "server_capabilities", "signatureHelpProvider", "triggerCharacters")
                          or { "(", "," }

            local trigger_set = {}
            for _, ch in ipairs(triggers) do
              trigger_set[ch] = true
            end

            local sig_group = vim.api.nvim_create_augroup("user-lsp-sighelp-" .. bufnr, { clear = true })
            vim.api.nvim_create_autocmd("InsertCharPre", {
              group  = sig_group,
              buffer = bufnr,
              callback = function()
                if trigger_set[vim.v.char] then
                  vim.schedule(function()
                    -- Открываем только если буфер всё ещё активный и
                    -- мы всё ещё в insert-режиме (пользователь мог
                    -- успеть выйти).
                    if vim.api.nvim_get_current_buf() == bufnr
                       and vim.api.nvim_get_mode().mode:sub(1, 1) == "i"
                    then
                      pcall(vim.lsp.buf.signature_help)
                    end
                  end)
                end
              end,
            })
          end
        end,
      })

      -- LspDetach: чистим autocommands и подсветки при отключении сервера.
      vim.api.nvim_create_autocmd("LspDetach", {
        group = vim.api.nvim_create_augroup("user-lsp-detach", { clear = true }),
        callback = function(ev)
          vim.lsp.buf.clear_references()
          for _, group in ipairs({
            "user-lsp-highlight-" .. ev.buf,
            "user-lsp-codelens-" .. ev.buf,
            "user-lsp-sighelp-" .. ev.buf,
          }) do
            pcall(vim.api.nvim_clear_autocmds, { group = group, buffer = ev.buf })
          end
        end,
      })

      -- ──────────────────────────────────────────────────────────────
      -- gopls.
      -- ──────────────────────────────────────────────────────────────
      vim.lsp.config("gopls", {
        filetypes    = { "go", "gomod", "gowork", "gotmpl" },
        root_markers = { "go.work", "go.mod", ".git" },
        settings = {
          gopls = {
            analyses = {
              unusedparams   = true,
              shadow         = true,
              fieldalignment = false,
              nilness        = true,
              unusedwrite    = true,
              useany         = true,
            },
            staticcheck = true,
            hints = {
              assignVariableTypes    = true,
              compositeLiteralFields = true,
              compositeLiteralTypes  = true,
              constantValues         = true,
              functionTypeParameters = true,
              parameterNames         = true,
              rangeVariableTypes     = true,
            },
            codelenses = {
              generate           = true,
              gc_details         = false,
              regenerate_cgo     = true,
              run_govulncheck    = true,
              test               = true,
              tidy               = true,
              upgrade_dependency = true,
              vendor             = true,
            },
            semanticTokens     = true,
            usePlaceholders    = true,
            completeUnimported = true,
            gofumpt            = true,
            diagnosticsDelay   = "250ms",
          },
        },
      })

      vim.lsp.enable("gopls")
    end,
  },
}