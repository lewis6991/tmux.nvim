local tmux = require('tmux.tmux')

--- @class tmux.layout
--- @field width integer
--- @field height integer
--- @field panes tmux.pane[]

--- @class tmux.pane
--- @field id integer
--- @field x integer
--- @field y integer
--- @field width integer
--- @field height integer

--- @param x string
--- @return integer
local function tointeger(x)
  return assert(tonumber(x) --[[@as integer]])
end

--- @param display string
--- @return tmux.layout?
local function parse(display)
  if display == '' or not display then
    return
  end

  local panes = {} --- @type tmux.pane[]

  --- @diagnostic disable-next-line:no-unknown
  for width, height, x, y, id in display:gmatch('(%d+)x(%d+),(%d+),(%d+),(%d+)') do
    panes[#panes + 1] = {
      id = tointeger(id),
      x = tointeger(x),
      y = tointeger(y),
      width = tointeger(width),
      height = tointeger(height),
    }
  end

  if #panes == 0 then
    return
  end

  local width, height = display:match('^%w+,(%d+)x(%d+)')

  if not width and not height then
    return
  end

  return {
    width = tointeger(width),
    height = tointeger(height),
    panes = panes,
  }
end

--- @type table<'h'|'j'|'k'|'l', fun(layout: tmux.layout, pane: tmux.pane): boolean>
local direction_checks = {
  h = function(_, pane)
    return pane.x == 0
  end,

  j = function(layout, pane)
    return pane.y + pane.height == layout.height
  end,

  k = function(_, pane)
    return pane.y == 0
  end,

  l = function(layout, pane)
    return pane.x + pane.width == layout.width
  end,
}

--- @param id integer
--- @param panes tmux.pane[]
--- @return tmux.pane?
local function get_pane(id, panes)
  for _, pane in pairs(panes) do
    if pane.id == id then
      return pane
    end
  end
end

local M = {}

--- @param direction 'h'|'j'|'k'|'l'
--- @return boolean?
function M.is_border(direction)
  local display = tmux.get_window_layout()
  local id = tmux.get_current_pane_id()

  local layout = parse(display)
  if not layout then
    return
  end

  local pane = get_pane(id, layout.panes)
  if not pane then
    return
  end

  local check = direction_checks[direction]
  if check ~= nil then
    return check(layout, pane)
  end
end

return M
