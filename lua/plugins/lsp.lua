-- lua/plugins/lsp.lua
-- LSP-инфраструктура: Mason + nvim-lspconfig + lsp_signature.nvim +
-- fidget.nvim + LspAttach.

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
        "json-lsp",
        "taplo",
        "dockerfile-language-server",
        "docker-compose-language-service",
        "lua-language-server",
        "bash-language-server",
        "marksman",
      },
      auto_update  = false,
      run_on_start = true,
      start_delay  = 3000,
    },
  },

  -- ────────────────────────────────────────────────────────────────────
  -- lsp_signature.nvim: подсказка сигнатуры функции при наборе ( и ,.
  -- ────────────────────────────────────────────────────────────────────
  {
    "ray-x/lsp_signature.nvim",
    event = "LspAttach",
    opts = {
      bind = true,

      floating_window = false,

      hint_enable = true,
      hint_prefix = "\u{25B8} ",
      hint_scheme = "Comment",

      hi_parameter = "Search",

      handler_opts = { border = "rounded" },

      always_trigger = false,

      toggle_key = nil,
      select_signature_key = nil,
    },
  },

  -- ────────────────────────────────────────────────────────────────────
  -- fidget.nvim: toast LSP-прогресса в правом нижнем углу.
  -- ────────────────────────────────────────────────────────────────────
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {
      progress = {
        display = {
          progress_icon = { pattern = "dots" },
          done_icon = "\u{2713}",
        },
      },
      notification = {
        window = {
          winblend = 0,
        },
      },
    },
  },

  -- ────────────────────────────────────────────────────────────────────
  -- SchemaStore.nvim: каталог JSON/YAML-схем со SchemaStore.org.
  -- ────────────────────────────────────────────────────────────────────
  {
    "b0o/SchemaStore.nvim",
    lazy    = true,
    version = false,
  },

  -- nvim-lspconfig + LspAttach + все серверы.
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
          map("i", "<C-k>", vim.lsp.buf.signature_help, "LSP: Signature help")

          -- ── Code actions ─────────────────────────────────────────
          map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "LSP: Code action (all)")
          map("n", "<leader>lq", function()
            vim.lsp.buf.code_action({
              context = { only = { "quickfix" } },
              apply   = true,
            })
          end, "LSP: Quick fix")
          map("n", "<leader>lr", vim.lsp.buf.rename, "LSP: Rename symbol")

          -- ── Code lens ────────────────────────────────────────────
          if client:supports_method("textDocument/codeLens") then
            map("n", "<leader>lc", vim.lsp.codelens.run, "LSP: Run code lens")
            vim.lsp.codelens.enable(true, { bufnr = bufnr })
          end

          -- ── Inlay hints ──────────────────────────────────────────
          if client:supports_method("textDocument/inlayHint") then
            map("n", "<leader>li", function()
              local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
            end, "LSP: Toggle inlay hints")
          end

          -- ── Document highlight ───────────────────────────────────
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
      -- yamlls.
      -- ──────────────────────────────────────────────────────────────
      vim.lsp.config("yamlls", {
        filetypes    = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
        root_markers = { ".git" },
        settings = {
          yaml = {
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
                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = {
                  "compose.yml",
                  "compose.yaml",
                  "compose.*.yml",
                  "compose.*.yaml",
                  "docker-compose.yml",
                  "docker-compose.yaml",
                  "docker-compose.*.yml",
                  "docker-compose.*.yaml",
                },
              }
            ),

            validate   = true,
            hover      = true,
            completion = true,

            format = { enable = false },

            telemetry = { enabled = false },

            keyOrdering = false,
          },
          redhat = { telemetry = { enabled = false } },
        },
      })

      vim.lsp.enable("yamlls")

      -- ──────────────────────────────────────────────────────────────
      -- jsonls.
      -- ──────────────────────────────────────────────────────────────
      vim.lsp.config("jsonls", {
        filetypes    = { "json", "jsonc" },
        root_markers = { ".git" },
        settings = {
          json = {
            schemas  = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      })

      vim.lsp.enable("jsonls")

      -- ──────────────────────────────────────────────────────────────
      -- taplo (TOML).
      -- ──────────────────────────────────────────────────────────────
      vim.lsp.config("taplo", {
        filetypes    = { "toml" },
        root_markers = { ".taplo.toml", "taplo.toml", ".git" },
      })

      vim.lsp.enable("taplo")

      -- ──────────────────────────────────────────────────────────────
      -- dockerls.
      -- ──────────────────────────────────────────────────────────────
      vim.lsp.config("dockerls", {
        filetypes    = { "dockerfile" },
        root_markers = { "Dockerfile", ".git" },
      })

      vim.lsp.enable("dockerls")

      -- ──────────────────────────────────────────────────────────────
      -- docker_compose_language_service.
      -- ──────────────────────────────────────────────────────────────
      vim.lsp.config("docker_compose_language_service", {
        filetypes    = { "yaml.docker-compose" },
        root_markers = { "docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml", ".git" },
      })

      vim.lsp.enable("docker_compose_language_service")

      -- ──────────────────────────────────────────────────────────────
      -- lua_ls (Lua language server).
      -- ──────────────────────────────────────────────────────────────
      -- Знает Neovim API через workspace.library — даёт автокомплит
      -- для vim.api.*, vim.keymap.*, vim.lsp.*, hover на функции
      -- Neovim. Globals { "vim" } говорит серверу, что vim — известная
      -- глобальная переменная (иначе будет warning на каждом
      -- использовании).
      vim.lsp.config("lua_ls", {
        filetypes    = { "lua" },
        root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", "stylua.toml", ".git" },
        settings = {
          Lua = {
            runtime = {
              -- Neovim использует LuaJIT (не Lua 5.4).
              version = "LuaJIT",
            },
            workspace = {
              -- Не сканировать сторонние библиотеки (slow, не нужно).
              checkThirdParty = false,
              -- Подключить рантайм Neovim как библиотеку — даёт
              -- автокомплит и hover на vim.* API.
              library = vim.api.nvim_get_runtime_file("", true),
            },
            diagnostics = {
              -- "vim" — известная глобальная переменная.
              globals = { "vim" },
            },
            telemetry = { enable = false },
          },
        },
      })

      vim.lsp.enable("lua_ls")

      -- ──────────────────────────────────────────────────────────────
      -- bashls (bash language server).
      -- ──────────────────────────────────────────────────────────────
      -- Автокомплит, hover, базовая валидация для bash/sh скриптов
      -- (bootstrap.sh, Makefile-команды в shell-форме, обычные
      -- скрипты). fish-файлы НЕ обслуживает — для них достаточно
      -- встроенной подсветки fish.
      vim.lsp.config("bashls", {
        filetypes    = { "sh", "bash" },
        root_markers = { ".git" },
      })

      vim.lsp.enable("bashls")

      -- ──────────────────────────────────────────────────────────────
      -- marksman (Markdown language server).
      -- ──────────────────────────────────────────────────────────────
      -- Кросс-ссылки между файлами, автокомплит для [[wiki-links]],
      -- folding по заголовкам, references на заголовки внутри
      -- проекта.
      vim.lsp.config("marksman", {
        filetypes    = { "markdown" },
        root_markers = { ".marksman.toml", ".git" },
      })

      vim.lsp.enable("marksman")
    end,
  },
}