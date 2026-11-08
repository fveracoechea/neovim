vim.g.neovim_smoke_errors = {}
local notify = vim.notify
vim.notify = function(message, level, options)
  if level == vim.log.levels.ERROR then
    vim.g.neovim_smoke_errors = vim.list_extend(vim.g.neovim_smoke_errors, { tostring(message) })
  end
  return notify(message, level, options)
end
