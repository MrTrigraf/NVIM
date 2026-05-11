-- lua/util/workspace_autocmds.lua
local helpers = require("util.workspace_helpers")

local group = vim.api.nvim_create_augroup("UserWorkspaces", { clear = true })
local handling_dir_change = false

local function normalize_dir(dir)
  return (dir:gsub("/$", "")) .. "/"
end

local function close_buffers_outside(cwd)
  local keep = normalize_dir(cwd)

  -- Собираем чужие буферы (теперь без проверки name ~= "")
    local to_delete = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
      local ft = vim.bo[buf].filetype
      if ft ~= "neo-tree" and ft ~= "snacks_dashboard" and vim.bo[buf].buftype ~= "nofile" then
        local name = vim.api.nvim_buf_get_name(buf)
        local abs = vim.fn.fnamemodify(name, ":p")
        if not abs:find(keep, 1, true) then
          table.insert(to_delete, buf)
        end
      end
    end
  end

  -- Свои буферы (файлы внутри cwd + любые nofile, включая нашу заглушку)
  local valid_keepers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
      local ft = vim.bo[buf].filetype
      if ft ~= "neo-tree" and ft ~= "snacks_dashboard" then
        local name = vim.api.nvim_buf_get_name(buf)
        local abs = vim.fn.fnamemodify(name, ":p")
        if abs:find(keep, 1, true) or vim.bo[buf].buftype == "nofile" then
          table.insert(valid_keepers, buf)
        end
      end
    end
  end

  -- Если нет ни одного валидного буфера, создаём fallback (на практике он не понадобится)
  local fallback_buf = nil
  if #valid_keepers == 0 then
    fallback_buf = vim.api.nvim_create_buf(true, true)
    vim.bo[fallback_buf].bufhidden = "wipe"
    vim.bo[fallback_buf].buftype = "nofile"
    vim.bo[fallback_buf].modifiable = false
    local project_name = vim.fn.fnamemodify(cwd, ":t")
    vim.api.nvim_buf_set_name(fallback_buf, "Project: " .. project_name)
  end

  -- Замена в окнах и удаление чужих буферов
  for _, buf in ipairs(to_delete) do
    local win_ids = vim.fn.win_findbuf(buf)
    for _, win in ipairs(win_ids) do
      local replacement = valid_keepers[1] or fallback_buf
      local win_buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[win_buf].filetype ~= "neo-tree" then
        pcall(vim.api.nvim_win_set_buf, win, replacement)
      end
    end
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

local function ensure_workspace_registered(cwd)
  local ok, ws = pcall(require, "workspaces")
  if not ok then return end

  local cwd_normalized = normalize_dir(cwd)
  for _, entry in ipairs(ws.get() or {}) do
    if entry.path == cwd_normalized then
      return
    end
  end

  ws.add(cwd, helpers.gen_unique_name(cwd))
end

local function sync_workspace_mru(cwd)
  local ok, ws = pcall(require, "workspaces")
  if not ok then return end

  local cwd_normalized = normalize_dir(cwd)
  for _, entry in ipairs(ws.get() or {}) do
    if entry.path == cwd_normalized then
      ws.open(entry.name)
      return
    end
  end

  ws.add(cwd, helpers.gen_unique_name(cwd))
  helpers.prune_dead()
  helpers.enforce_limit(20)
end

local function reopen_neo_tree_here()
  pcall(function()
    require("neo-tree.command").execute({
      action = "show",
      source = "filesystem",
      position = "left",
      dir = vim.fn.getcwd(),
    })
  end)
end

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function()
    vim.schedule(function()
      local cwd = vim.fn.getcwd()
      if vim.fn.isdirectory(cwd) == 0 then return end
      ensure_workspace_registered(cwd)
      helpers.prune_dead()
      helpers.enforce_limit(20)
    end)
  end,
})

vim.api.nvim_create_autocmd("DirChanged", {
  group = group,
  callback = function()
    if vim.v.event.scope ~= "global" then return end
    if handling_dir_change then return end

    handling_dir_change = true

    local ok, err = xpcall(function()
      local cwd = vim.fn.getcwd()
      if vim.fn.isdirectory(cwd) == 0 then return end

      -- Мягко закрываем все буферы дашборда, чтобы они не мешали
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "snacks_dashboard" then
          pcall(vim.cmd, "bdelete " .. buf)
        end
      end

      close_buffers_outside(cwd)
      sync_workspace_mru(cwd)

      vim.schedule(function()
        reopen_neo_tree_here()
      end)
    end, debug.traceback)

    handling_dir_change = false

    if not ok then
      vim.notify("DirChanged callback failed: " .. tostring(err), vim.log.levels.ERROR)
    end
  end,
})