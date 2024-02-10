local config = require('fittencode.config')
local utils = require('fittencode.utils')

local login_url = 'https://codeuser.fittentech.cn:14443/login'
local fico_url = 'https://codeuser.fittentech.cn:14443/get_ft_token'

local M = {
  ---@type string | nil
  token = nil,
}

function M.load_token()
  if M.token then
    return
  end
  if not utils.file_exists(config.opts.token_path) then
    return
  end

  --- @type PluginStorageJson?
  local json = utils.read_json(config.opts.token_path)
  if not json then
    return
  end
  M.token = json.token
end

function M.check_api_file()
  return utils.file_exists(config.opts.token_path)
end

function M.logout()
  if utils.file_exists(config.opts.token_path) then
    utils.remove_file(config.opts.token_path)
    M.token = nil
    vim.notify('Logout successful')
  else
    vim.notify('You are already logged out')
  end
end

function M.login(username, password)
  local json_data = string.format('{"username": "%s", "password": "%s"}', username, password)
  local login_command = string.format(
    'curl -s -X POST -H "Content-Type: application/json" -d %s %s',
    vim.fn.shellescape(json_data),
    login_url
  )
  local response = vim.fn.system(login_command)
  ---@type FittenResponseLogin?
  local login_data = vim.json.decode(response)

  if not login_data or login_data.code ~= 200 then
    vim.notify('Login failed', vim.log.levels.ERROR)
    return
  end

  local user_token = login_data.data.token

  local fico_command = string.format('curl -s -H "Authorization: Bearer %s" %s', user_token, fico_url)
  local fico_response = vim.fn.system(fico_command)
  ---@type FittenResponseFico?
  local fico_json = vim.json.decode(fico_response)

  if not fico_json or not fico_json.data then
    vim.notify('failed to get token', vim.log.levels.ERROR)
    return
  end

  M.token = fico_json.data.fico_token
  -- vim.fn.writefile({ apikey }, config.options.token_path)
  local ok = utils.write_json(config.opts.token_path, { token = M.token })
  if not ok then
    vim.notify('failed to save token', vim.log.levels.ERROR)
  end

  vim.notify('Login successful')
end

function M.setup()
  M.load_token()
end

return M
