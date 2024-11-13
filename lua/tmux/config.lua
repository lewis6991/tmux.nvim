local M = {}

--- @class tmux.config
M.options = {
  --- @class tmux.config.navigation
  navigation = {
    -- cycles to opposite pane while navigating into the border
    cycle_navigation = true,

    -- enables default keybindings (C-hjkl) for normal mode
    enable_default_keybindings = false,

    -- prevents unzoom tmux when navigating beyond vim border
    persist_zoom = false,
  },
  --- @class tmux.config.resize
  resize = {
    -- enables default keybindings (A-hjkl) for normal mode
    enable_default_keybindings = false,

    -- sets resize steps for x axis
    resize_step_x = 1,

    -- sets resize steps for y axis
    resize_step_y = 1,
  },
}

--- @param source table<string,any>
--- @param target table<string,any>
local function copy(source, target)
  if source == nil or target == nil then
    return
  end
  for index in pairs(source) do
    if
      target[index] ~= nil
      and type(source[index]) == 'table'
      and type(target[index]) == 'table'
    then
      copy(source[index], target[index])
    elseif target[index] ~= nil and type(source[index]) == type(target[index]) then
      source[index] = target[index]
    end
  end
  for index, _ in pairs(target) do
    if target[index] ~= nil and source[index] == nil then
      source[index] = target[index]
    end
  end
end

--- @param opts? tmux.config
function M.setup(opts)
  if not opts then
    return
  end
  copy(M.options, opts)
end

return M
