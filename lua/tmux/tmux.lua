local config = require('tmux.config')
local options = config.options

local tmux_directions = {
  h = 'L',
  j = 'D',
  k = 'U',
  l = 'R',
}

local opposite_directions = {
  h = 'l',
  j = 'k',
  k = 'j',
  l = 'h',
}

local is_tmux = vim.env.TMUX ~= nil

--- @param arg string[]
--- @return string
local function execute(arg)
  local socket = vim.split(vim.env.TMUX, ',')[1]
  local command = vim.list_extend({ 'tmux', '-S', socket }, arg)
  return vim.fn.system(command)
end

--- @param direction 'h'|'j'|'k'|'l'
local function change_pane(direction)
  execute({ 'select-pane', '-t', vim.env.TMUX_PANE, '-' .. tmux_directions[direction] })
end

--- @return integer
local function get_current_pane_id()
  return tonumber(vim.env.TMUX_PANE:sub(2)) --[[@as integer]]
end

--- @return string
local function get_window_layout()
  return execute({ 'display-message', '-p', '#{window_layout}' })
end

--- @return boolean
local function is_zoomed()
  return execute({ 'display-message', '-p', '#{window_zoomed_flag}' }):find('1') ~= nil
end

--- @param direction 'h'|'j'|'k'|'l'
--- @param step integer
local function resize(direction, step)
  execute({ 'resize-pane', '-t', vim.env.TMUX_PANE, '-' .. tmux_directions[direction], tostring(step) })
end

--- @class tmux.layout
--- @field width integer
--- @field height integer
--- @field panes table<integer,tmux.pane>

--- @class tmux.pane
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

  local panes = {} --- @type table<integer,tmux.pane>

  --- @diagnostic disable-next-line:no-unknown
  for width, height, x, y, id in display:gmatch('(%d+)x(%d+),(%d+),(%d+),(%d+)') do
    id = tointeger(id)
    panes[id] = {
      x = tointeger(x),
      y = tointeger(y),
      width = tointeger(width),
      height = tointeger(height),
    }
  end

  if next(panes) == nil then
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

--- @param direction 'h'|'j'|'k'|'l'
--- @return boolean?
local function is_border(direction)
  local display = get_window_layout()
  local id = get_current_pane_id()

  local layout = parse(display)
  if not layout then
    return
  end

  local pane = layout.panes[id]
  if not pane then
    return
  end

  if direction == 'h' then
    return pane.x == 0
  elseif direction == 'j' then
    return pane.y + pane.height == layout.height
  elseif direction == 'k' then
    return pane.y == 0
  elseif direction == 'l' then
    return pane.x + pane.width == layout.width
  end
  return false
end

--- @param direction 'h'|'j'|'k'|'l'
--- @return boolean
local function has_tmux_target(direction)
  if not is_tmux then
    return false
  end
  if is_zoomed() and options.navigation.persist_zoom then
    return false
  end
  if not is_border(direction) then
    return true
  end
  return options.navigation.cycle_navigation
    and not is_border(opposite_directions[direction])
end

local function is_nvim_border(border)
  return vim.fn.winnr() == vim.fn.winnr('1' .. border)
end

--- @param direction 'h'|'j'|'k'|'l'
local function nav_to(direction)
  if not is_nvim_border(direction) then
    vim.cmd('1wincmd ' .. direction)
  elseif has_tmux_target(direction) then
    change_pane(direction)
  elseif options.navigation.cycle_navigation then
    vim.cmd('999wincmd ' .. opposite_directions[direction])
  end
end

local function is_only_window()
  return vim.fn.winnr('1h') == vim.fn.winnr('1l')
    and vim.fn.winnr('1j') == vim.fn.winnr('1k')
end

local function is_tmux_target(border)
  return is_tmux and not is_border(border) or is_only_window()
end

local M = {}

function M.resize_left()
  local step = options.resize.resize_step_x
  if not is_nvim_border('l') then
    vim.cmd('vertical resize +' .. step)
  elseif is_tmux_target('l') then
    resize('h', step)
  else
    vim.cmd('vertical resize -' .. step)
  end
end

function M.resize_bottom()
  local step = options.resize.resize_step_y
  if not is_nvim_border('j') then
    vim.cmd.resize('+' .. step)
  elseif is_tmux_target('j') then
    resize('j', step)
  elseif vim.fn.winnr() ~= vim.fn.winnr('1k') then
    vim.cmd.resize('-' .. step)
  end
end

function M.resize_top()
  local step = options.resize.resize_step_y
  if not is_nvim_border('j') then
    vim.cmd.resize('+' .. step)
  elseif is_tmux_target('j') then
    resize('k', step)
  else
    vim.cmd.resize('-' .. step)
  end
end

function M.resize_right()
  local step = options.resize.resize_step_x
  if not is_nvim_border('l') then
    vim.cmd('vertical resize +' .. step)
  elseif is_tmux_target('l') then
    resize('l', step)
  else
    vim.cmd('vertical resize -' .. step)
  end
end

function M.move_left()
  nav_to('h')
end

function M.move_bottom()
  nav_to('j')
end

function M.move_top()
  nav_to('k')
end

function M.move_right()
  nav_to('l')
end

return M
