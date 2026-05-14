-- lua/plugins/linting.lua
-- nvim-lint: запуск внешних линтеров, вывод вливается в vim.diagnostic
-- (те же squiggles / ]d / [d / trouble, что и у LSP).
--   Go         -> golangcilint (металинтер, ~50 линтеров под капотом)
--   Dockerfile -> hadolint (best practices для Dockerfile)
-- Линтеры дополняют gopls/dockerls, а не заменяют их.

return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },

  config = function()
    local lint = require("lint")

    -- ────────────────────────────────────────────────────────────────
    -- Какой линтер для какого filetype.
    -- ────────────────────────────────────────────────────────────────
    -- ВАЖНО: имя линтера здесь — "golangcilint" БЕЗ дефиса. Это имя
    -- модуля внутри nvim-lint. Mason-пакет при этом называется
    -- "golangci-lint" С дефисом — легко перепутать.
    lint.linters_by_ft = {
      go         = { "golangcilint" },
      dockerfile = { "hadolint" },
    }

    -- ────────────────────────────────────────────────────────────────
    -- golangci-lint v2: не паниковать из-за кода выхода.
    -- ────────────────────────────────────────────────────────────────
    -- golangci-lint v2 может вернуть ненулевой код выхода (например
    -- 5) из-за служебных замечаний — typechecking, проблемы с
    -- модулем и т.п. — ДАЖЕ когда диагностику он корректно выдал в
    -- stdout. Без этой опции nvim-lint видит ненулевой код и
    -- показывает warning "Linter command golangci-lint exited with
    -- code: N", хотя на деле всё отработало.
    --
    -- Мы и так зовём golangci-lint с --issues-exit-code=0 (это в
    -- дефолтных args nvim-lint), т.е. "найдены проблемы" уже не
    -- считается ошибкой. Ненулевой код остаётся только от служебных
    -- замечаний, которые диагностики не несут — их игнор безопасен,
    -- вся диагностика парсится из stdout.
    lint.linters.golangcilint.ignore_exitcode = true

    -- ────────────────────────────────────────────────────────────────
    -- Когда запускать линтинг.
    -- ────────────────────────────────────────────────────────────────
    -- BufReadPost — при открытии файла (сразу видно проблемы).
    -- BufWritePost — после сохранения (основной триггер).
    -- InsertLeave — после выхода из режима вставки (свежо, но не
    --   дёргает линтер на каждый символ — golangci-lint тяжёлый,
    --   он под капотом компилирует пакет).
    local lint_augroup = vim.api.nvim_create_augroup("user-nvim-lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        -- try_lint без аргументов — запускает линтеры из linters_by_ft
        -- для текущего filetype. Если линтера для типа нет — тихо
        -- ничего не делает.
        -- pcall — чтобы ошибка одного линтера (например, бинарь ещё
        -- не докачан Mason'ом) не ломала автокоманду целиком.
        pcall(function()
          lint.try_lint()
        end)
      end,
    })

    -- ────────────────────────────────────────────────────────────────
    -- <leader>ll — запустить линтинг текущего файла вручную.
    -- ────────────────────────────────────────────────────────────────
    vim.keymap.set("n", "<leader>ll", function()
      lint.try_lint()
    end, { desc = "Lint: запустить линтинг текущего файла" })

    -- ────────────────────────────────────────────────────────────────
    -- :LintInfo — показать, какие линтеры назначены этому буферу.
    -- ────────────────────────────────────────────────────────────────
    -- Удобно для диагностики: "почему не линтится?" -> :LintInfo
    -- покажет, есть ли вообще линтер для этого filetype.
    vim.api.nvim_create_user_command("LintInfo", function()
      local ft      = vim.bo.filetype
      local linters = lint.linters_by_ft[ft]
      if linters and #linters > 0 then
        vim.notify(
          "Линтеры для '" .. ft .. "': " .. table.concat(linters, ", "),
          vim.log.levels.INFO
        )
      else
        vim.notify(
          "Для filetype '" .. ft .. "' линтеры не настроены",
          vim.log.levels.WARN
        )
      end
    end, { desc = "Показать линтеры для текущего filetype" })
  end,
}