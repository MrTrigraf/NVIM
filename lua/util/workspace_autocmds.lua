-- lua/util/workspace_autocmds.lua
-- Autocmd-обвязка вокруг workspaces.nvim.

local helpers = require("util.workspace_helpers")

local group = vim.api.nvim_create_augroup("UserWorkspaces", { clear = true })

-- ---------------------------------------------------------------------------
-- VimEnter: при каждом старте nvim регистрируем текущий cwd в workspaces.nvim.
-- Если запись уже есть — workspaces.add() обновит last_opened (MRU поднимет
-- запись в топ при сортировке).
--
-- vim.schedule нужен из-за гонки: workspaces.nvim грузится по VeryLazy,
-- который срабатывает ПОСЛЕ VimEnter. К моменту работы scheduled-callback'а
-- плагин уже загружен.
-- ---------------------------------------------------------------------------
vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  desc = "Auto-register current cwd in workspaces.nvim",
  callback = function()
    vim.schedule(function()
      -- pcall на случай, если плагин всё-таки не загрузился (сломанный spec).
      local ok, ws = pcall(require, "workspaces")
      if not ok then return end

      local cwd = vim.fn.getcwd()
      if vim.fn.isdirectory(cwd) == 0 then return end

      -- Проверка: есть ли уже запись с таким путём.
      -- Плагин хранит пути с хвостовым слэшем — нормализуем для сравнения.
      local cwd_normalized = cwd:gsub("/$", "") .. "/"
      for _, entry in ipairs(ws.get() or {}) do
        if entry.path == cwd_normalized then
          -- Запись уже есть. Просто обновляем MRU через повторный add() —
          -- плагин не создаст дубликата, но обновит last_opened.
          ws.add(cwd, entry.name)
          return
        end
      end

      -- Записи нет — генерируем уникальное имя и добавляем.
      local name = helpers.gen_unique_name(cwd)
      ws.add(cwd, name)
    end)
  end,
})