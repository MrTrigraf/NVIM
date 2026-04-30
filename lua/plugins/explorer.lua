-- lua/plugins/explorer.lua
-- Neo-tree — дерево файлов в левом сплите.
-- В VS Code аналог: Ctrl+Shift+E (панель Explorer).

return {
  { "MunifTanjim/nui.nvim", lazy = true },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-mini/mini.icons",
      "MunifTanjim/nui.nvim",
    },

    cmd = "Neotree",

    deactivate = function()
      vim.cmd("Neotree close")
    end,

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
      open_files_do_not_replace_types = {
        "terminal", "Trouble", "trouble", "qf",
      },

      source_selector = {
        winbar         = true,
        statusline     = false,
        sources        = {
          { source = "filesystem", display_name = " File" },
          { source = "buffers",    display_name = "󰈙 Bufs" },
          { source = "git_status", display_name = " Git"  },
        },
        content_layout = "center",
        tabs_layout    = "equal",
        separator      = { left = "▏", right = "▕" },
      },

      default_component_configs = {
        indent = {
          indent_size        = 2,
          padding            = 0,
          with_markers       = true,
          highlight          = "NeoTreeIndentMarker",
          with_expanders     = true,
          expander_collapsed = "",
          expander_expanded  = "",
          expander_highlight = "NeoTreeExpander",
        },

        -- Иконки + кастомный provider для папок
        icon = {
          highlight = "NeoTreeFileIcon",

          provider = function(icon, node, state)
            local folder_icons = {
              -- Точки входа и оркестрация
              cmd            = { 0xf120,  "MiniIconsAzure"  },
              main           = { 0xf135,  "MiniIconsYellow" },
              bin            = { 0xf471,  "MiniIconsAzure"  },

              -- Конфигурация
              config         = { 0xe615,  "MiniIconsCyan"   },
              configs        = { 0xe615,  "MiniIconsCyan"   },
              settings       = { 0xe615,  "MiniIconsCyan"   },
              env            = { 0xf462,  "MiniIconsYellow" },

              -- Исходники
              src            = { 0xf121,  "MiniIconsBlue"   },
              lib            = { 0xf121,  "MiniIconsBlue"   },
              internal       = { 0xf07b,  "MiniIconsYellow" },
              pkg            = { 0xf487,  "MiniIconsGreen"  },
              core           = { 0xf2db,  "MiniIconsRed"    },

              -- Архитектурные слои
              usecase        = { 0xf085,  "MiniIconsYellow" },
              usecases       = { 0xf085,  "MiniIconsYellow" },
              service        = { 0xf013,  "MiniIconsCyan"   },
              services       = { 0xf013,  "MiniIconsCyan"   },
              repository     = { 0xf1c0,  "MiniIconsGreen"  },
              repositories   = { 0xf1c0,  "MiniIconsGreen"  },
              infrastructure = { 0xf233,  "MiniIconsOrange" },

              -- HTTP / API
              api            = { 0xf462,  "MiniIconsBlue"   },
              client         = { 0xf109,  "MiniIconsBlue"   },
              server         = { 0xf233,  "MiniIconsGreen"  },
              router         = { 0xf126,  "MiniIconsPurple" },
              routes         = { 0xf126,  "MiniIconsPurple" },
              http           = { 0xf07b,  "MiniIconsAzure"  },
              grpc           = { 0xf07b,  "MiniIconsAzure"  },

              -- Данные
              db             = { 0xf1c0,  "MiniIconsBlue"   },
              database       = { 0xf1c0,  "MiniIconsBlue"   },
              migrations     = { 0xf021,  "MiniIconsRed"    },
              migration      = { 0xf021,  "MiniIconsRed"    },

              -- Тесты
              tests          = { 0xf188,  "MiniIconsYellow" },
              test           = { 0xf188,  "MiniIconsYellow" },
              __tests__      = { 0xf188,  "MiniIconsYellow" },
              mocks          = { 0xf12e,  "MiniIconsPurple" },
              mock           = { 0xf12e,  "MiniIconsPurple" },
              fixtures       = { 0xf12e,  "MiniIconsCyan"   },
              e2e            = { 0xf188,  "MiniIconsRed"    },

              -- Утилиты
              utils          = { 0xf0ad,  "MiniIconsYellow" },
              util           = { 0xf0ad,  "MiniIconsYellow" },
              helpers        = { 0xf0ad,  "MiniIconsOrange" },
              helper         = { 0xf0ad,  "MiniIconsOrange" },
              common         = { 0xf0ad,  "MiniIconsCyan"   },
              shared         = { 0xf0ad,  "MiniIconsCyan"   },
              tools          = { 0xf0ad,  "MiniIconsAzure"  },

              -- Стили / ассеты
              styles         = { 0xe749,  "MiniIconsOrange" },
              css            = { 0xe749,  "MiniIconsOrange" },
              assets         = { 0xf03e,  "MiniIconsAzure"  },
              images         = { 0xf03e,  "MiniIconsAzure"  },
              img            = { 0xf03e,  "MiniIconsAzure"  },
              icons          = { 0xf03e,  "MiniIconsYellow" },
              fonts          = { 0xf031,  "MiniIconsPurple" },
              static         = { 0xf6ff,  "MiniIconsCyan"   },
              scripts        = { 0xf121,  "MiniIconsYellow" },

              -- DevOps
              docker         = { 0xf308,  "MiniIconsAzure"  },
              ["docker-compose"] = { 0xf308, "MiniIconsAzure" },
              k8s            = { 0xf10b,  "MiniIconsBlue"   },
              kubernetes     = { 0xf10b,  "MiniIconsBlue"   },
              terraform      = { 0xe69d,  "MiniIconsPurple" },
              ansible        = { 0xf434,  "MiniIconsRed"    },

              -- CI/CD / системные
              [".git"]         = { 0xe5fb, "MiniIconsOrange" },
              [".github"]      = { 0xe5fd, "MiniIconsPurple" },
              [".gitlab"]      = { 0xf296, "MiniIconsOrange" },
              [".vscode"]      = { 0xe70c, "MiniIconsBlue"   },
              [".idea"]        = { 0xe7b5, "MiniIconsRed"    },
              ["node_modules"] = { 0xe5fa, "MiniIconsRed"    },
              vendor           = { 0xe5fa, "MiniIconsOrange" },
              target           = { 0xf471, "MiniIconsRed"    },
              build            = { 0xf471, "MiniIconsAzure"  },
              dist             = { 0xf471, "MiniIconsGreen"  },
            }

            if node.type == "directory" then
              local custom = folder_icons[node.name:lower()]
              if custom then
                icon.text      = vim.fn.nr2char(custom[1])
                icon.highlight = custom[2]
              end
            elseif node.type == "file" then
              local ok, devicons = pcall(require, "nvim-web-devicons")
              if ok then
                local devicon, devhl = devicons.get_icon(node.name, node.ext, { default = true })
                if devicon then
                  icon.text      = devicon
                  icon.highlight = devhl
                end
              end
            end
          end,
        },

        modified = {
          symbol    = "●",
          highlight = "NeoTreeModified",
        },
        name = {
          trailing_slash        = false,
          use_git_status_colors = true,
        },
        git_status = {
          symbols = {},
        },
      },

      window = {
        position = "left",
        width    = 32,
        mappings = {
          ["l"]     = "open",
          ["h"]     = "close_node",
          ["<cr>"]  = "open",
          ["v"]     = "open_vsplit",
          ["s"]     = "open_split",
          ["P"]     = { "toggle_preview", config = { use_float = true } },
          ["a"]     = { "add", config = { show_path = "relative" } },
          ["A"]     = "add_directory",
          ["d"]     = "delete",
          ["r"]     = "rename",
          ["c"]     = "copy",
          ["m"]     = "move",
          ["y"]     = "copy_to_clipboard",
          ["x"]     = "cut_to_clipboard",
          ["p"]     = "paste_from_clipboard",
          ["Y"] = {
            function(state)
              vim.fn.setreg("+", state.tree:get_node():get_id(), "c")
            end,
            desc = "Copy path to clipboard",
          },
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

      -- Unicode-символы через nr2char
      opts.default_component_configs.icon.folder_closed        = vim.fn.nr2char(0xe5ff)
      opts.default_component_configs.icon.folder_open          = vim.fn.nr2char(0xe5fe)
      opts.default_component_configs.icon.folder_empty         = vim.fn.nr2char(0xe5fd)
      opts.default_component_configs.icon.default              = vim.fn.nr2char(0xf15b)
      opts.default_component_configs.indent.expander_collapsed = vim.fn.nr2char(0xf0142)
      opts.default_component_configs.indent.expander_expanded  = vim.fn.nr2char(0xf0140)

      opts.default_component_configs.git_status.symbols.added     = "+"
      opts.default_component_configs.git_status.symbols.modified  = "~"
      opts.default_component_configs.git_status.symbols.deleted   = "✖"
      opts.default_component_configs.git_status.symbols.renamed   = "➜"
      opts.default_component_configs.git_status.symbols.untracked = "★"
      opts.default_component_configs.git_status.symbols.ignored   = "◌"
      opts.default_component_configs.git_status.symbols.unstaged  = "✗"
      opts.default_component_configs.git_status.symbols.staged    = "✓"
      opts.default_component_configs.git_status.symbols.conflict  = ""

      require("neo-tree").setup(opts)

      vim.api.nvim_create_autocmd("TermClose", {
        pattern = "*lazygit",
        callback = function()
          if package.loaded["neo-tree.sources.git_status"] then
            require("neo-tree.sources.git_status").refresh()
          end
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "neo-tree",
        callback = function()
          vim.opt_local.cursorline = false
        end,
      })
    end,
  },
}


