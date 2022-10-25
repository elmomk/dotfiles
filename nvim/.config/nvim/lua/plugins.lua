-- Only required if you have packer configured as `opt`
-- vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'
  -- lsp
  use 'neovim/nvim-lspconfig'
  use 'prabirshrestha/async.vim'
  use 'prabirshrestha/asyncomplete.vim'
  use 'prabirshrestha/asyncomplete-lsp.vim'
  use 'prabirshrestha/vim-lsp'
  use 'mattn/vim-lsp-settings'
  -- telescope
  use 'sharkdp/fd'
  use 'nvim-treesitter/nvim-treesitter'
  use 'BurntSushi/ripgrep'
  use {
  'nvim-telescope/telescope.nvim', tag = '0.1.0',
-- or                            , branch = '0.1.x',
  requires = { {'nvim-lua/plenary.nvim'} }
}
  use 'hashivim/vim-terraform'
--  use 'dense-analysis/ale'
--  use 'neomake/neomake'
--  use 'shougo/ddc.vim'
--  use 'vim-denops/denops.vim'
--  use 'shougo/ddc-around'
--  use 'shougo/pum.vim'
--  use({
--  "folke/noice.nvim",
--  event = "VimEnter",
--  config = function()
--    require("noice").setup()
--  end,
--  requires = {
--    -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
--    "MunifTanjim/nui.nvim",
--    "rcarriga/nvim-notify",
--    }
--})
end)
