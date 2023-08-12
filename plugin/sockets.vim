if exists('g:loaded_sockets') | finish | endif
let g:loaded_sockets = 1

lua << EOF
  local Sockets = require 'sockets'

  Sockets:setup(true)

  Sockets:on('msg', function(props)
    print(props.data)
  end)

  vim.api.nvim_create_user_command('SendMsg', function() Sockets:emmit('msg', 'hi') end, { nargs = 0 })

  Sockets:unregister_self()
EOF
