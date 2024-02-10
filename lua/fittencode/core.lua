local A = require('fittencode.auth')
local C = require('fittencode.config')
local R = require('fittencode.request')
local U = require('fittencode.utils')

local augroup = 'fittencode.core'
local ns_id = vim.api.nvim_create_namespace('fittencodepreview')
local extmark_id = 1

local completion_url = 'https://codeapi.fittentech.cn:13443/generate_one_stage'

local M = {
  ---@type boolean | nil
  need_auto_trigger = nil,
  ---@type string | nil
  generated_text = nil,
  ---@type number | nil
  timer = nil,

  setup_done = false,
}

local function clear_preview()
  vim.api.nvim_buf_del_extmark(0, ns_id, extmark_id)
end

function M.clear()
  R.cancel_inflight()
  M.generated_text = nil
  clear_preview()
end

local function show_preview()
  if not M.generated_text or M.generated_text == '' then
    return
  end

  local current_line = vim.fn.line('.')
  local current_col = vim.fn.col('.')
  local lines = vim.split(M.generated_text, '\n')

  local extmark = {
    id = extmark_id,
    virt_text_win_col = vim.fn.virtcol('.') - 1,
    virt_text = { { lines[1], 'Comment' } },
    hl_mode = 'combine',
  }

  if #lines > 1 then
    extmark.virt_lines = {}
    for i = 2, #lines do
      extmark.virt_lines[i - 1] = { { lines[i], 'Comment' } }
    end
  end

  vim.api.nvim_buf_set_extmark(0, ns_id, current_line - 1, current_col - 1, extmark)
end

function M.accept_preview()
  if not M.generated_text or M.generated_text == '' then
    return
  end
  vim.paste(vim.split(M.generated_text, '\n'), -1)
  M.clear()
end

local function get_params()
  local filename = vim.api.nvim_buf_get_name(0)

  local line_pos, col_pos = vim.fn.line('.'), vim.fn.col('.')
  local line_end, col_end = vim.fn.line('$'), vim.fn.col('$')

  local prompt = '!FCPREFIX!'
    .. table.concat(vim.api.nvim_buf_get_text(0, 0, 0, line_pos - 1, col_pos - 1, {}), '\n')
    .. '!FCSUFFIX!'
    .. table.concat(vim.api.nvim_buf_get_text(0, line_pos - 1, col_pos - 1, line_end - 1, col_end - 1, {}), '\n')
    .. '!FCMIDDLE!'

  local escaped_prompt = string.gsub(prompt, '"', '\\"')

  local params = vim.json.encode({
    inputs = escaped_prompt,
    meta_datas = { filename = filename },
  })
  return params
end

function M.code_completion()
  if not A.token then
    vim.notify('Please login first', vim.log.levels.ERROR)
    M.teardown()
    return
  end

  if M.generated_text then
    return
  end

  M.clear()

  local tempfile = vim.fn.tempname()
  vim.fn.writefile({ get_params() }, tempfile)

  local method = 'POST'
  local url = string.format('%s/%s?ide=vim&v=0.1.0', completion_url, A.token)
  local data = '@' .. tempfile

  R.request(method, url, data, function(response)
    U.remove_file(tempfile)

    if not response then
      return
    end

    ---@type FittenResponseCompletion?
    local response_json = vim.json.decode(response)
    if not response_json or not response_json.generated_text then
      vim.notify('Failed to get completion data', vim.log.levels.ERROR)
      return
    end

    M.generated_text = string.gsub(response_json.generated_text, '<.endoftext.>', '')

    show_preview()
  end)
end

local function stop_timer()
  if M.timer then
    vim.fn.timer_stop(M.timer)
    M.timer = nil
  end
end

local function schedule()
  M.clear()
  local bufnr = vim.api.nvim_get_current_buf()

  ---@diagnostic disable-next-line: redundant-parameter
  M.timer = vim.fn.timer_start(C.opts.suggestion.auto_trigger.debounce, function(id)
    local _timer = M.timer
    M.timer = nil

    if bufnr ~= vim.api.nvim_get_current_buf() or id ~= _timer or vim.fn.mode() ~= 'i' then
      return
    end

    stop_timer()
    M.code_completion()
  end)
end

local function auto_trigger()
  if M.need_auto_trigger then
    schedule()
  end
end

local function create_keymaps()
  local keymap = C.opts.suggestion.keymap or {}
  if keymap.accept then
    vim.keymap.set('i', keymap.accept, M.accept_preview, { noremap = true, silent = true })
  end
  if keymap.generate then
    vim.keymap.set('i', keymap.generate, M.code_completion, { noremap = true, silent = true })
  end
  if keymap.dismiss then
    vim.keymap.set('i', keymap.dismiss, M.clear, { noremap = true, silent = true })
  end
end

local function delete_keymaps()
  local keymap = C.opts.suggestion.keymap or {}
  if keymap.accept then
    vim.keymap.del('i', keymap.accept)
  end
  if keymap.generate then
    vim.keymap.del('i', keymap.generate)
  end
  if keymap.dismiss then
    vim.keymap.del('i', keymap.dismiss)
  end
end

local function create_autocmds()
  vim.api.nvim_create_augroup(augroup, { clear = true })

  vim.api.nvim_create_autocmd('CompleteChanged', {
    group = augroup,
    callback = M.clear,
  })

  vim.api.nvim_create_autocmd('CursorMovedI', {
    group = augroup,
    callback = function()
      if M.timer or M.need_auto_trigger then
        schedule()
      end
    end,
  })

  vim.api.nvim_create_autocmd('InsertLeave', {
    group = augroup,
    callback = M.clear,
  })

  vim.api.nvim_create_autocmd('InsertEnter', {
    group = augroup,
    callback = auto_trigger,
  })

  vim.api.nvim_create_autocmd('BufLeave', {
    group = augroup,
    callback = function()
      if vim.fn.mode():match('^[iR]') then
        M.clear()
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufEnter', {
    group = augroup,
    callback = function()
      if vim.fn.mode():match('^[iR]') then
        auto_trigger()
      end
    end,
  })
end

local function delete_autocmds()
  vim.api.nvim_clear_autocmds({ group = augroup })
end

function M.check_core_status()
  if M.setup_done then
    return 'active'
  end
  return 'inactive'
end

function M.setup()
  if M.setup_done then
    return
  end

  if not A.token then
    vim.notify('`fittencode.core.setup()` failed: please login first', vim.log.levels.ERROR)
    return
  end

  create_keymaps()
  create_autocmds()
  if type(M.need_auto_trigger) ~= 'boolean' then
    M.need_auto_trigger = C.opts.suggestion.auto_trigger.enabled_by_default
  end
  M.setup_done = true
end

function M.teardown()
  M.clear()
  delete_keymaps()
  delete_autocmds()
  M.setup_done = false
end

return M
