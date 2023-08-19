ScriptPath = debug.getinfo(1, 'S').source:sub(2)
package.path = package.path .. ';' .. ScriptPath:match '(.*)/.*/' .. '/deps/?.lua'

local VimSockets = require 'deps.vim-sockets'


---@class VPlugin
---@field vim_sockets VimSockets
local VPlugin = {}

function VPlugin:setup()
  self.vim_sockets = VimSockets

  VimSockets:setup('package.loaded.vplugin.vim_sockets', true)

  VimSockets:on('great', function(props)
    print(props.data)
  end)

  VimSockets:emit('great', 'Hello')
end

return VPlugin
