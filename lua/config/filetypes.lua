-- lua/config/filetypes.lua
-- Кастомные правила определения filetype для нестандартных имён.
-- Использует современный API vim.filetype.add (Neovim 0.7+).
--
-- Зачем: распространённая конвенция класть в репо "шаблон конфига" с
-- суффиксом ".example", ".template", ".sample" или ".dist" — например,
-- config.yaml.example. Neovim не знает таких расширений и оставляет
-- filetype пустым, поэтому ни LSP, ни syntax highlight, ни SchemaStore
-- не активируются. Здесь явно маппим эти варианты на базовый тип.

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

vim.filetype.add({
  pattern = patterns,
})