-- lua/plugins/lsp.lua
-- LSP-инфраструктура. На этом шаге — только Mason: менеджер бинарников
-- для LSP-серверов, линтеров, форматтеров и debug-адаптеров.
-- Сами серверы (gopls, yamlls и т.п.) будут подключены позже.

return {
  {
    "mason-org/mason.nvim",
    -- Грузим лениво — только когда руками вызвали одну из команд Mason.
    -- Под gopls/lspconfig мы потом добавим явный dependency, чтобы
    -- Mason поднимался ДО запуска LSP-серверов.
    cmd = {
      "Mason",
      "MasonInstall",
      "MasonUninstall",
      "MasonUpdate",
      "MasonLog",
    },
    -- При первой установке (и при :Lazy update) обновляем реестр
    -- пакетов Mason — список доступных серверов/линтеров.
    build = ":MasonUpdate",
    opts = {
      ui = {
        -- Скруглённая рамка окна Mason — единый стиль со всем UI.
        border = "rounded",
        -- Чёткие глифы статусов установленных пакетов.
        -- Nerd Font у нас есть, поэтому символы рендерятся корректно.
        icons = {
          package_installed   = "✓",
          package_pending     = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },
}