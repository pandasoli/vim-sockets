local msgpack = require 'deps.msgpack'

require 'lib.list_to_argv'
require 'lib.json'
require 'sockets.std'
require 'sockets.utils'


local Sockets = {
  socket = vim.v.servername,
  data = {},
  sockets = {}
}

---@param data string
function Sockets:setup(data)
  self.data = data or {}
  self:register_self()

  vim.api.nvim_create_autocmd('ExitPre', {
    callback = function() self:unregister_self() end
  })

  vim.cmd([[command! -nargs=0 PrintSockets lua package.loaded.sockets:print_sockets()]])
end

function Sockets:print_sockets()
  print(EncodeJSON(self.sockets))
end

function Sockets:register_self()
  local sockets = self:get_nvim_socket_paths()

  for _, socket in pairs(sockets) do
    if socket ~= self.socket then
      self:call_remote_method(socket, 'register_socket_setup', { self.socket, self.data })
    end
  end
end

function Sockets:unregister_self()
  for socket, _ in pairs(self.sockets) do
    if socket ~= self.socket then
      print('Unregistering self to socket ' .. socket)
      self:call_remote_method(socket, 'unregister_socket', { self.socket })
    end
  end
end

---@return table
function Sockets:get_nvim_socket_paths()
  local cmd = "ss -lx | grep 'lvim'"

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

  self:call_remote_nvim_instance(socket, cmd)
end

---@param socket string
---@param cmd string
function Sockets:call_remote_nvim_instance(socket, cmd)
  local remote_nvim_instance = assert(vim.loop.new_pipe(true))

  remote_nvim_instance:connect(socket, function()
    local packed = msgpack.pack({ 0, 0, 'nvim_command', { cmd } })

    remote_nvim_instance:write(packed, function()
      print('Wrote to remote nvim instance: ' .. socket)
    end)
  end)
end

--- End client methods ---
--- Start server methods ---

---@param socket string
---@param data table
function Sockets:register_socket_setup(socket, data)
  self:register_socket(socket, data)

  print('Sending self to socket ' .. socket)
  self:call_remote_method(socket, 'register_socket', { self.socket, self.data })
end

---@param socket string
---@param data table
function Sockets:register_socket(socket, data)
  print('Registering socket ' .. socket)
  self.sockets[socket] = data
end

---@param socket string
function Sockets:unregister_socket(socket)
  print('Unregistering socket ' .. socket)
  self.sockets[socket] = nil
end

return Sockets
