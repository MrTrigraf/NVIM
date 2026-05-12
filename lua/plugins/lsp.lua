-- lua/plugins/lsp.lua
-- LSP-инфраструктура: Mason + nvim-lspconfig + lsp_signature.nvim + LspAttach.

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
      ensure_installed = {
        "gopls",
        "yaml-language-server",
      },
      auto_update  = false,
      run_on_start = true,
      start_delay  = 3000,
    },
  },

  -- ────────────────────────────────────────────────────────────────────
  -- lsp_signature.nvim: подсказка сигнатуры функции при наборе ( и ,.
  -- ────────────────────────────────────────────────────────────────────
  -- Режим: hint-only — серый ghost-текст рядом с курсором с именем
  -- активного параметра, без всплывающего окна. VS Code-аналог:
  -- Parameter Hints, но не popup, а inline-подсказка.
  --
  -- Если захочется ещё и floating popup (полная сигнатура с типами):
  --   floating_window = true
  -- Полный popup всё равно доступен вручную через <C-k> ниже —
  -- плагин перехватит стандартный handler и нарисует красиво.
  {
    "ray-x/lsp_signature.nvim",
    event = "LspAttach",
    opts = {
      -- Обязательный флаг — без него кастомные border/highlight не
      -- регистрируются (требование плагина).
      bind = true,

      -- Floating window выключен: видим только hint.
      floating_window = false,

      -- Hint mode: inline ghost-текст с именем активного параметра.
      hint_enable = true,
      hint_prefix = "\u{25B8} ",   -- ▸ — маркер перед параметром
      hint_scheme = "Comment",     -- highlight-группа (серый тон)

      -- Подсветка активного параметра внутри popup (для <C-k>).
      hi_parameter = "Search",

      -- Граница floating-окна — используется при ручном <C-k>.
      handler_opts = { border = "rounded" },

      -- Не показывать пустой ответ от сервера ("(no signature)").
      always_trigger = false,

      -- Свои биндинги плагина выключены — у нас уже <C-k> в LspAttach.
      toggle_key = nil,
      select_signature_key = nil,
    },
  },

  -- ────────────────────────────────────────────────────────────────────
  -- SchemaStore.nvim: каталог JSON/YAML-схем со SchemaStore.org.
  -- ────────────────────────────────────────────────────────────────────
  -- Сам по себе ничего не делает — это библиотека-таблица.
  -- yamlls и (позже) jsonls берут отсюда схемы через
  -- require("schemastore").yaml.schemas() / .json.schemas().
  -- Поэтому lazy=true: загрузится только когда первый раз позовут.
  -- version=false — всегда свежая main-ветка (схемы обновляются часто).
  {
    "b0o/SchemaStore.nvim",
    lazy    = true,
    version = false,
  },

  -- nvim-lspconfig + LspAttach + gopls + yamlls.
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

          -- ── Signature help (ручной вызов) ────────────────────────
          -- <C-k> в insert: открывает полное floating-окно с сигнатурой
          -- (lsp_signature.nvim перехватывает handler и стилизует его).
          -- Авто-подсказка inline идёт через lsp_signature.nvim (выше).
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
          -- <leader>lc — запустить code lens под курсором.
          -- В Neovim 0.12+ enable() сам поддерживает lens'ы свежими.
          if client:supports_method("textDocument/codeLens") then
            map("n", "<leader>lc", vim.lsp.codelens.run, "LSP: Run code lens")
            vim.lsp.codelens.enable(true, { bufnr = bufnr })
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
        end,
      })

      -- LspDetach: чистим document_highlight группу и подсветки.
      vim.api.nvim_create_autocmd("LspDetach", {
        group = vim.api.nvim_create_augroup("user-lsp-detach", { clear = true }),
        callback = function(ev)
          vim.lsp.buf.clear_references()
          pcall(vim.api.nvim_clear_autocmds, {
            group  = "user-lsp-highlight-" .. ev.buf,
            buffer = ev.buf,
          })
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

      -- ──────────────────────────────────────────────────────────────
      -- yamlls (Red Hat YAML language server).
      -- ──────────────────────────────────────────────────────────────
      -- Схемы берём из b0o/SchemaStore.nvim — это даёт ~700 актуальных
      -- схем со SchemaStore.org (Kubernetes, docker-compose, GitHub
      -- Actions, GitLab CI, OpenAPI, kustomization и т.д.). Сервер
      -- сам сопоставляет схему по паттерну пути файла.
      vim.lsp.config("yamlls", {
        filetypes    = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
        root_markers = { ".git" },
        settings = {
          yaml = {
            -- Отключаем встроенный SchemaStore yamlls — у него своя
            -- (устаревшая) база. Используем только b0o/SchemaStore.
            schemaStore = {
              enable = false,
              url    = "",
            },
            schemas = vim.tbl_extend("force",
              require("schemastore").yaml.schemas(),
              {
                kubernetes = {
                  "k8s/**/*.{yml,yaml}",
                  "kubernetes/**/*.{yml,yaml}",
                  "manifests/**/*.{yml,yaml}",
                  "kustomization.{yml,yaml}",
                  "*deployment.{yml,yaml}",
                  "*statefulset.{yml,yaml}",
                  "*daemonset.{yml,yaml}",
                  "*service.{yml,yaml}",
                  "*ingress.{yml,yaml}",
                  "*configmap.{yml,yaml}",
                  "*pvc.{yml,yaml}",
                },
              }
            ),

            -- Включаем валидацию, hover, автокомплит.
            validate   = true,
            hover      = true,
            completion = true,

            -- Форматирование внутри yamlls слабое — оставляем
            -- conform.nvim/prettier в Блоке 7.
            format = { enable = false },

            -- Гасим телеметрию Red Hat (иначе при первом запуске
            -- будет всплывающий вопрос про опт-ин).
            telemetry = { enabled = false },

            -- Чтобы k8s-схемы корректно подхватывались по apiVersion +
            -- kind, нужно дополнительно включить kubernetes-режим.
            -- Применяется к файлам с kubernetes-подобной структурой.
            keyOrdering = false,
          },
          -- Альтернативный путь, который yamlls тоже читает.
          redhat = { telemetry = { enabled = false } },
        },
      })

      vim.lsp.enable("yamlls")
    end,
  },
}