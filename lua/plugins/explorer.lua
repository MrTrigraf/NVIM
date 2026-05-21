-- ────────────────────────────────────────────────────────────────────
-- lua/plugins/explorer.lua
-- Neo-tree — дерево файлов в левом сплите.
-- В VS Code аналог: панель Explorer.
-- ────────────────────────────────────────────────────────────────────
local function name_to_highlight(name, ext)
  local by_name = {
    ["Makefile"]            = "NeoTreeFileNameMakefile",
    ["makefile"]            = "NeoTreeFileNameMakefile",
    ["GNUmakefile"]         = "NeoTreeFileNameMakefile",
    ["Dockerfile"]          = "NeoTreeFileNameDocker",
    ["dockerfile"]          = "NeoTreeFileNameDocker",
    ["docker-compose.yml"]  = "NeoTreeFileNameDocker",
    ["docker-compose.yaml"] = "NeoTreeFileNameDocker",
    ["go.mod"]              = "NeoTreeFileNameDim",
    ["go.sum"]              = "NeoTreeFileNameDim",
    [".gitignore"]          = "NeoTreeFileNameDim",
    [".gitattributes"]      = "NeoTreeFileNameDim",
    [".env"]                = "NeoTreeFileNameDim",
    [".editorconfig"]       = "NeoTreeFileNameDim",
  }
  if by_name[name] then return by_name[name] end

  local by_ext = {
    go    = "NeoTreeFileNameGo",
    lua   = "NeoTreeFileNameLua",
    yml   = "NeoTreeFileNameYaml",
    yaml  = "NeoTreeFileNameYaml",
    json  = "NeoTreeFileNameJson",
    toml  = "NeoTreeFileNameToml",
    sh    = "NeoTreeFileNameShell",
    bash  = "NeoTreeFileNameShell",
    fish  = "NeoTreeFileNameShell",
    zsh   = "NeoTreeFileNameShell",
  }
  return by_ext[ext]
end

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
          padding            = 1,
          with_markers       = true,
          highlight          = "NeoTreeIndentMarker",
          with_expanders     = true,
          expander_collapsed = "",
          expander_expanded  = "",
          expander_highlight = "NeoTreeExpander",
        },
        -- Иконки + кастомный provider для папок (цвета в стиле kanagawa-paper)
        icon = {
          highlight = "NeoTreeFileIcon",

          provider = function(icon, node, state)
            -- Цвета папок подобраны из палитры kanagawa-paper (dragon-вариант),
            -- чтобы гармонировать с тёмным фоном темы.
            local folder_icons = {
              -- Точки входа и оркестрация
              cmd                = { 0xf120,  "NeoTreeFolderCmd"    },  -- springBlue
              main               = { 0xf135,  "NeoTreeFolderMain"   },  -- dragonYellow
              bin                = { 0xf471,  "NeoTreeFolderBin"    },  -- dragonAqua

              -- Конфигурация
              config             = { 0xe615,  "NeoTreeFolderConfig" },  -- dragonAqua
              configs            = { 0xe615,  "NeoTreeFolderConfig" },
              settings           = { 0xe615,  "NeoTreeFolderConfig" },
              env                = { 0xf462,  "NeoTreeFolderEnv"    },  -- dragonAqua

              -- Исходный код
              src                = { 0xf121,  "NeoTreeFolderSrc"    },  -- crystalBlue
              lib                = { 0xf121,  "NeoTreeFolderSrc"    },
              internal           = { 0xf07b,  "NeoTreeFolderInternal" },  -- crystalBlue

              -- Пакеты и сборка
              pkg                = { 0xf487,  "NeoTreeFolderPkg"    },  -- dragonGreen
              dist               = { 0xf471,  "NeoTreeFolderPkg"    },
              build              = { 0xf471,  "NeoTreeFolderPkg"    },

              -- Ядро / важное
              core               = { 0xf2db,  "NeoTreeFolderCore"   },  -- dragonRed

              -- Архитектурные слои
              usecase            = { 0xf085,  "NeoTreeFolderUsecase" },  -- dragonYellow
              usecases           = { 0xf085,  "NeoTreeFolderUsecase" },
              service            = { 0xf013,  "NeoTreeFolderService" },  -- dragonAqua
              services           = { 0xf013,  "NeoTreeFolderService" },
              repository         = { 0xf1c0,  "NeoTreeFolderRepo"   },  -- dragonYellow
              repositories       = { 0xf1c0,  "NeoTreeFolderRepo"   },
              infrastructure     = { 0xf233,  "NeoTreeFolderInfra"  },  -- dragonYellow

              -- HTTP / API
              api                = { 0xf462,  "NeoTreeFolderApi"    },  -- springBlue
              client             = { 0xf109,  "NeoTreeFolderApi"    },
              server             = { 0xf233,  "NeoTreeFolderApi"    },
              router             = { 0xf126,  "NeoTreeFolderRouter" },  -- dragonViolet
              routes             = { 0xf126,  "NeoTreeFolderRouter" },
              http               = { 0xf07b,  "NeoTreeFolderHttp"   },  -- springBlue
              grpc               = { 0xf07b,  "NeoTreeFolderHttp"   },

              -- Данные
              db                 = { 0xf1c0,  "NeoTreeFolderDb"     },  -- crystalBlue
              database           = { 0xf1c0,  "NeoTreeFolderDb"     },
              migrations         = { 0xf021,  "NeoTreeFolderMigration" },  -- crystalBlue
              migration          = { 0xf021,  "NeoTreeFolderMigration" },

              -- Тесты
              tests              = { 0xf188,  "NeoTreeFolderTest"    },  -- autumnYellow
              test               = { 0xf188,  "NeoTreeFolderTest"    },
              __tests__          = { 0xf188,  "NeoTreeFolderTest"    },
              mocks              = { 0xf12e,  "NeoTreeFolderMock"    },  -- dragonViolet
              mock               = { 0xf12e,  "NeoTreeFolderMock"    },
              fixtures           = { 0xf12e,  "NeoTreeFolderFixture" },  -- dragonViolet
              e2e                = { 0xf188,  "NeoTreeFolderE2e"     },  -- dragonRed

              -- Утилиты
              utils              = { 0xf0ad,  "NeoTreeFolderUtils"   },  -- boatYellow2
              util               = { 0xf0ad,  "NeoTreeFolderUtils"   },
              helpers            = { 0xf0ad,  "NeoTreeFolderUtils"   },
              helper             = { 0xf0ad,  "NeoTreeFolderUtils"   },
              common             = { 0xf0ad,  "NeoTreeFolderUtils"   },
              shared             = { 0xf0ad,  "NeoTreeFolderUtils"   },
              tools              = { 0xf0ad,  "NeoTreeFolderUtils"   },

              -- Стили / ассеты
              styles             = { 0xe749,  "NeoTreeFolderStyles"  },  -- sakuraPink
              css                = { 0xe749,  "NeoTreeFolderStyles"  },
              assets             = { 0xf03e,  "NeoTreeFolderAssets"  },  -- dragonViolet
              images             = { 0xf03e,  "NeoTreeFolderAssets"  },
              img                = { 0xf03e,  "NeoTreeFolderAssets"  },
              icons              = { 0xf03e,  "NeoTreeFolderAssets"  },
              fonts              = { 0xf031,  "NeoTreeFolderAssets"  },
              static             = { 0xf6ff,  "NeoTreeFolderStatic"  },  -- dragonYellow
              scripts            = { 0xf121,  "NeoTreeFolderScripts" },  -- dragonYellow

              -- DevOps
              docker             = { 0xf308,  "NeoTreeFolderDocker"  },  -- dragonBlue
              ["docker-compose"] = { 0xf308,  "NeoTreeFolderDocker"  },
              k8s                = { 0xf10b,  "NeoTreeFolderK8s"     },  -- springBlue
              kubernetes         = { 0xf10b,  "NeoTreeFolderK8s"     },
              terraform          = { 0xe69d,  "NeoTreeFolderTerraform" },  -- dragonViolet
              ansible            = { 0xf434,  "NeoTreeFolderAnsible" },  -- dragonRed

              -- Системные
              [".git"]         = { 0xe5fb, "NeoTreeFolderGit"     },  -- dragonOrange
              [".github"]      = { 0xe5fd, "NeoTreeFolderGitHub"  },  -- dragonViolet
              [".gitlab"]      = { 0xf296, "NeoTreeFolderGitLab"  },  -- dragonOrange
              [".vscode"]      = { 0xe70c, "NeoTreeFolderVscode"  },  -- springBlue
              [".idea"]        = { 0xe7b5, "NeoTreeFolderIdea"    },  -- dragonRed
              ["node_modules"] = { 0xe5fa, "NeoTreeFolderNodeModules" },  -- dragonRed
              vendor           = { 0xe5fa, "NeoTreeFolderVendor"  },  -- dragonOrange
              target           = { 0xf471, "NeoTreeFolderTarget"  },  -- dragonRed
            }

            if node.type == "directory" then
              local custom = folder_icons[node.name:lower()]
              if custom then
                icon.text      = vim.fn.nr2char(custom[1])
                icon.highlight = custom[2]
              else
                -- Для папок без кастомной иконки оставляем стандартную иконку и цвет, заданный темой
                icon.highlight = "NeoTreeDirectoryIcon"
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
          use_git_status_colors = false,         
        },
        git_status = {
          symbols = {},
        },
      },

      window = {
        position = "left",
        width    = 28,
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
        follow_current_file    = { enabled = false },
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

        -- КЛЮЧЕВОЙ БЛОК: переопределяем компонент имени файла
        components = {
          name = function(config, node, state)
            -- Стандартный компонент (со всеми настройками из default_component_configs)
            local component = require("neo-tree.sources.common.components").name(config, node, state)
            -- Если это обычный файл (не корень), подменяем highlight
            if node.type == "file" and node:get_depth() > 1 then
              local custom_hl = name_to_highlight(node.name, node.ext)
              if custom_hl then
                component.highlight = custom_hl
              end
            end
            return component
          end,
        },
      },
    },

    config = function(_, opts)
      vim.g.loaded_netrw       = 1
      vim.g.loaded_netrwPlugin = 1

      -- Unicode-символы через nr2char (оставлено как было)
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

      -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      -- Определяем цвета для кастомных иконок папок, используя палитру
      -- kanagawa-paper (dragon-вариант). Эти группы будут использоваться
      -- в icon.provider.
      -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      local folder_colors = {
        ["NeoTreeFolderCmd"]        = "#7FB4CA", -- springBlue
        ["NeoTreeFolderMain"]       = "#C4B28A", -- dragonYellow
        ["NeoTreeFolderBin"]        = "#8EA49E", -- dragonAqua
        ["NeoTreeFolderConfig"]     = "#8EA49E", -- dragonAqua
        ["NeoTreeFolderEnv"]        = "#8EA49E",
        ["NeoTreeFolderSrc"]        = "#7E9CD8", -- crystalBlue
        ["NeoTreeFolderInternal"]   = "#7E9CD8",
        ["NeoTreeFolderPkg"]        = "#699469", -- dragonGreen
        ["NeoTreeFolderCore"]       = "#C4746E", -- dragonRed
        ["NeoTreeFolderUsecase"]    = "#C4B28A", -- dragonYellow
        ["NeoTreeFolderService"]    = "#8EA49E",
        ["NeoTreeFolderRepo"]       = "#C4B28A",
        ["NeoTreeFolderInfra"]      = "#C4B28A",
        ["NeoTreeFolderApi"]        = "#7FB4CA",
        ["NeoTreeFolderRouter"]     = "#8992A7", -- dragonViolet
        ["NeoTreeFolderHttp"]       = "#7FB4CA",
        ["NeoTreeFolderDb"]         = "#7E9CD8",
        ["NeoTreeFolderMigration"]  = "#7E9CD8",
        ["NeoTreeFolderTest"]       = "#DCA561", -- autumnYellow
        ["NeoTreeFolderMock"]       = "#8992A7",
        ["NeoTreeFolderFixture"]    = "#8992A7",
        ["NeoTreeFolderE2e"]        = "#C4746E",
        ["NeoTreeFolderUtils"]      = "#C0A36E", -- boatYellow2
        ["NeoTreeFolderStyles"]     = "#D27E99", -- sakuraPink
        ["NeoTreeFolderAssets"]     = "#8992A7",
        ["NeoTreeFolderStatic"]     = "#C4B28A",
        ["NeoTreeFolderScripts"]    = "#C4B28A",
        ["NeoTreeFolderDocker"]     = "#658594", -- dragonBlue
        ["NeoTreeFolderK8s"]        = "#7FB4CA",
        ["NeoTreeFolderTerraform"]  = "#8992A7",
        ["NeoTreeFolderAnsible"]    = "#C4746E",
        ["NeoTreeFolderGit"]        = "#B6927B", -- dragonOrange
        ["NeoTreeFolderGitHub"]     = "#8992A7",
        ["NeoTreeFolderGitLab"]     = "#B6927B",
        ["NeoTreeFolderVscode"]     = "#7FB4CA",
        ["NeoTreeFolderIdea"]       = "#C4746E",
        ["NeoTreeFolderNodeModules"]= "#C4746E",
        ["NeoTreeFolderVendor"]     = "#B6927B",
        ["NeoTreeFolderTarget"]     = "#C4746E",
      }

      for group, color in pairs(folder_colors) do
        vim.api.nvim_set_hl(0, group, { fg = color, default = true })
      end

      -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      -- Цвета имён файлов по расширению. Hex'ы взяты из той же палитры
      -- kanagawa-paper, что и folder_colors. Меняй здесь — это и есть
      -- место, где живёт цветовая «политика файлов».
      -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      local file_colors = {
        ["NeoTreeFileNameGo"]       = "#7FB4CA", -- crystalBlue   (.go)
        ["NeoTreeFileNameLua"]      = "#8992A7", -- dragonViolet  (.lua)
        ["NeoTreeFileNameYaml"]     = "#C4B28A", -- dragonYellow  (.yml/.yaml)
        ["NeoTreeFileNameJson"]     = "#C0A36E", -- boatYellow2   (.json)
        ["NeoTreeFileNameToml"]     = "#DCA561", -- autumnYellow  (.toml)
        ["NeoTreeFileNameShell"]    = "#699469", -- dragonGreen   (.sh/.bash/.fish/.zsh)
        ["NeoTreeFileNameDocker"]   = "#658594", -- dragonBlue    (Dockerfile, docker-compose)
        ["NeoTreeFileNameMakefile"] = "#B6927B", -- dragonOrange  (Makefile)
        ["NeoTreeFileNameDim"]      = "#727169", -- fujiGray      (go.mod, .gitignore, .env)
      }

      for group, color in pairs(file_colors) do
        vim.api.nvim_set_hl(0, group, { fg = color, default = true })
      end

      -- Цвета иконок git-статуса (свои группы, чтобы тема не перебивала)
      local git_status_colors = {
        GitStatusAdded     = "#699469", -- dragonGreen
        GitStatusModified  = "#DCA561", -- autumnYellow
        GitStatusDeleted   = "#C4746E", -- dragonRed
        GitStatusRenamed   = "#7FB4CA", -- springBlue
        GitStatusUntracked = "#B6927B", -- dragonOrange
        GitStatusIgnored   = "#727169", -- fujiGray
        GitStatusUnstaged  = "#C4746E", -- dragonRed
        GitStatusStaged    = "#699469", -- dragonGreen
        GitStatusConflict  = "#C4746E", -- dragonRed
      }

      for group, color in pairs(git_status_colors) do
        vim.api.nvim_set_hl(0, group, { fg = color, default = true })
      end

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
          vim.opt_local.cursorline   = false
        end,
      })
      
      vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
        pattern = "neo-tree*",
        callback = function(args)
          local buf = args.buf or vim.api.nvim_get_current_buf()
          if vim.bo[buf].filetype == "neo-tree" or vim.bo[buf].filetype == "neo-tree-popup" then
            vim.wo.statuscolumn = ""
            vim.wo.foldcolumn = "0"
          end
        end,
      })
    end,
  },
}


