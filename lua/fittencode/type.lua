---@class PluginStorageJson
---@field token string

---@class PluginConfigSuggestionAutoTrigger
---@field enabled_by_default? boolean
---@field debounce? number

---@class PluginConfigSuggestion
---@field enabled_at_startup? boolean
---@field auto_trigger? PluginConfigSuggestionAutoTrigger
---@field keymap? table<string, string>

---@class PluginConfig
---@field token_path? string
---@field suggestion? PluginConfigSuggestion

---@class FittenResponseCompletion
---@field generated_text string
---@field server_request_id string

---@class FittenResponseFicoData
---@field expire_time number
---@field expire_token table
---@field fico_token string
---@field phone string
---@field user_id string
---@field username string

---@class FittenResponseFico
---@field data FittenResponseFicoData
---@field msg string
---@field status_code number

---@class FittenResponseLoginData
---@field email string
---@field jobs table
---@field like_jobs table
---@field liked_count number
---@field nickname string
---@field phone string
---@field token string
---@field user_id string
---@field username string
---@field viewed_count number

---@class FittenResponseLogin
---@field code number
---@field data FittenResponseLoginData
---@field message string
