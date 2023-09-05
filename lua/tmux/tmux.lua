local vim = vim

local tmux_directions = {
  h = 'L',
  j = 'D',
  k = 'U',
  l = 'R',
}

local function get_tmux()
  return vim.env.TMUX
end

local function get_tmux_pane()
  return vim.env.TMUX_PANE
end

local function get_socket()
  return vim.split(get_tmux(), ',')[1]
end

--- @param arg string[]
--- @return string
local function execute(arg)
  local command = vim.list_extend({ 'tmux', '-S', get_socket() }, arg)
  return vim.fn.system(command)
end

--- @param arg string
--- @param pre? string
--- @return string
local function execute2(arg, pre)
  local command = string.format('%s tmux -S %s %s', pre or '', get_socket(), arg)
  return vim.fn.system(command)
end

local M = {
  is_tmux = false,
}

function M.setup()
  M.is_tmux = get_tmux() ~= nil
  return M.is_tmux
end

function M.change_pane(direction)
  execute({ 'select-pane', '-t', get_tmux_pane(), '-' .. tmux_directions[direction] })
end

function M.get_buffer(name)
  return execute({ 'show-buffer', '-b', name })
end

function M.get_buffer_names()
  local buffers = execute({ 'list-buffers', '-F', '#{buffer_name}' })

  local result = {}
  for line in buffers:gmatch('([^\n]+)\n?') do
    result[#result + 1] = line
  end

  return result
end

--- @return integer
function M.get_current_pane_id()
  return tonumber(get_tmux_pane():sub(2)) --[[@as integer]]
end

--- @return string
function M.get_window_layout()
  return execute({ 'display-message', '-p', '#{window_layout}' })
end

--- @return boolean
function M.is_zoomed()
  return execute({ 'display-message', '-p', '#{window_zoomed_flag}' }):find('1') ~= nil
end

function M.resize(direction, step)
  execute({ 'resize-pane', '-t', get_tmux_pane(), '-' .. tmux_directions[direction], step })
end

function M.set_buffer(content, sync_clipboard)
  content = content:gsub('\\', '\\\\')
  content = content:gsub('"', '\\"')
  content = content:gsub('`', '\\`')
  content = content:gsub('%$', '\\$')

  if sync_clipboard then
    execute2('load-buffer -w -', string.format('printf "%%s" "%s" | ', content))
  else
    execute2('load-buffer -', string.format('printf "%%s" "%s" | ', content))
  end
end

return M
