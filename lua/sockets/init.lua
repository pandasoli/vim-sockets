local Discord = require 'sockets.discord'
local msgpack = require 'deps.msgpack'

require 'sockets.std'
require 'lib.list_to_argv'


local Sockets = {
  socket = vim.v.servername,
  peers = {}
}

function Sockets:setup()
  local seed_nums = {}
  self.socket:gsub('.', function(c) table.insert(seed_nums, c:byte()) end)
  self.id = Discord.generate_uuid(tonumber(table.concat(seed_nums)) / os.clock())

  self:register_self()

  vim.api.nvim_create_autocmd('ExitPre', {
    callback = function() self:unregister_self() end
  })

  vim.cmd([[command! -nargs=0 PrintPeers lua package.loaded.sockets:print_peers()]])
end

function Sockets:print_peers()
  print(ListToArgv(self.peers))
end

function Sockets:register_self()
  local sockets = self:get_nvim_socket_paths()

  for _, socket in pairs(sockets) do
    if socket ~= self.socket then
      self:call_remote_method(socket, 'register_peer_setup', { self.id, self.socket })
    end
  end
end

function Sockets:unregister_self()
  local self_as_peer = {
    socket = self.socket
  }

  for id, peer in pairs(self.peers) do
    if id ~= self.id then
      print('Unregistering self to peer ' .. id)
      self:call_remote_method(peer.socket, 'unregister_peer', { self.id, self_as_peer })
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

---@param id string
---@param socket string
function Sockets:register_peer_setup(id, socket)
  self:register_peer(id, socket)

  print('Sending self to peer ' .. id)
  self:call_remote_method(socket, 'register_peer', { self.id, self.socket })
end

---@param id string
---@param socket string
function Sockets:register_peer(id, socket)
  print('Registering peer ' .. id)

  self.peers[id] = {
    socket = socket
  }
end

---@param id string
---@param peer table
function Sockets:unregister_peer(id, peer)
  print('Unregistering peer ' .. id .. '... ' .. vim.inspect(peer))

  local peers = {}

  for peer_id, data in pairs(self.peers) do
    if peer_id ~= id then
      peers[id] = data
    end
  end

  self.peers = peers
end

return Sockets
