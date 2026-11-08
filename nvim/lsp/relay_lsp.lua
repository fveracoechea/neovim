return {
  cmd = function(dispatchers, config)
    local local_command = config.root_dir .. "/node_modules/.bin/relay-compiler"
    local command = vim.fn.executable(local_command) == 1 and local_command or "relay-compiler"
    return vim.lsp.rpc.start({ command, "lsp" }, dispatchers)
  end,
  root_markers = { "relay.config.json", "relay.config.js", "relay.config.cjs" },
  workspace_required = true,
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
}
