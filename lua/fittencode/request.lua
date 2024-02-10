local uv = vim.loop

local M = {
  ---@type uv_process_t | nil
  handle = nil,
}

function M.running()
  return M.handle ~= nil
end

function M.cancel_inflight()
  if M.running() then
    uv.close(M.handle)
    M.handle = nil
  end
end

---@param method string @GET | POST | PUT | DELETE etc.
---@param url string
---@param data string '-d' option for curl
---@param callback fun(response: string | nil)
function M.request(method, url, data, callback)
  if M.running() then
    return
  end

  local stdout_pipe = uv.new_pipe()
  M.handle = uv.spawn('curl', {
    args = { '-s', '-X', method, '-H', 'Content-Type: application/json', '-d', data, url },
    stdio = { nil, stdout_pipe, nil },
  }, function()
    if M.handle then
      uv.close(M.handle)
      M.handle = nil
    end
  end)

  local response = nil
  uv.read_start(stdout_pipe, function(_, trunk)
    if trunk then
      response = response and response .. trunk or trunk
      return
    end
    if M.running() then
      vim.schedule(function()
        callback(response)
      end)
      return
    end
  end)
end

return M
