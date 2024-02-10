---@diagnostic disable: unused-local, redefined-local
local uv = vim.loop

local default_mod = 438

local M = {}

---@param path string
---@param json table
---@return boolean -- success
function M.write_json(path, json)
  local ok, text = pcall(vim.json.encode, json)
  if not ok or not text then
    vim.notify('Failed to encode json', vim.log.levels.ERROR)
    return false
  end

  local fd, err_o = uv.fs_open(vim.fn.expand(path), 'w+', default_mod)

  if err_o or not fd then
    vim.notify('Failed to open file', vim.log.levels.ERROR)
    return false
  end

  local _, err_w = uv.fs_write(fd, text, 0)

  uv.fs_close(fd)

  if err_w then
    vim.notify('Failed to write file', vim.log.levels.ERROR)
    return false
  end

  return true
end

---@param path string
---@return table? -- json
function M.read_json(path)
  local fd, err, errcode = uv.fs_open(vim.fn.expand(path), 'r', default_mod)
  if err or not fd then
    if errcode == 'ENOENT' then
      return nil
    end
    vim.notify('could not open ' .. path .. ': ' .. err, vim.log.levels.ERROR)
    return nil
  end

  local stat, err, errcode = uv.fs_fstat(fd)
  if err or not stat then
    uv.fs_close(fd)
    vim.notify('could not stat ' .. path .. ': ' .. err, vim.log.levels.ERROR)
    return nil
  end

  local contents, err, errcode = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  if err then
    vim.notify('could not read ' .. path .. ': ' .. err, vim.log.levels.ERROR)
    return nil
  end

  local ok, json = pcall(vim.fn.json_decode, contents)
  if not ok then
    vim.notify('could not parse json in ' .. path .. ': ' .. json, vim.log.levels.ERROR)
    return nil
  end

  return json
end

---@param path string
---@return boolean -- exists
function M.file_exists(path)
  local stat, err = uv.fs_stat(vim.fn.expand(path))
  if err or not stat then
    return false
  end
  return stat.type == 'file'
end

---@param path string
---@return boolean -- success
function M.remove_file(path)
  local ok, _, err_msg = uv.fs_unlink(vim.fn.expand(path))
  if not ok then
    if err_msg then
      vim.notify('could not remove ' .. path .. ': ' .. err_msg, vim.log.levels.ERROR)
    end
    return false
  end
  return true
end

return M
