-- lua/util/pinned_projects.lua
-- CRUD над JSON-файлом ~/.local/share/nvim/pinned_projects.json.
-- Шаг 6/10: только Lua API. UI в шагах 7-9.

local M = {}

-- ---------------------------------------------------------------------------
-- Файл хранения. Создаётся лениво при первом save().
-- ---------------------------------------------------------------------------
local STORE_PATH = vim.fn.stdpath("data") .. "/pinned_projects.json"

-- ---------------------------------------------------------------------------
-- Внутренние утилиты
-- ---------------------------------------------------------------------------

-- Нормализация пути: абсолютный, без хвостового слэша.
local function normalize(path)
  if not path or path == "" then return nil end
  local abs = vim.fn.fnamemodify(path, ":p")
  return (abs:gsub("/$", ""))
end

-- Текущая дата в ISO-8601 (для pinned_at).
local function now_iso()
  return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

-- Базовое имя из пути с учётом спецслучаев (root, home).
local function basename_for(path)
  local home = vim.fn.expand("~"):gsub("/$", "")
  if path == home then return "home" end
  if path == "" or path == "/" then return "root" end
  local n = vim.fn.fnamemodify(path, ":t")
  return (n ~= "" and n) or "root"
end

-- Уникальное имя в рамках pinned-листа.
-- Стратегия идентична gen_unique_name из workspace_helpers, но проверка
-- против pinned-БД (не против workspaces.nvim).
local function gen_unique_name(path, list)
  local taken = {}
  for _, e in ipairs(list) do
    if e.path ~= path then taken[e.name] = true end
  end

  local base = basename_for(path)
  if not taken[base] then return base end

  local parent = vim.fn.fnamemodify(path, ":h:t")
  if parent ~= "" and parent ~= "." and parent ~= "/" then
    local with_parent = string.format("%s (%s)", base, parent)
    if not taken[with_parent] then return with_parent end

    local grandparent = vim.fn.fnamemodify(path, ":h:h:t")
    if grandparent ~= "" and grandparent ~= "." and grandparent ~= "/" then
      local with_two = string.format("%s (%s/%s)", base, grandparent, parent)
      if not taken[with_two] then return with_two end
    end
  end

  local n = 2
  while true do
    local cand = string.format("%s #%d", base, n)
    if not taken[cand] then return cand end
    n = n + 1
    if n > 100 then return base .. "_" .. tostring(vim.loop.now()) end
  end
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

-- load(): table[]
-- Читает JSON. Возвращает пустой массив, если файла нет или JSON битый.
function M.load()
  local stat = vim.loop.fs_stat(STORE_PATH)
  if not stat then return {} end

  local fd = vim.loop.fs_open(STORE_PATH, "r", 438) -- 0666
  if not fd then return {} end
  local data = vim.loop.fs_read(fd, stat.size, 0)
  vim.loop.fs_close(fd)
  if not data or data == "" then return {} end

  local ok, decoded = pcall(vim.json.decode, data)
  if not ok or type(decoded) ~= "table" then
    vim.notify(
      "pinned_projects: битый JSON в " .. STORE_PATH .. ", использую пустой список",
      vim.log.levels.WARN
    )
    return {}
  end
  return decoded
end

-- save(list): nil
-- Пишет массив в JSON. Создаёт директорию, если нужно.
function M.save(list)
  local dir = vim.fn.fnamemodify(STORE_PATH, ":h")
  vim.fn.mkdir(dir, "p")

  local encoded = vim.json.encode(list or {})

  local fd = vim.loop.fs_open(STORE_PATH, "w", 420) -- 0644
  if not fd then
    vim.notify("pinned_projects: не могу открыть " .. STORE_PATH .. " для записи",
      vim.log.levels.ERROR)
    return
  end
  vim.loop.fs_write(fd, encoded, 0)
  vim.loop.fs_close(fd)
end

-- list(): table[]
-- Копия текущего списка для использования снаружи.
function M.list()
  return M.load()
end

-- is_pinned(path): bool
function M.is_pinned(path)
  local p = normalize(path)
  if not p then return false end
  for _, e in ipairs(M.load()) do
    if e.path == p then return true end
  end
  return false
end

-- add(path, name?): entry | nil
-- nil если уже закреплён или путь невалидный.
function M.add(path, name)
  local p = normalize(path)
  if not p then return nil end
  if vim.fn.isdirectory(p) == 0 then
    vim.notify("pinned_projects: путь не существует: " .. p, vim.log.levels.ERROR)
    return nil
  end

  local list = M.load()
  for _, e in ipairs(list) do
    if e.path == p then return nil end
  end

  local entry_name = name and name ~= "" and name or gen_unique_name(p, list)
  local entry = { path = p, name = entry_name, pinned_at = now_iso() }
  -- Новые записи — в начало списка (новейшее сверху).
  table.insert(list, 1, entry)
  M.save(list)
  return entry
end

-- remove(path): bool
function M.remove(path)
  local p = normalize(path)
  if not p then return false end

  local list = M.load()
  local kept, removed = {}, false
  for _, e in ipairs(list) do
    if e.path == p then
      removed = true
    else
      table.insert(kept, e)
    end
  end

  if removed then M.save(kept) end
  return removed
end

-- prune_dead(): number
-- Удаляет записи с несуществующими путями.
function M.prune_dead()
  local list = M.load()
  local kept, removed = {}, 0
  for _, e in ipairs(list) do
    if vim.fn.isdirectory(e.path) == 1 then
      table.insert(kept, e)
    else
      removed = removed + 1
    end
  end

  if removed > 0 then M.save(kept) end
  return removed
end

-- reorder(paths): bool
-- Переупорядочивает по переданному списку путей. Записи, которых нет в paths,
-- сохраняются в конце в исходном порядке. Записи в paths, которых нет в БД,
-- игнорируются.
function M.reorder(paths)
  local list = M.load()
  local by_path = {}
  for _, e in ipairs(list) do by_path[e.path] = e end

  local new_list = {}
  local seen = {}

  for _, p in ipairs(paths) do
    local norm = normalize(p)
    if norm and by_path[norm] then
      table.insert(new_list, by_path[norm])
      seen[norm] = true
    end
  end

  -- Хвост: записи, которых не было в paths.
  for _, e in ipairs(list) do
    if not seen[e.path] then table.insert(new_list, e) end
  end

  M.save(new_list)
  return true
end

return M