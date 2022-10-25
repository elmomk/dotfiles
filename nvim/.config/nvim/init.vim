lua require('plugins')

lua <<EOF
  require'lspconfig'.terraformls.setup{}
  local builtin = require('telescope.builtin')
  vim.keymap.set('n', 'ff', builtin.find_files, {})
  vim.keymap.set('n', 'fg', builtin.live_grep, {})
  vim.keymap.set('n', 'fb', builtin.buffers, {})
  vim.keymap.set('n', 'fh', builtin.help_tags, {})
EOF

set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc
