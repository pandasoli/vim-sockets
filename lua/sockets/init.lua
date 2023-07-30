local msgpack = require 'deps.msgpack'

require 'lib.list_to_argv'
require 'lib.json'
require 'sockets.std'
require 'sockets.utils'


local Sockets = {
  socket = vim.v.servername,
  sockets = {},
  show_logs = true,

  ---@param data any
  dataUpdate = function(data)
    print(EncodeJSON(data))
  end
}

---@param data any
function Sockets:setup(data, show_logs)
  self.show_logs = not not show_logs

  self:register_self(data)

  vim.cmd([[
    command! -nargs=0 PrintSockets lua package.loaded.sockets:print_sockets()
    command! -nargs=? UpdateData lua package.loaded.sockets:updateData(<q-args>)

    autocmd ExitPre * lua package.loaded.sockets:unregister_self()
  ]])
end

function Sockets:print_sockets()
  print(EncodeJSON(self.sockets))
end

---@param data any
function Sockets:updateData(data)
  self.dataUpdate(data)

  for _, socket in ipairs(self.sockets) do
    if socket ~= self.socket then
      self:call_remote_method(socket, 'update_data', { self.socket, data })
    end
  end
end

---@param from string|nil
---@param msg string
function Sockets:log(from, msg)
  if self.show_logs then
    print(
      from and '[' .. from .. ']:' or ' ',
      msg
    )
  end
end

---@param data any
function Sockets:register_self(data)
  local sockets = self.get_socket_paths()

  for _, socket in ipairs(sockets) do
    if socket ~= self.socket then
      table.insert(self.sockets, socket)
      self:call_remote_method(socket, 'register_socket', { self.socket, data })
    end
  end
end

function Sockets:unregister_self()
  for _, socket in ipairs(self.sockets) do
    if socket ~= self.socket then
      self:log('unregister_self', 'Unregistering self to socket ' .. socket)
      self:call_remote_method(socket, 'unregister_socket', { self.socket })
    end
  end
end

---@return table
function Sockets.get_socket_paths()
  local cmd = "ss -lx | grep 'vim'"

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

  local f = assert(io.popen(cmd))
  local data = f:read('*a')
  f:close()

  return handle(data:split '\n')
end

---@param socket string
---@param name string
---@param args table
function Sockets:call_remote_method(socket, name, args)
  local cmd_fmt = 'lua package.loaded.sockets:%s(%s)'

  local arglist = ListToArgv(args)
  local cmd = string.format(cmd_fmt, name, arglist)

  self:call_remote_instance(socket, cmd)
end

---@param socket string
---@param cmd string
function Sockets:call_remote_instance(socket, cmd)
  local pipe = assert(vim.loop.new_pipe(true))

  pipe:connect(socket, function()
    local packed = msgpack.pack({ 0, 0, 'nvim_command', { cmd } })

    pipe:write(packed, function()
      self:log('call_remote_instance', 'Wrote to remote nvim instance: ' .. socket)
    end)
  end)
end

--- End client methods ---
--- Start server methods ---

---@param socket string
---@param data table
function Sockets:register_socket(socket, data)
  self:log('register_socket', 'Registering socket ' .. socket)

  table.insert(self.sockets, socket)
  self.updateData(data)
end

---@param socket string
function Sockets:unregister_socket(socket)
  self:log('unregister_socket', 'Unregistering socket ' .. socket)
  self.sockets[socket] = nil
end

---@param socket string
---@param data any
function Sockets:update_data(socket, data)
  self:log('update_data', 'Updating data from socket ' .. socket)
  self.dataUpdate(data)
end

return Sockets
