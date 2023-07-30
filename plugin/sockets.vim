if exists('g:loaded_sockets') | finish | endif
let g:loaded_sockets = 1

lua << EOF
  require 'sockets':setup({}, true)
EOF
