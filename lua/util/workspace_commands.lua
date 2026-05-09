-- lua/util/workspace_commands.lua
-- Команды и keymap'ы для пиннинга проектов.
local pinned = require("util.pinned_projects")

-- ── :Pin / <leader>fa — закрепить текущий cwd ─────────────────────────
local function pin_cwd()
  local cwd = vim.fn.getcwd()

  if pinned.is_pinned(cwd) then
    vim.notify("Уже закреплён: " .. cwd, vim.log.levels.INFO)
    return
  end

  local entry = pinned.add(cwd)
  if entry then
    vim.notify("Закреплён: " .. entry.name .. "  →  " .. cwd, vim.log.levels.INFO)
    -- Если дашборд открыт — перерисовать.
    if vim.bo.filetype == "snacks_dashboard" then
      vim.schedule(function() Snacks.dashboard() end)
    end
  end
end

-- ── :Unpin / <leader>fu — открепить через vim.ui.select ───────────────
local function unpin_select()
  local list = pinned.list()

  if #list == 0 then
    vim.notify("Нечего откреплять — список Projects пуст", vim.log.levels.WARN)
    return
  end

  -- Готовим items для vim.ui.select.
  local items = {}
  for _, e in ipairs(list) do
    table.insert(items, { entry = e })
  end

  vim.ui.select(items, {
    prompt = "Открепить проект:",
    format_item = function(item)
      -- В select показываем "name  path".
      return string.format("%-20s  %s", item.entry.name, item.entry.path)
    end,
  }, function(choice)
    if not choice then return end  -- отмена

    local removed = pinned.remove(choice.entry.path)
    if removed then
      vim.notify("Откреплён: " .. choice.entry.name, vim.log.levels.INFO)
      if vim.bo.filetype == "snacks_dashboard" then
        vim.schedule(function() Snacks.dashboard() end)
      end
    end
  end)
end

-- ── Регистрация команд (на случай если удобнее набрать команду)
vim.api.nvim_create_user_command("Pin",   pin_cwd,      { desc = "Pin current cwd" })
vim.api.nvim_create_user_command("Unpin", unpin_select, { desc = "Unpin a pinned project" })

-- ── Keymap'ы ──────────────────────────────────────────────────────────
vim.keymap.set("n", "<leader>fa", pin_cwd,      { desc = "Pin current cwd" })
vim.keymap.set("n", "<leader>fu", unpin_select, { desc = "Unpin a pinned project" })

-- <leader>fp — пикер истории workspaces (telescope).
-- require живёт ВНУТРИ функции-обёртки: workspace_pickers тянет telescope,
-- а тот ленивый — на старте nvim его ещё нет на runtimepath.
vim.keymap.set("n", "<leader>fp", function()
  require("util.workspace_pickers").pick_workspaces()
end, { desc = "Workspaces history (telescope)" })

-- <leader>fP — пикер закреплённых проектов (telescope), <C-d> для unpin.
vim.keymap.set("n", "<leader>fP", function()
  require("util.workspace_pickers").pick_pinned()
end, { desc = "Pinned projects (telescope)" }) 
