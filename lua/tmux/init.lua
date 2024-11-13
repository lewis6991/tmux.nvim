local config = require('tmux.config')

local options = config.options

local M = {}

local function nmap(l, r)
  vim.keymap.set('n', l, function()
    require('tmux.tmux')[r]()
  end, { nowait = true, silent = true })
end

--- @param user_options? tmux.config
function M.setup(user_options)
  config.setup(user_options)

  if options.resize.enable_default_keybindings then
    nmap('<A-h>', 'resize_left')
    nmap('<A-j>', 'resize_bottom')
    nmap('<A-k>', 'resize_top')
    nmap('<A-l>', 'resize_right')
  end

  if options.navigation.enable_default_keybindings then
    nmap('<C-h>', 'move_left')
    nmap('<C-j>', 'move_bottom')
    nmap('<C-k>', 'move_top')
    nmap('<C-l>', 'move_right')
  end
end

return M
