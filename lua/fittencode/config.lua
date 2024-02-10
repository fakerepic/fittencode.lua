---@type PluginConfig
local default_configs = {
  token_path = vim.fn.stdpath('cache') .. '/fittencode.json',
  suggestion = {
    enabled_at_startup = true,
    auto_trigger = {
      debounce = 1000,
      enabled_by_default = false,
      -- TODO: filetypes
      -- filetypes = {
      -- },
    },
    keymap = {
      generate = '<C-L>',
      accept = '<C-;>',
      dismiss = '<C-M>',
    },
  },
}

local M = {
  ---@type PluginConfig?
  opts = nil,
}

---@param opts PluginConfig?
function M.setup(opts)
  if M.opts then
    vim.notify('Fitten code config is already installed')
    return
  end
  opts = opts or {}
  M.opts = vim.tbl_deep_extend('force', default_configs, opts)
end

---@param key? string
function M.get(key)
  if not M.opts then
    error('Fitten code config is not installed')
  end

  if key then
    return M.opts[key]
  end

  return M.opts
end

return M
