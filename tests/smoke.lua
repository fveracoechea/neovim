local function check_config()
  assert(vim.v.errmsg == "", vim.v.errmsg)
  assert(#(vim.g.neovim_smoke_errors or {}) == 0, vim.inspect(vim.g.neovim_smoke_errors))

  local lock = vim.json.decode(table.concat(vim.fn.readfile(vim.fn.stdpath "config" .. "/nvim-pack-lock.json"), "\n"))
  assert(#vim.pack.get() == vim.tbl_count(lock.plugins), "Plugin catalog differs from the lockfile")
  if vim.env.NEOVIM_OFFLINE_TEST ~= "1" then
    for name, plugin in pairs(lock.plugins) do
      local directory = vim.fn.stdpath "data" .. "/site/pack/core/opt/" .. name
      local revision = vim.system({ "git", "-C", directory, "rev-parse", "HEAD" }, { text = true }):wait()
      assert(revision.code == 0 and vim.trim(revision.stdout) == plugin.rev, "Wrong plugin revision: " .. name)
    end
    vim.pack.update(nil, { offline = true, target = "lockfile", force = true })
    local updated =
      vim.json.decode(table.concat(vim.fn.readfile(vim.fn.stdpath "config" .. "/nvim-pack-lock.json"), "\n"))
    assert(vim.deep_equal(lock, updated), "Offline update changed plugin revisions")
  end

  for _, command in ipairs {
    "fd",
    "fzf",
    "rg",
    "gh",
    "lazygit",
    "unzip",
    "cc",
    "tree-sitter",
    "curl",
    "tar",
    "git",
    "graphql-lsp",
    "stylelint-language-server",
    "stylelint",
    "lua-language-server",
    "oxfmt",
    "oxlint",
    "tsc",
    "stylua",
    "prettier",
    "magick",
  } do
    local path = vim.fn.exepath(command)
    assert(path ~= "", "Missing dependency: " .. command)
    if vim.env.NEOVIM_NIX_TEST == "1" then
      assert(path:match "^/nix/store/", "Dependency escaped the Nix installation: " .. command .. " at " .. path)
    end
  end

  for _, name in ipairs {
    "cssls",
    "eslint",
    "graphql",
    "html",
    "jsonls",
    "lua_ls",
    "oxfmt",
    "oxlint",
    "stylelint_lsp",
    "tailwindcss",
    "tsc",
  } do
    assert(vim.lsp.is_enabled(name), "Disabled LSP: " .. name)
    local server = vim.lsp.config[name]
    assert(server and server.cmd, "Missing LSP config: " .. name)
    if type(server.cmd) == "table" then
      assert(vim.fn.executable(server.cmd[1]) == 1, "Missing LSP executable: " .. server.cmd[1])
    end
  end
  assert(not vim.lsp.is_enabled "qmlls")
  assert(not vim.lsp.is_enabled "denols")
  assert(vim.lsp.is_enabled "relay_lsp")
  assert(vim.lsp.is_enabled "nixd" == (vim.fn.executable "nixd" == 1))

  local treesitter = table.concat(vim.fn.readfile(vim.fn.stdpath "config" .. "/lua/plugins/treesitter.lua"), "\n")
  local parser_dir = vim.fn.stdpath "data" .. "/site/parser/"
  for language in treesitter:gmatch '\n  "([a-z_0-9]+)",' do
    local path = parser_dir .. language .. ".so"
    assert(vim.fn.filereadable(path) == 1, "Parser not installed: " .. language)
    vim.treesitter.language.add(language, { path = path })
    assert(vim.treesitter.get_string_parser("", language):parse(), "Parser cannot load: " .. language)
  end

  assert(vim.fn.exists ":Herdr" == 2)
  assert(require("herdr-nvim").config.clear_after_send == true)
  for _, suffix in ipairs { "c", "l", "s", "S" } do
    local mapping = vim.fn.maparg(vim.g.mapleader .. "h" .. suffix, "n", false, true)
    assert(mapping.desc:match "herdr%-nvim", "Missing Herdr mapping: " .. suffix)
  end
  assert(#vim.fn.maparg(vim.g.mapleader .. "hc", "x") > 0)
  assert(#vim.fn.maparg(vim.g.mapleader .. "ll", "n") == 0, "Unused lint mapping remains")
  for _, key in ipairs { "<C-n>", "<C-y>" } do
    assert(type(vim.fn.maparg(key, "n", false, true).callback) == "function", "Missing explorer mapping")
  end
  assert(type(Snacks.explorer) == "table" or type(Snacks.explorer) == "function")

  local text = "dotfiles_no_matching_snippet"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { text })
  vim.api.nvim_win_set_cursor(0, { 1, #text - 1 })
  assert(vim.fn.maparg("<Tab>", "i", false, true).callback() == "<Tab>")
  assert(vim.fn.maparg("<S-Tab>", "i", false, true).callback() == "<S-Tab>")
  local conform = require "conform"
  local formatters = conform.formatters_by_ft
  assert(vim.deep_equal(formatters.javascript, { "prettier", "oxfmt", stop_after_first = true }))
  if vim.env.NEOVIM_NIX_TEST == "1" then
    assert(vim.fn.exepath("nixfmt"):match "^/nix/store/", "Missing Nix-provided nixfmt")
  end
  if vim.fn.executable "nixfmt" == 1 then
    assert(formatters.nix[1] == "nixfmt")
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.bo[buffer].filetype = "nix"
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "{value=1;}" })
    conform.format { bufnr = buffer, async = false, lsp_format = "never", timeout_ms = 5000 }
    assert(vim.deep_equal(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), { "{ value = 1; }" }))
    vim.api.nvim_buf_delete(buffer, { force = true })
  else
    assert(formatters.nix == nil)
  end
  assert(formatters.qml == nil)
  assert(formatters.python == nil)

  require("mini.sessions").write("shared-runtime", { force = true })
  assert(vim.fn.filereadable(vim.fn.stdpath "state" .. "/sessions/shared-runtime") == 1)
  assert(vim.fn.filereadable(vim.fn.stdpath "config" .. "/shared-runtime") == 0)
  assert(vim.opt.undodir:get()[1] == vim.fn.stdpath "state" .. "/undo")

  local project = vim.fn.tempname()
  vim.fn.mkdir(project .. "/src", "p")
  vim.fn.writefile(
    { '{ "compilerOptions": { "strict": true, "noEmit": true }, "include": ["src"] }' },
    project .. "/tsconfig.json"
  )
  vim.fn.writefile({ "const count: number = 1;" }, project .. "/src/main.ts")
  vim.fn.writefile({ "{ outputs = _: {}; }" }, project .. "/flake.nix")
  vim.cmd.cd(project)

  local function open_with_server(file, name)
    vim.cmd.edit(file)
    local buffer = vim.api.nvim_get_current_buf()
    assert(
      vim.wait(15000, function()
        for _, client in ipairs(vim.lsp.get_clients { bufnr = buffer, name = name }) do
          if client.initialized then
            return true
          end
        end
        return false
      end),
      "Language server did not initialize: " .. name
    )
    assert(vim.v.errmsg == "", vim.v.errmsg)
  end

  open_with_server(project .. "/src/main.ts", "tsc")
  if vim.fn.executable "nixd" == 1 then
    open_with_server(project .. "/flake.nix", "nixd")
  end
  assert(#(vim.g.neovim_smoke_errors or {}) == 0, vim.inspect(vim.g.neovim_smoke_errors))
end

local ok, error_message = pcall(check_config)
if not ok then
  io.stderr:write(tostring(error_message) .. "\n")
  vim.cmd "cquit 1"
end
print "Neovim runtime checks passed"
vim.cmd "qa!"
