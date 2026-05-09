-- lua/util/workspace_pickers.lua
-- Кастомные telescope-пикеры для workspaces (БД №1) и pinned (БД №2).
-- Шаг 19a: только pick_workspaces. pick_pinned + pick_for_pin — в 19b/19c.
--
-- ВАЖНО: все require'ы telescope живут ВНУТРИ функций, а не на верхнем
-- уровне модуля. Причина: workspace_commands.lua подтягивается из
-- autocmds.lua на старте nvim, когда telescope ещё не загружен (он
-- ленивый). Если require сделать наверху файла — модуль упадёт сразу
-- при загрузке. Внутри функции require отрабатывает в момент нажатия
-- <leader>fp, к этому времени lazy.nvim уже поднимет telescope.

local M = {}

-- Превращает /home/<user>/foo в ~/foo для красивого вывода в пикере.
-- Чистая функция без внешних зависимостей — можно держать наверху.
local function pretty_path(path)
  return vim.fn.fnamemodify((path or ""):gsub("/$", ""), ":~")
end

-- ---------------------------------------------------------------------------
-- Пикер 1: <leader>fp — Workspaces history (БД №1)
-- ---------------------------------------------------------------------------
function M.pick_workspaces()
  -- Все telescope-модули — внутри функции (см. комментарий в шапке файла).
  local pickers       = require("telescope.pickers")
  local finders       = require("telescope.finders")
  local conf          = require("telescope.config").values
  local actions       = require("telescope.actions")
  local action_state  = require("telescope.actions.state")
  local entry_display = require("telescope.pickers.entry_display")

  local ok, ws = pcall(require, "workspaces")
  if not ok then
    vim.notify("workspaces.nvim не загружен", vim.log.levels.ERROR)
    return
  end

  local results = ws.get() or {}
  if #results == 0 then
    vim.notify("История workspaces пуста", vim.log.levels.INFO)
    return
  end

  -- Двухколоночный displayer: имя 24 символа, остаток — путь.
  local displayer = entry_display.create({
    separator = "  ",
    items = {
      { width = 24 },
      { remaining = true },
    },
  })

  pickers.new({}, {
    prompt_title = "Workspaces (history)",
    finder = finders.new_table({
      results = results,
      entry_maker = function(w)
        return {
          value   = w.path,
          -- ordinal — строка, по которой telescope ищет fuzzy-матчем.
          -- Кладём имя + путь, чтобы можно было искать и по тому, и по другому.
          ordinal = w.name .. " " .. w.path,
          name    = w.name,
          path    = w.path,
          display = function(e)
            return displayer({
              { e.name,              "TelescopeResultsIdentifier" },
              { pretty_path(e.path), "TelescopeResultsComment" },
            })
          end,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      -- <CR>: переключиться через ws.open() — это обновит MRU в плагине.
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not entry then return end
        ws.open(entry.name)
      end)

      -- <C-d>: удалить запись из истории и переоткрыть пикер.
      map({ "i", "n" }, "<C-d>", function()
        local entry = action_state.get_selected_entry()
        if not entry then return end
        ws.remove(entry.name)
        actions.close(prompt_bufnr)
        -- vim.schedule: даём telescope доработать свои close-хуки,
        -- потом открываем пикер заново.
        vim.schedule(M.pick_workspaces)
      end)

      return true  -- остальные дефолтные маппинги telescope не трогаем
    end,
  }):find()
end

-- ---------------------------------------------------------------------------
-- Пикер 2: <leader>fP — Pinned projects (БД №2)
-- ---------------------------------------------------------------------------
function M.pick_pinned()
  -- Все telescope-модули — внутри функции (см. комментарий в шапке файла).
  local pickers       = require("telescope.pickers")
  local finders       = require("telescope.finders")
  local conf          = require("telescope.config").values
  local actions       = require("telescope.actions")
  local action_state  = require("telescope.actions.state")
  local entry_display = require("telescope.pickers.entry_display")

  local pinned = require("util.pinned_projects")

  local results = pinned.list()
  if #results == 0 then
    vim.notify(
      "Список Projects пуст. Закрепи текущую папку через <leader>fa.",
      vim.log.levels.INFO
    )
    return
  end

  -- Двухколоночный displayer — повторяем стиль pick_workspaces.
  local displayer = entry_display.create({
    separator = "  ",
    items = {
      { width = 24 },
      { remaining = true },
    },
  })

  pickers.new({}, {
    prompt_title = "Pinned projects",
    finder = finders.new_table({
      results = results,
      entry_maker = function(p)
        return {
          value   = p.path,
          ordinal = p.name .. " " .. p.path,
          name    = p.name,
          path    = p.path,
          display = function(e)
            return displayer({
              { e.name,              "TelescopeResultsIdentifier" },
              { pretty_path(e.path), "TelescopeResultsComment" },
            })
          end,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      -- <CR>: cd в выбранный проект.
      -- Не используем helpers.switch() — он подключается в шаге 20 вместе
      -- с DirChanged-autocmd (политика буферов 3 + neo-tree refresh).
      -- Пока — простой :cd, как у pick_workspaces.
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not entry then return end
        vim.cmd("cd " .. vim.fn.fnameescape(entry.path))
        vim.notify("Перешёл в: " .. entry.name, vim.log.levels.INFO)
      end)

      -- <C-d>: открепить и переоткрыть пикер.
      map({ "i", "n" }, "<C-d>", function()
        local entry = action_state.get_selected_entry()
        if not entry then return end
        local removed = pinned.remove(entry.path)
        if removed then
          vim.notify("Откреплён: " .. entry.name, vim.log.levels.INFO)
          -- Если открыт дашборд — перерисовать.
          if vim.bo.filetype == "snacks_dashboard" then
            vim.schedule(function() Snacks.dashboard() end)
          end
        end
        actions.close(prompt_bufnr)
        vim.schedule(M.pick_pinned)
      end)

      return true
    end,
  }):find()
end

return M