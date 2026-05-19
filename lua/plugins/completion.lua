-- lua/plugins/completion.lua
-- blink.cmp: движок автодополнения + сниппеты (LuaSnip + friendly-snippets).
-- Signature popup: ВКЛ, но БЕЗ авто-триггера — показывается только по <C-k>
-- руками. Inline hint при наборе ( и , даёт ray-x/lsp_signature.nvim
-- (см. lua/plugins/lsp.lua).

return {
  -- ──────────────────────────────────────────────────────────────────
  -- LuaSnip + friendly-snippets.
  -- ──────────────────────────────────────────────────────────────────
  -- LuaSnip — движок сниппетов (плейсхолдеры, Tab-навигация между
  -- ними, регексп-преобразования). friendly-snippets — большая
  -- библиотека готовых сниппетов для десятков языков в формате
  -- VS Code (Go, Lua, YAML, Dockerfile, JSON, SQL, Markdown и т.д.).
  {
    "L3MON4D3/LuaSnip",
    -- Прибиваемся к мажорной версии 2.x — API устоявшийся, но
    -- внутри 2.* возможны фиксы и небольшие фичи.
    version = "v2.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      -- Подгружает все сниппеты VS Code-формата из плагинов,
      -- лежащих в runtimepath. friendly-snippets — главный
      -- поставщик. Lazy_load именно "лениво": сниппеты для каждого
      -- языка читаются только при первом открытии файла этого типа.
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },

  -- ──────────────────────────────────────────────────────────────────
  -- blink.cmp — движок автодополнения.
  -- ──────────────────────────────────────────────────────────────────
  {
    "saghen/blink.cmp",
    -- Прибиваемся к мажорной версии 1.x — стабильный API.
    version = "1.*",

    -- Lazy-load: blink.cmp нужен только когда мы реально начинаем
    -- что-то набирать.
    event = "InsertEnter",

    -- LuaSnip должен быть в runtimepath до setup() blink.cmp,
    -- т.к. snippets.preset = "luasnip" вызывает require("luasnip")
    -- сразу при загрузке.
    dependencies = { "L3MON4D3/LuaSnip" },

    ---@module "blink.cmp"
    ---@type blink.cmp.Config
    opts = {
      -- ──────────────────────────────────────────────────────────────
      -- Keymap preset.
      -- ──────────────────────────────────────────────────────────────
      -- "super-tab" — VS Code-подобное поведение:
      --   <Tab>      — если меню открыто: выбрать первый и принять;
      --                если активен сниппет: прыгнуть на след. placeholder;
      --                иначе: обычный Tab.
      --   <S-Tab>    — назад по сниппету / выбрать предыдущий.
      --   <CR>       — accept (или fallback).
      --   <C-Space>  — открыть меню вручную.
      --   <C-n>/<C-p>— следующий/предыдущий вариант в меню.
      --   <C-e>      — закрыть меню.
      --   <C-b>/<C-f>— скролл документации вверх/вниз.
      --   <C-k>      — показать/спрятать signature popup (наш вариант C:
      --                единственный способ вызвать popup сигнатуры).
      keymap = {
        preset = "super-tab",
      },

      -- ──────────────────────────────────────────────────────────────
      -- Внешний вид.
      -- ──────────────────────────────────────────────────────────────
      appearance = {
        -- JetBrainsMono Nerd Font Mono — все глифы в 1 ячейку.
        nerd_font_variant = "mono",
      },

      -- ──────────────────────────────────────────────────────────────
      -- Completion: меню, документация, авто-скобки.
      -- ──────────────────────────────────────────────────────────────
      completion = {
        -- Авто-вставка скобок при выборе функции из меню.
        -- "Println" -> Tab -> "Println(|)" с курсором внутри.
        accept = {
          auto_brackets = { enabled = true },
        },

        menu = {
          -- Treesitter-подсветка для LSP-итемов в меню.
          draw = {
            treesitter = { "lsp" },
          },
        },

        -- Окно с документацией (preview справа от меню).
        documentation = {
          auto_show          = true,
          auto_show_delay_ms = 200,
        },

        -- Ghost text — серый "призрак" справа от курсора. Отключаем:
        -- у нас уже есть hint от lsp_signature.nvim, два маркера
        -- мешали бы друг другу.
        ghost_text = { enabled = false },
      },

      -- ──────────────────────────────────────────────────────────────
      -- Signature help (Вариант C из обсуждения шага 7.1b).
      -- ──────────────────────────────────────────────────────────────
      -- Popup ВКЛЮЧЁН (enabled = true), но все авто-триггеры
      -- ВЫКЛЮЧЕНЫ. Единственный способ его открыть — <C-k> в Insert
      -- (биндинг из preset = "super-tab"). Это даёт нам:
      --   • Inline hint от lsp_signature.nvim — автоматически при
      --     ( и , (тонкий серый "▸ <param>" рядом с курсором).
      --   • Полный popup в стиле blink.cmp — только по <C-k>, когда
      --     реально нужна полная сигнатура + docstring.
      signature = {
        enabled = true,
        trigger = {
          show_on_trigger_character           = false,
          show_on_insert_on_trigger_character = false,
          show_on_insert                      = false,
          show_on_keyword                     = false,
        },
      },

      -- ──────────────────────────────────────────────────────────────
      -- Источники вариантов автодополнения.
      -- ──────────────────────────────────────────────────────────────
      -- Порядок важен: чем раньше в списке — тем выше приоритет при
      -- одинаковом fuzzy-скоре.
      --   lsp      — от gopls/yamlls/jsonls/и т.д. Самый умный.
      --   path     — пути к файлам/папкам.
      --   snippets — теперь через LuaSnip + friendly-snippets.
      --   buffer   — слова из открытых буферов (low-tech fallback).
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        per_filetype = {
          sql = { "snippets", "dadbod", "buffer" },
        },
        providers = {
          dadbod = {
            name = "Dadbod",
            module = "vim_dadbod_completion.blink",
          },
        },
      },

      -- ──────────────────────────────────────────────────────────────
      -- Snippet engine.
      -- ──────────────────────────────────────────────────────────────
      -- Переключаем источник сниппетов с встроенного vim.snippet
      -- на LuaSnip — даёт доступ к библиотеке friendly-snippets и
      -- более продвинутую логику плейсхолдеров.
      snippets = {
        preset = "luasnip",
      },

      -- ──────────────────────────────────────────────────────────────
      -- Fuzzy matcher.
      -- ──────────────────────────────────────────────────────────────
      -- При первом запуске blink.cmp скачает прекомпилированный
      -- Rust-бинарь (~1 МБ) с GitHub releases. Если не удалось —
      -- упадёт на Lua-реализацию (медленнее) с warning.
      fuzzy = {
        implementation = "prefer_rust_with_warning",
      },
    },
  },
}