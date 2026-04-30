-- lua/plugins/explorer.lua
-- Neo-tree — дерево файлов в левом сплите.
-- В VS Code аналог: Ctrl+Shift+E (панель Explorer).

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",

    -- Корректное закрытие при деактивации плагина
    deactivate = function()
      vim.cmd("Neotree close")
    end,

    -- Ленивая загрузка: если nvim запущен с папкой (`nvim .`) — подгрузить neo-tree
    init = function()
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("Neotree_start_directory", { clear = true }),
        once = true,
        callback = function()
          if package.loaded["neo-tree"] then return end
          local stats = vim.uv.fs_stat(vim.fn.argv(0))
          if stats and stats.type == "directory" then
            require("neo-tree")
          end
        end,
      })
    end,

    keys = {
      {
        "<leader>e",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
        end,
        desc = "Explorer (neo-tree)",
      },
      {
        "<leader>E",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.fn.expand("%:p:h") })
        end,
        desc = "Explorer (current file dir)",
      },
    },

    opts = {
      sources = { "filesystem", "buffers", "git_status" },
      close_if_last_window = true,
      open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf" },

      -- Вкладки File / Bufs / Git в шапке панели
      source_selector = {
        winbar         = true,
        statusline     = false,
        sources        = {
          { source = "filesystem", display_name = " File" },
          { source = "buffers",    display_name = "󰈙 Bufs" },
          { source = "git_status", display_name = " Git"  },
        },
        content_layout = "center",
        tabs_layout    = "equal",
        separator      = { left = "▏", right = "▕" },
      },

      default_component_configs = {
        -- Линии отступов и стрелки разворачивания
        indent = {
          indent_size        = 2,
          padding            = 1,
          with_markers       = true,
          with_expanders     = true,
          highlight          = "NeoTreeIndentMarker",
          expander_highlight = "NeoTreeExpander",
          -- символы expander_collapsed/expanded задаются в config через nr2char
          -- из-за проблем с кодировкой Unicode при редактировании файла
        },
        -- Иконки папок и дефолтная иконка файла (задаются в config)
        icon = {
          highlight = "NeoTreeFileIcon",
        },
        modified = {
          symbol    = "●",
          highlight = "NeoTreeModified",
        },
        name = {
          trailing_slash        = false,
          use_git_status_colors = true,
        },
        -- ASCII-символы git-статуса — гарантированно рендерятся в любом терминале
        git_status = {
          symbols = {
            added     = "A",
            modified  = "M",
            deleted   = "D",
            renamed   = "R",
            untracked = "?",
            ignored   = "!",
            unstaged  = "U",
            staged    = "S",
            conflict  = "C",
          },
        },
      },

      -- Глобальные маппинги — работают во всех трёх вкладках (File/Bufs/Git)
      window = {
        position = "left",
        width    = 32,
        mappings = {
          -- Открыть файл / развернуть папку
          ["l"]     = "open",
          ["h"]     = "close_node",
          ["<cr>"]  = "open",
          -- Открыть в сплитах
          ["v"]     = "open_vsplit",
          ["s"]     = "open_split",
          ["P"]     = { "toggle_preview", config = { use_float = true } },
          -- Операции с файлами
          ["a"]     = { "add", config = { show_path = "relative" } },
          ["A"]     = "add_directory",
          ["d"]     = "delete",
          ["r"]     = "rename",
          ["c"]     = "copy",
          ["m"]     = "move",
          ["y"]     = "copy_to_clipboard",
          ["x"]     = "cut_to_clipboard",
          ["p"]     = "paste_from_clipboard",
          -- Скопировать полный путь файла в системный буфер обмена
          ["Y"] = {
            function(state)
              vim.fn.setreg("+", state.tree:get_node():get_id(), "c")
            end,
            desc = "Copy path to clipboard",
          },
          -- Открыть файл системным приложением (xdg-open на Linux)
          ["O"] = {
            function(state)
              vim.fn.jobstart({ "xdg-open", state.tree:get_node().path }, { detach = true })
            end,
            desc = "Open with system application",
          },
          ["R"]     = "refresh",
          ["q"]     = "close_window",
          ["<esc>"] = "close_window",
        },
      },

      filesystem = {
        bind_to_cwd            = false,
        follow_current_file    = { enabled = true, leave_dirs_open = false },
        use_libuv_file_watcher = true,
        filtered_items = {
          visible         = false,
          hide_dotfiles   = false,
          hide_gitignored = true,
          hide_by_name    = { ".git", "node_modules" },
        },
        -- Маппинги только для вкладки File (не работают в Bufs/Git)
        window = {
          mappings = {
            ["H"] = "toggle_hidden",
            ["<"] = "navigate_up",
            ["."] = "set_root",
          },
        },
      },
    },

    config = function(_, opts)
      vim.g.loaded_netrw       = 1
      vim.g.loaded_netrwPlugin = 1

      -- Unicode-символы задаются здесь через nr2char,
      -- потому что копирование иконок через чат портит кодировку
      opts.default_component_configs.icon.folder_closed       = vim.fn.nr2char(0xe5ff)
      opts.default_component_configs.icon.folder_open         = vim.fn.nr2char(0xe5fe)
      opts.default_component_configs.icon.folder_empty        = vim.fn.nr2char(0xe5fd)
      opts.default_component_configs.icon.default             = vim.fn.nr2char(0xf15b)
      opts.default_component_configs.indent.expander_collapsed = vim.fn.nr2char(0xf0142)
      opts.default_component_configs.indent.expander_expanded  = vim.fn.nr2char(0xf0140)

      require("neo-tree").setup(opts)

      -- Обновить git-статус в neo-tree после закрытия lazygit
      vim.api.nvim_create_autocmd("TermClose", {
        pattern = "*lazygit",
        callback = function()
          if package.loaded["neo-tree.sources.git_status"] then
            require("neo-tree.sources.git_status").refresh()
          end
        end,
      })

      -- Убрать подсветку текущей строки в панели neo-tree (как в LazyVim)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "neo-tree",
        callback = function()
          vim.opt_local.cursorline = false
        end,
      })
    end,
  },
}