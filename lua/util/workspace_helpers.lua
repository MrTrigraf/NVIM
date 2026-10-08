-- lua/util/workspace_helpers.lua
-- Утилиты для работы с workspaces.nvim:
--   * автогенерация имён с дисамбигуацией конфликтов
--   * автоочистка мёртвых записей (несуществующих папок)
--   * enforce_limit для удержания истории workspaces в пределах N записей
-- Переключение проекта (:cd) и закрытие чужих буферов живут в
-- workspace_autocmds.lua (реакция на DirChanged).
local M = {}

-- ---------------------------------------------------------------------------
-- Helper: безопасный вызов workspaces API.
-- Если плагин ещё не загружен (VeryLazy), возвращаем nil вместо ошибки.
-- ---------------------------------------------------------------------------
local function ws()
  local ok, mod = pcall(require, "workspaces")
  return ok and mod or nil
end

-- ---------------------------------------------------------------------------
-- gen_name(path) → string
-- Возвращает базовое имя для workspace из абсолютного пути.
-- Никакой дисамбигуации не делает — за это отвечает gen_unique_name.
-- ---------------------------------------------------------------------------
function M.gen_name(path)
  -- Нормализация: убираем хвостовой слэш если есть.
  path = path:gsub("/$", "")

  -- Спецслучай: корень файловой системы.
  if path == "" or path == "/" then
    return "root"
  end

  -- Спецслучай: домашняя папка пользователя.
  local home = vim.fn.expand("~"):gsub("/$", "")
  if path == home then
    return "home"
  end

  -- Базовый случай: последняя компонента пути.
  -- fnamemodify(":t") = tail of path = basename.
  local name = vim.fn.fnamemodify(path, ":t")
  if name == "" then
    return "root"
  end

  return name
end

-- ---------------------------------------------------------------------------
-- unique_name(path, entries) → string
-- Имя, не конфликтующее с именами из entries (список { name, path }).
-- Общая логика для workspaces.nvim и pinned_projects.
-- Стратегия:
--   1. basename                       (foo)
--   2. basename + parent in parens    (foo (personal))
--   3. basename + 2 ancestors         (foo (work/personal))
--   4. fallback с числовым суффиксом  (foo #2)
-- ---------------------------------------------------------------------------
function M.unique_name(path, entries)
  path = path:gsub("/$", "")

  -- Собираем set уже занятых имён.
  -- Исключаем запись, у которой path совпадает с нашим (ре-регистрация —
  -- не конфликт, мы хотим сохранить текущее имя для этой папки).
  local taken = {}
  for _, entry in ipairs(entries or {}) do
    if entry.path ~= path then
      taken[entry.name] = true
    end
  end

  -- Попытка 1: чистый basename.
  local base = M.gen_name(path)
  if not taken[base] then
    return base
  end

  -- Попытка 2: basename с именем родительской папки в скобках.
  local parent = vim.fn.fnamemodify(path, ":h:t")
  if parent ~= "" and parent ~= "." and parent ~= "/" then
    local with_parent = string.format("%s (%s)", base, parent)
    if not taken[with_parent] then
      return with_parent
    end

    -- Попытка 3: basename с двумя предками.
    local grandparent = vim.fn.fnamemodify(path, ":h:h:t")
    if grandparent ~= "" and grandparent ~= "." and grandparent ~= "/" then
      local with_two = string.format("%s (%s/%s)", base, grandparent, parent)
      if not taken[with_two] then
        return with_two
      end
    end
  end

  -- Попытка 4: численный суффикс (последний рубеж).
  local n = 2
  while true do
    local candidate = string.format("%s #%d", base, n)
    if not taken[candidate] then
      return candidate
    end
    n = n + 1
    if n > 100 then
      -- Безопасный предохранитель: если что-то совсем сломалось.
      return base .. "_" .. tostring(vim.loop.now())
    end
  end
end

-- ---------------------------------------------------------------------------
-- gen_unique_name(path) → string
-- Уникальное имя относительно записей workspaces.nvim.
-- ---------------------------------------------------------------------------
function M.gen_unique_name(path)
  path = path:gsub("/$", "")
  local plugin = ws()
  if not plugin then
    return M.gen_name(path)
  end
  return M.unique_name(path, plugin.get())
end

-- ---------------------------------------------------------------------------
-- prune_dead() → number
-- Удаляет из workspaces.nvim все записи, чьи пути не существуют на диске.
-- Возвращает количество удалённых.
-- ---------------------------------------------------------------------------
function M.prune_dead()
  local plugin = ws()
  if not plugin then
    return 0
  end

  -- Сначала собираем список к удалению, потом удаляем.
  -- Удаление во время итерации по plugin.get() может побить порядок.
  local to_remove = {}
  for _, entry in ipairs(plugin.get() or {}) do
    if vim.fn.isdirectory(entry.path) == 0 then
      table.insert(to_remove, entry.name)
    end
  end

  for _, name in ipairs(to_remove) do
    plugin.remove(name)
  end

  return #to_remove
end

-- ---------------------------------------------------------------------------
-- enforce_limit(n) → number
-- Если в workspaces.nvim > n записей, удаляет самые старые по MRU (записи
-- с last_opened="" уходят первыми). Возвращает количество удалённых.
-- Вызывается из VimEnter autocmd после prune_dead.
-- ---------------------------------------------------------------------------
function M.enforce_limit(n)
  local plugin = ws()
  if not plugin then return 0 end
  n = n or 20

  local list = plugin.get() or {}
  if #list <= n then return 0 end

  -- Делаем копию для сортировки (не мутируем то, что вернул плагин).
  local sorted = vim.deepcopy(list)
  table.sort(sorted, function(a, b)
    -- Записи без last_opened = пустая строка → их в конец (самые "старые").
    local ao = a.last_opened or ""
    local bo = b.last_opened or ""
    if ao == "" and bo ~= "" then return false end
    if bo == "" and ao ~= "" then return true end
    -- MRU: позже открытые — наверху.
    return ao > bo
  end)

  -- Кандидаты на удаление — всё что после n-го элемента.
  local removed = 0
  for i = n + 1, #sorted do
    plugin.remove(sorted[i].name)
    removed = removed + 1
  end

  return removed
end

return M
