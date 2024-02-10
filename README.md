# fittencode.lua

A lua port of the [fittencode.vim](https://github.com/FittenTech/fittencode.vim.git) plugin.

## Features

- Blazing fast code suggestions powered by [Fitten Code](https://code.fittentech.com)
- Code completion can be triggered automatically or manually

## Requirements

- curl (system command)

## Installation and Configuration

You should run the `require("fittencode").setup(options)` function to run this plugin. 
Here is an example with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "fakerepic/fittencode.lua",
    config = function()
        require("fittencode").setup({
            -- config options go here, if any
        })
    end
}
```

The following is the default configuration, which is used when no options are provided:

```lua
require("fittencode").setup({
    token_path = vim.fn.stdpath('cache') .. '/fittencode.json',
    suggestion = {
        enabled_at_startup = true,
        auto_trigger = {
            debounce = 1000,
            enabled_by_default = false,
        },
        keymap = {
            generate = '<C-L>',
            accept = '<C-;>',
            dismiss = '<C-M>',
        },
    },
})
```

## Usage

### Authentication

Run `:FCLogin <username> <password>` to login to your Fitten account and enable the plugin.
The token will be saved in the `token_path` file.

### Commands

- `FCLogin <username> <password>`: Login to your Fitten account
- `FCLogout`: Logout of your Fitten account
- `FCStatus`: Show the current status of the plugin (logged in, enabled, auto-trigger enabled)
- `FCEnable`, `FCDisable`: Enable or disable the features of the plugin
- `FCAutoTrigEnable`, `FCAutoTrigDisable`: Enable or disable the auto-trigger feature

### Default Keymap

| Key Combination | Function Called                                | Description                           |
| --------------- | ---------------------------------------------- | ------------------------------------- |
| `<C-L>`         | `require('fittencode.core').code_completion()` | Generate suggestion and preview       |
| `<C-;>`         | `require('fittencode.core').accept_preview()`  | Accept preview and insert into buffer |
| `<C-M>`         | `require('fittencode.core').clear()`           | Dismiss suggestion and clear preview  |

# Previews

![](https://raw.githubusercontent.com/fakerepic/fittencode.lua/gif/preview.gif)

## Reference

- [fittencode.vim](https://github.com/FittenTech/fittencode.vim.git) - The main reference for api usage
- [copilot.lua](https://github.com/zbirenbaum/copilot.lua) - Borrowed some ideas and snippets from here

## Others

~~Currently there is no official neovim binding for Fitten Code~~, and this plugin was developed mainly to facilitate self-use. **It seems that other developers have already built [fittencode.nvim](https://github.com/luozhiya/fittencode.nvim), but it requires nightly version of neovim, I published this one anyway :)**
Some of the other official features may be added if Fitten Code reveals more API details.
