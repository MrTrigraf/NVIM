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
        "json-lsp",
        "taplo",
        "dockerfile-language-server",
        "docker-compose-language-service",
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
  -- yamlls и jsonls берут отсюда схемы через
  -- require("schemastore").yaml.schemas() / .json.schemas().
  -- Поэтому lazy=true: загрузится только когда первый раз позовут.
  -- version=false — всегда свежая main-ветка (схемы обновляются часто).
  --
  -- taplo НЕ использует SchemaStore.nvim — у него собственный встроенный
  -- каталог схем для TOML-файлов (Cargo.toml, pyproject.toml и т.д.).
  {
    "b0o/SchemaStore.nvim",
    lazy    = true,
    version = false,
  },

  -- nvim-lspconfig + LspAttach + gopls + yamlls + jsonls + taplo +
  -- dockerls + docker_compose_language_service.
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
      --
      -- Дополнительно: ключ "kubernetes" в schemas — это магическое
      -- слово yamlls, активирующее его встроенную k8s-схему для
      -- перечисленных path-паттернов. SchemaStore не умеет детектить
      -- k8s по apiVersion/kind, поэтому полагаемся на конвенции имён.
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
      -- jsonls (VS Code JSON Language Server).
      -- ──────────────────────────────────────────────────────────────
      -- Принимает обычный JSON и JSONC (JSON-with-comments, как в
      -- tsconfig.json или .vscode/settings.json).
      -- Схемы — из того же SchemaStore: package.json, tsconfig,
      -- .eslintrc, .prettierrc, .devcontainer.json и сотни других.
      -- Привязка к файлам — по имени, автоматически.
      vim.lsp.config("jsonls", {
        filetypes    = { "json", "jsonc" },
        root_markers = { ".git" },
        settings = {
          json = {
            schemas  = require("schemastore").json.schemas(),
            -- У jsonls validate — это вложенная таблица, а не булеан.
            -- Специфика VS Code JSON Language Server.
            validate = { enable = true },
          },
        },
      })

      vim.lsp.enable("jsonls")

      -- ──────────────────────────────────────────────────────────────
      -- taplo (TOML language server).
      -- ──────────────────────────────────────────────────────────────
      -- taplo написан на Rust и имеет собственный встроенный каталог
      -- TOML-схем: Cargo.toml, pyproject.toml, .taplo.toml, rustfmt.toml
      -- и т.д. Сопоставление со схемой идёт автоматически по имени
      -- файла — наша задача только подключить сервер.
      --
      -- ВНИМАНИЕ: taplo молча исключает файлы вне git-репозитория
      -- (single-file режим без root marker). В /tmp/ работает, но
      -- выдаёт hint-уровень "this document has been excluded" — это
      -- не баг, просто не для прод-валидации. В обычном проекте с
      -- .git всё работает штатно.
      vim.lsp.config("taplo", {
        filetypes    = { "toml" },
        root_markers = { ".taplo.toml", "taplo.toml", ".git" },
      })

      vim.lsp.enable("taplo")

      -- ──────────────────────────────────────────────────────────────
      -- dockerls (Dockerfile language server).
      -- ──────────────────────────────────────────────────────────────
      -- LSP для Dockerfile: автокомплит инструкций (FROM, RUN, COPY,
      -- WORKDIR, ENV, EXPOSE, CMD, ENTRYPOINT и т.д.), hover-документация
      -- на K, базовая валидация синтаксиса.
      --
      -- Глубокие проверки best-practices (избегать ADD, не запускать
      -- от root, использовать конкретные теги вместо latest и т.д.)
      -- делает hadolint — он подключается через nvim-lint в Блоке 7.
      vim.lsp.config("dockerls", {
        filetypes    = { "dockerfile" },
        root_markers = { "Dockerfile", ".git" },
      })

      vim.lsp.enable("dockerls")

      -- ──────────────────────────────────────────────────────────────
      -- docker_compose_language_service.
      -- ──────────────────────────────────────────────────────────────
      -- LSP, специально знающий про compose-spec: автокомплит для
      -- depends_on (предлагает другие сервисы из этого же файла),
      -- semantic-навигация (gd на имя сервиса в depends_on прыгнет
      -- к его определению), hover с описаниями полей.
      --
      -- Работает ПАРАЛЛЕЛЬНО с yamlls на том же файле compose.yml:
      -- yamlls даёт schema-валидацию из SchemaStore, compose-LS —
      -- доменно-специфичные фичи. Это нормальная LSP-практика.
      --
      -- Filetype "yaml.docker-compose" Neovim 0.10+ распознаёт сам
      -- для файлов compose.yml / docker-compose.yml / *.compose.yml.
      vim.lsp.config("docker_compose_language_service", {
        filetypes    = { "yaml.docker-compose" },
        root_markers = { "docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml", ".git" },
      })

      vim.lsp.enable("docker_compose_language_service")
    end,
  },
}