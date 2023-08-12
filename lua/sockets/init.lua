local msgpack = require 'deps.msgpack'
local Logger = require 'lib.log'

require 'lib.list_to_argv'
require 'sockets.std'


---@class ReceiverProps
---@field event string
---@field socket_emmiter string
---@field data any

---@class Sockets
---@field socket string
---@field sockets string[]
---@field receivers table<string, fun(props: ReceiverProps)>
local Sockets = {
  socket = vim.v.servername,
  sockets = {},
  receivers = {}
}
Sockets.__index = Sockets

---@param vim_events? boolean
function Sockets:setup(vim_events)
  self:register_self()

  if vim_events then
    vim.api.nvim_create_user_command('PrintSockets', function() self:print_sockets() end, { nargs = 0 })
    vim.api.nvim_create_user_command('PrintLogs', function() Logger:print() end, { nargs = 0 })
  end

  vim.api.nvim_create_autocmd('ExitPre', {
    callback = function() self:unregister_self() end
  })
end

---@param vim_events? boolean
function Sockets.new(vim_events)
  local instance = setmetatable({}, Sockets)
  instance:setup(vim_events)

  return instance
end

function Sockets:print_sockets()
  print(vim.fn.json_encode(self.sockets))
end

---@param event string
---@param data any
function Sockets:emmit(event, data)
  ---@type ReceiverProps
  local props = {
    socket_emmiter = self.socket,
    event = event,
    data = data
  }

  Logger:log('emmit', 'Emmiting event', event, 'to', #self.sockets, 'sockets')

  for _, socket in ipairs(self.sockets) do
    local err = self:call_remote_method(socket, 'receive_data', { event, props })

    if err then
      Logger:log('emmit', 'Error emmiting to', socket .. ':', err)
    end
  end
end

---@param event string
---@param fn fun(props: ReceiverProps)
function Sockets:on(event, fn)
  self.receivers[event] = fn
end

---@private
function Sockets:register_self()
  self.sockets = self.get_socket_paths()

  Logger:log('register_self', 'Registered self for', #self.sockets - 1, 'sockets')

  for i, socket in ipairs(self.sockets) do
    if socket == self.socket then
      self.sockets[i] = nil
    else
      local err = self:call_remote_method(socket, 'register_socket', { self.socket })

      if err then
        Logger:log('register_self', 'Error registering for', socket .. ':', err)
      end
    end
  end
end

function Sockets:unregister_self()
  Logger:log('unregister_self', 'Unregistering self for', #self.sockets, 'sockets')

  for _, socket in ipairs(self.sockets) do
    local err = self:call_remote_method(socket, 'unregister_socket', { self.socket })

    if err then
      Logger:log('unregister_self', 'Error unregistering for socket', socket .. ':', err)
    end
  end
end

---@private
---@return string[]
function Sockets.get_socket_paths()
  local function handle(lines)
    local sockets = {}

    for i = 1, #lines do
      local socket = lines[i]:match '%s(/.-)%s'

      if socket then
        table.insert(sockets, socket)
      end
    end

    return sockets
  end

  local f = assert(io.popen('ss -lx | grep vim'))
  local data = f:read('*a')
  f:close()

  return handle(data:split '\n')
end

---@private
---@param socket string
---@param name string
---@param args table
---@return string?
function Sockets:call_remote_method(socket, name, args)
  local cmd_fmt = 'lua package.loaded.sockets:%s(%s)'

  local arglist = ListToArgv(args)
  local cmd = string.format(cmd_fmt, name, arglist)

  return self:call_remote_instance(socket, cmd)
end

---@private
---@param socket string
---@param cmd string
---@return string?
function Sockets:call_remote_instance(socket, cmd)
  local pipe = assert(vim.loop.new_pipe(true))
  local err

  pipe:connect(socket, function()
    local packed = msgpack.pack({ 0, 0, 'nvim_command', { cmd } })

    pipe:write(packed, function(err_)
      err = err_
    end)
  end)

  return err
end

--- End client methods ---
--- Start server methods ---

---@private
---@param socket string
function Sockets:register_socket(socket)
  Logger:log('register_socket', 'Registering socket', socket)
  table.insert(self.sockets, socket)
end

---@private
---@param socket string
function Sockets:unregister_socket(socket)
  Logger:log('unregister_socket', 'Unregistering socket', socket)
  self.sockets[socket] = nil
end

---@private
---@param event string
---@param props ReceiverProps
function Sockets:receive_data(event, props)
  Logger:log('receive_data', 'Receiving event', props.event, 'from', props.socket_emmiter)

  local fn = self.receivers[event]

  if fn then
    fn(props)
  end
end

return Sockets
