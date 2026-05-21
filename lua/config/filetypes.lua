-- lua/config/filetypes.lua
-- Кастомные правила определения filetype для нестандартных имён.
-- Использует современный API vim.filetype.add (Neovim 0.7+).
--
-- Зачем:
-- 1. Конфиг-шаблоны: ".example", ".template", ".sample", ".dist" —
--    например, config.yaml.example. Без этого правила Neovim оставляет
--    filetype пустым, и ни LSP, ни syntax highlight не активируются.
-- 2. Docker Compose: файлы compose.yml / docker-compose.yml должны
--    получать filetype "yaml.docker-compose" — это то, на чём слушает
--    docker_compose_language_service. Без явного маппинга Neovim
--    отдаёт просто "yaml", и compose-LSP не приатачивается.

local cfg_exts = { "yaml", "yml", "json", "toml" }
local tmpl_suffixes = { "example", "template", "sample", "dist" }

-- Собираем таблицу паттернов программно — короче, чем 16 строк руками.
-- Lua-паттерн ".*%.yaml%.example" значит:
--   .*       — любое начало имени
--   %.yaml   — буквальное ".yaml" (% экранирует точку)
--   %.example — буквальное ".example"
local patterns = {}
for _, ext in ipairs(cfg_exts) do
  -- .yml-файлы стандартно отображаются на filetype "yaml" — то же самое
  -- делаем и для шаблонных вариаций.
  local target_ft = (ext == "yml") and "yaml" or ext
  for _, suffix in ipairs(tmpl_suffixes) do
    patterns[".*%." .. ext .. "%." .. suffix] = target_ft
  end
end

-- Дополнительно: compose-варианты с суффиксами окружения
-- (compose.dev.yml, docker-compose.prod.yaml и т.п.)
patterns["compose%..*%.ya?ml"]        = "yaml.docker-compose"
patterns["docker%-compose%..*%.ya?ml"] = "yaml.docker-compose"

vim.filetype.add({
  -- Точное совпадение имени файла → filetype.
  filename = {
    ["compose.yml"]         = "yaml.docker-compose",
    ["compose.yaml"]        = "yaml.docker-compose",
    ["docker-compose.yml"]  = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
  },
  -- Совпадение по Lua-паттерну.
  pattern = patterns,
})