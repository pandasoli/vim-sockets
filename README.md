<div align='center'>

  # Vim Sockets :tv::earth_americas:
  The best way of sharing data between Vim instances is through pipes.  
  This is what this library does... Nothing more.
</div>
<br/>

## Setting up environment

1. Copy the folder `/lua` to your project's dependencies folder
2. Require it
  ```lua
    local VimSockets = require 'vim-sockets.sockets.init'
  ```

<br/>

## Using

This library doesn't use OOP instances, so after you import the module you can already initialize it.
```lua
---@param data any
---@param show_logs boolean|nil
VimSockets:setup()
```

- `data` is the setup data. It's not strictly needed
- `show_logs` is for showing debugging messages

:information_source: The data you want to share can be of any type.  
:information_source: You can change `show_logs` by `VimSockets.show_logs`.

<br/>

`Sockets:print_sockets()` is usefull to check if the library is getting all the expected sockets.

`Sockets.dataChanged(data)` is called anytime a socket (another vim instance) updates the data.  
It's expected that you overwrite this function.

<br/>

There are some commands to help us in the development.  
You must delete them (removing from the source code of `Sockets:setup`).

- `PrintSockets` Prints a list of the got sockets (uses `Sockets:print_sockets`)
- `UpdateSocketData` Updates the data

<br/>

## Development

:information_source: Read [#using](#using) before keep reading.

By default `Sockets` already has props that help us developmenting.
- `show_logs` enabled
- `dataChanged` shows the received data
- `sockets` stores other sockets of vim instances
- `socket` the current vim instance's socket

### Startup
In `:setup` it sets `self.show_logs` to the received arg for it,  
and calls `:register_self` passing the received `data` (as said before, it's not store).

<br/>

`:register_self(data)`  
Calls all the other Vim instances to register the current Vim instance.

It gets all the Vim instances with `.get_socket_paths()`.  
It adds the instances' socket in `Sockets.sockets` to call them when needed.  
And calls the other instances to register this one.

PS: It asks `:call_remote_method` to call `:register_socket` of the other instances.

<br/>

`:call_remote_method(socket, name, args)`
- Formats the command `lua package.loaded.sockets:%s(%s)` with `name` and `args`
- Calls `:call_remove_instance(socket, cmd)`

<br/>

`:call_remote_instance(socket, cmd)`
- Created a pipe
- Connects to the received socket
- Format the `cmd` with `msgpack` (library)
- Send it to the vim instance

<br/>

`:register_socket(socket, data)`  
- Inserts `socket` into `Sockets.sockets`
- Calls `updateData(data)` as the last opened instances should have priority

<br/>

`:updateData(data)`  
- Calls `.dataUpdate(data)`
- Loops through each instance calling `:update_data` (with `:call_remote_method`)

<br/>

`:update_data(data)`  
- Calls `.dataUpdate(data)`

<br/><br/>

### Shutdown

`:unregister_self()`  
- Calls `:unregister_socket(socket)` of each instance

<br/>

`:unregister_socket(socket)`
- Removed the socket from the list of sockets

<br/><br/>

### Update

`:updateData(data)`  
- Calls `.dataUpdate(data)`
- Loops through each instances calling `:update_data`

<br/>

:information_source: You might notice that the function `:update_data(data)` is only calling `.dataUpdate(data)`.  
So why not calling it directly? Because of the log message.  
I don't want you to have to add it when necessary inside `.dataUpdate`.
