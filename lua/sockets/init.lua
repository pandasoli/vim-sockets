local msgpack = require 'deps.msgpack'

require 'lib.list_to_argv'
require 'lib.json'
require 'sockets.std'
require 'sockets.utils'


local Sockets = {
  socket = vim.v.servername,
  sockets = {}
}

function Sockets:setup()
  self:register_self()

  vim.api.nvim_create_autocmd('ExitPre', {
    callback = function() self:unregister_self() end
  })

  vim.cmd([[command! -nargs=0 PrintPeers lua package.loaded.sockets:print_peers()]])
end

function Sockets:print_peers()
  print(EncodeJSON(self.sockets))
end

function Sockets:register_self()
  local sockets = self:get_nvim_socket_paths()

  for _, socket in pairs(sockets) do
    if socket ~= self.socket then
      self:call_remote_method(socket, 'register_peer_setup', { self.socket })
    end
  end
end

function Sockets:unregister_self()
  for _, socket in ipairs(self.sockets) do
    if socket ~= self.socket then
      print('Unregistering self to peer ' .. socket)
      self:call_remote_method(socket, 'unregister_peer', { self.socket })
    end
  end
end

---@return table
function Sockets:get_nvim_socket_paths()
  local cmd = "ss -lx | grep 'lvim'"
  local sockets = {}
  local data

  local function handle(lines)
    for i = 1, #lines do
      local socket = lines[i]:match '%s(/.-)%s'

      if socket then
        table.insert(sockets, socket)
      end
    end
  end

  local f = assert(io.popen(cmd))
  data = f:read('*a')
  f:close()

  handle(data:split '\n')
  return sockets
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
function Sockets:register_peer_setup(socket)
  self:register_peer(socket)

  print('Sending self to peer ' .. socket)
  self:call_remote_method(socket, 'register_peer', { self.socket })
end

---@param socket string
function Sockets:register_peer(socket)
  print('Registering socket ' .. socket)
  table.insert(self.sockets, socket)
end

---@param socket string
function Sockets:unregister_peer(socket)
  print('Unregistering socket ' .. socket)

  local peers = {}

  for _, socket_ in ipairs(self.sockets) do
    if socket_ ~= socket then
      table.insert(peers, socket)
    end
  end

  self.sockets = peers
end

return Sockets
