<div align='center'>

  # Vim Sockets :tv::earth_americas:
  The best way of sharing data between Vim instances is through pipes.  
  This is what this library does... Nothing more.
</div>
<br/>

## Environment

1. Copy the folder `lua/deps/vim-sockets` to your project's dependencies folder
2. Change the imports (**Lua** doesn't support relative imports)
3. And require it
  ```lua
  local VimSockets = require 'vim-sockets'
  ```

<br/>
<details>
  <summary>How I implemented relative imports</summary>

  ```lua
  ScriptPath = debug.getinfo(1, 'S').source:sub(2)
  package.path = package.path .. ';' .. ScriptPath:match '(.*)/.*/' .. '/deps/?.lua'
  ```

  `ScriptPath` is `lua/vplugin/init.lua`,  
  `:match` turns it into `lua`.
</details>

<br/>
<br/>
<br/>

## Setting up
```lua
---@class VimSockets
---@field socket    string
---@field dep_path  string
---@field sockets   string[]
---@field receivers table<string, fun(props: ReceiverProps)>

---@param dep_path    string # package.loaded...
---@param vim_events? boolean
function VimSockets:setup(dep_path, vim_events) end
```

- `dep_path` is the path to access itself in the loaded vim plugin
- `vim_events` create or not `:PrintLogs` and `:PrintSockets`

  By default the event `VimLeavePre` is setted with `:unregister_self()`.

<br/>
<br/>
<br/>

## Using

- `:on(event: string, fn: fun(props: ReceiverProps))`

  Sets a callback for when the said event is received.

- `:emit(event: string, data: any)`

  Emit the said event passing the said data to all the other instances.

- `:emit_to(socket: string, event: string: data: any)`

  Emit the said event with the said data to the said socket.

- `:unregister_self()`

  Unregister/disable/disconnect the current instance.

<br/>
<br/>
<br/>

## Types

```lua
---@class ReceiverProps
---@field event   string
---@field emitter string
---@field data    any
```
