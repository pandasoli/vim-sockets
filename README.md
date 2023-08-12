<div align='center'>

  # Vim Sockets :tv::earth_americas:
  The best way of sharing data between Vim instances is through pipes.  
  This is what this library does... Nothing more.
</div>
<br/>

## Setting up environment

1. Copy the folder `/lua` to your project's dependencies folder
2. And require it
  ```lua
  local VimSockets = require 'vim-sockets.sockets.init'
  ```

<br/>

## Using

After requiring it the next step is setting up.

If you're gonna use it globaly use the function `:setup`,  
If you're gonna store an instance of it use `:new`.

Both receive `vim_events: boolean` to initialize some Vim commands for debugging.

Functions:
- `:on(event: string, fn: fun(props: ReceiverProps))`

  Sets a function to be called when the said event is called.

  ```lua
  ---@class ReceiverProps
  ---@field event string
  ---@field socket_emmiter string
  ---@field data any
  ```

- `:emmit(event: string, data: any)`

  Calls the said event sending the said data.

<br/>

By default it creates the Vim autocmd `PreExit` to call `:unregister_self`.  
But if you want to close the connection with the other instances you might call it.
