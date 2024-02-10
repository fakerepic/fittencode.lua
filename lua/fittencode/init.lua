local auth = require('fittencode.auth')
local command = require('fittencode.command')
local config = require('fittencode.config')
local core = require('fittencode.core')

local M = {
  setup_done = false,
}

---@param opts PluginConfig?
function M.setup(opts)
  if M.setup_done then
    return
  end

  config.setup(opts)
  command.setup()
  auth.setup()

  if config.opts.suggestion.enabled_at_startup then
    core.setup()
  end

  M.setup_done = true
end

return M
