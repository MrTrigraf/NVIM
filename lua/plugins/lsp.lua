-- lua/plugins/lsp.lua
-- LSP-инфраструктура: Mason + nvim-lspconfig + LspAttach с биндингами.
-- Сами серверы (gopls, yamlls и т.п.) подключаются на следующих шагах.

return {
  -- ============================================================================
  -- 1. MASON — менеджер бинарников (LSP-серверы, линтеры, форматтеры, DAP).
  -- Сам по себе ничего не настраивает, только устанавливает.
  -- ============================================================================

  {
    "mason-org/mason.nvim",
    -- Грузим лениво — только при ручных командах Mason. Под LSP нам
    -- этого хватает: mason-lspconfig и mason-tool-installer ниже
    -- сами поднимут mason через свои dependencies.
    cmd = {
      "Mason",
      "MasonInstall",
      "MasonUninstall",
      "MasonUpdate",
      "MasonLog",
    },
    build = ":MasonUpdate",
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed   = "\u{2713}", -- ✓
          package_pending     = "\u{279C}", -- ➜
          package_uninstalled = "\u{2717}", -- ✗
        },
      },
    },
  },

  -- ============================================================================
  -- 2. MASON-TOOL-INSTALLER — декларативный список того, что должно быть
  -- установлено через mason. При запуске плагин докачает недостающее.
  -- Удобно на новой машине: клонировал dotfiles → запустил nvim → всё
  -- установилось само.
  -- ============================================================================

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    event = "VimEnter", -- стартуем после полной загрузки nvim
    opts = {
      -- Список пакетов на установку. Сейчас пусто — наполним
      -- начиная со следующего шага (gopls).
      -- ПРИМЕЧАНИЕ: имена пакетов в Mason могут отличаться от имён
      -- LSP-серверов в lspconfig (например, "lua-language-server" в
      -- mason vs "lua_ls" в lspconfig). Используем mason-имена.
      ensure_installed = {
        -- В шаге 4 добавим: "gopls",
        -- В блоке 6b добавим: "yaml-language-server", "json-lsp",
        --                     "taplo", "dockerfile-language-server",
        --                     "docker-compose-language-service".
      },
      -- Автоматически устанавливать недостающее при старте nvim.
      -- true = установить; false = только сообщать в :Mason; "prompt" = спросить.
      auto_update = false,
      run_on_start = true,
      -- Задержка перед автоустановкой при старте (мс). Маленькая —
      -- не блокирует UI, но даёт mason'у успеть инициализироваться.
      start_delay = 3000,
    },
  },

  -- ============================================================================
  -- 3. NVIM-LSPCONFIG — коллекция рецептов конфигурации для популярных
  -- LSP-серверов. В Neovim 0.11+ работает через новое API:
  --   vim.lsp.config("gopls", {...})  -- задать настройки
  --   vim.lsp.enable("gopls")          -- включить сервер
  -- Сам lspconfig больше не активирует серверы — он только поставляет
  -- дефолты (cmd, root_markers, filetypes) для известных имён.
  --
  -- mason-lspconfig — мост между Mason (где лежат бинарники) и lspconfig
  -- (который их запускает). Прицепляет mason'овский путь автоматически.
  -- ============================================================================

  {
    "neovim/nvim-lspconfig",
    -- Грузим, когда открываем реальный файл. До этого LSP не нужен.
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      -- ──────────────────────────────────────────────────────────────
      -- mason-lspconfig: только мост. Не указываем ensure_installed
      -- здесь — за установку отвечает mason-tool-installer выше.
      -- automatic_enable = false — мы сами вызовем vim.lsp.enable()
      -- для каждого сервера на следующих шагах, чтобы контролировать
      -- порядок и конфиг.
      -- ──────────────────────────────────────────────────────────────
      require("mason-lspconfig").setup({
        ensure_installed = {},
        automatic_enable = false,
      })

      -- ──────────────────────────────────────────────────────────────
      -- LspAttach autocmd: вешаем биндинги в момент, когда LSP реально
      -- приатачился к буферу. Биндинги локальны для этого буфера
      -- (buffer = ev.buf), не глобальны — это позволяет K в буфере без
      -- LSP остаться обычным man-page lookup'ом.
      -- ──────────────────────────────────────────────────────────────
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true }),
        callback = function(ev)
          local bufnr = ev.buf
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if not client then return end

          -- Хелпер: короче вызов vim.keymap.set с buffer-локальным флагом.
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end

          -- ── Навигация по символам ────────────────────────────────
          -- gd / gD / gr / gI / gy — стандартные LSP-биндинги.
          -- В VS Code это F12, Shift+F12 и т.п.
          map("n", "gd", vim.lsp.buf.definition,      "LSP: Go to definition")
          map("n", "gD", vim.lsp.buf.declaration,     "LSP: Go to declaration")
          map("n", "gr", vim.lsp.buf.references,      "LSP: References")
          map("n", "gI", vim.lsp.buf.implementation,  "LSP: Implementation")
          map("n", "gy", vim.lsp.buf.type_definition, "LSP: Type definition")

          -- ── Hover и signature help ───────────────────────────────
          -- K — hover. ВАЖНО: в navigation.lua K уже занят nvim-ufo
          -- (peek folded lines под курсором). Там предусмотрен fallback:
          -- если фолд не свёрнут, вызывается vim.lsp.buf.hover(). Так что
          -- здесь K дополнительно НЕ вешаем — иначе перебьём ufo.peek.
          --
          -- <C-k> в insert-mode — подсказка по сигнатуре функции
          -- (какие параметры она ожидает). В VS Code это всплывающая
          -- панель параметров при наборе "func(".
          map("i", "<C-k>", vim.lsp.buf.signature_help, "LSP: Signature help")

          -- ── Действия с кодом ─────────────────────────────────────
          -- <leader>la — code action (исправить, импортировать, и т.п.).
          --              В VS Code это лампочка / Ctrl+.
          -- <leader>lr — переименовать символ во всём проекте.
          --              В VS Code это F2.
          map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "LSP: Code action")
          map("n", "<leader>lr", vim.lsp.buf.rename, "LSP: Rename symbol")

          -- ── Inlay hints ──────────────────────────────────────────
          -- Inlay hints — серые подсказки прямо в коде: имена параметров,
          -- выведенные типы, и т.п. В VS Code включаются автоматически
          -- для языков, которые это умеют.
          --
          -- Включаем сразу, если сервер поддерживает. Toggle на <leader>li.
          if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            map("n", "<leader>li", function()
              local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
            end, "LSP: Toggle inlay hints")
          end

          -- ── Document highlight ───────────────────────────────────
          -- Подсветка всех вхождений слова под курсором (через LSP, а не
          -- через ripgrep). Аналог "highlight occurrences" в VS Code.
          -- Подсветка появляется на CursorHold (через updatetime=250 мс
          -- из options.lua) и убирается при движении курсора.
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

      -- ──────────────────────────────────────────────────────────────
      -- LspDetach autocmd: чистим document_highlight и inlay hints при
      -- отключении сервера. Иначе подсветки/хинты "залипают" на буфере.
      -- ──────────────────────────────────────────────────────────────
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
    end,
  },
}