local auth = require('fittencode.auth')
local core = require('fittencode.core')

local M = {
  setup_done = false,
}

function M.setup()
  if M.setup_done then
    return
  end

  vim.api.nvim_create_user_command('FCLogin', function(o)
    local params = vim.split(o.args, '%s+', { trimempty = true })
    local username, password = params[1], params[2]
    if not username or not password then
      vim.notify('Usage: FittenLogin <username> <password>')
      return
    end
    auth.login(username, password)
    core.setup()
  end, { bang = true, nargs = '*' })

  vim.api.nvim_create_user_command('FCLogout', function()
    auth.logout()
    core.teardown()
  end, {})

  vim.api.nvim_create_user_command('FCStatus', function()
    local api_file_ok = auth.check_api_file()
    local core_status = core.check_core_status()
    local auto_trigger = core.need_auto_trigger and 'enabled' or 'disabled'
    vim.notify(
      string.format('API file ok: %s\nCore status: %s\nAuto trigger: %s', api_file_ok, core_status, auto_trigger)
    )
  end, {})

  vim.api.nvim_create_user_command('FCEnable', function()
    core.setup()
    vim.notify('fittencode.core enabled')
  end, {})

  vim.api.nvim_create_user_command('FCDisable', function()
    core.teardown()
    vim.notify('fittencode.core disabled')
  end, {})

  vim.api.nvim_create_user_command('FCAutoTrigEnable', function()
    core.need_auto_trigger = true
    vim.notify('fittencode auto trigger enabled')
  end, {})

  vim.api.nvim_create_user_command('FCAutoTrigDisable', function()
    core.need_auto_trigger = false
    vim.notify('fittencode auto trigger disabled')
  end, {})

  M.setup_done = true
end

return M
