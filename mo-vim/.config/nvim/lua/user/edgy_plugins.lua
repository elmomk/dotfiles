-- Install packer reference: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
local install_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
local is_bootstrap = false
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
	is_bootstrap = true
	vim.fn.execute("!git clone https://github.com/wbthomason/packer.nvim " .. install_path)
	vim.cmd([[packadd packer.nvim]])
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost edgy_plugins.lua source <afile> | PackerSync
  augroup end
]])

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
	return
end

-- Have packer use a popup window
packer.init({
	display = {
		open_fn = function()
			return require("packer.util").float({ border = "rounded" })
		end,
	},
	git = {
		clone_timeout = 300, -- Timeout, in seconds, for git clones
	},
})

require("packer").startup(function(use)
	-- Install your plugins here
	use({ "wbthomason/packer.nvim" }) -- Have packer manage itself
	use({ "folke/trouble.nvim" }) -- enables lsp trouble shooting
	use({ "ellisonleao/glow.nvim" }) -- show markdown files
	use({ "windwp/nvim-autopairs" }) -- Autopairs, integrates with both cmp and treesitter
	use({ "numToStr/Comment.nvim" })
	use({ "JoosepAlviste/nvim-ts-context-commentstring" })
	use({ "kyazdani42/nvim-web-devicons" })
	use({ "kyazdani42/nvim-tree.lua" })
	use({ "akinsho/bufferline.nvim" })
	use({ "moll/vim-bbye" })
	use({ "nvim-lualine/lualine.nvim" })
	use({ "akinsho/toggleterm.nvim" })
	use({ "ahmedkhalf/project.nvim" })
	use({ "lewis6991/impatient.nvim" })
	use({ "lukas-reineke/indent-blankline.nvim" })
	use({ "goolord/alpha-nvim" })

	-- Colorschemes
	use({ "folke/lsp-colors.nvim" })
	use({ "folke/tokyonight.nvim" })
  use({ "rebelot/kanagawa.nvim" })

	-- cmp plugins
	use({ "hrsh7th/nvim-cmp" }) -- The completion plugin
	use({ "hrsh7th/cmp-buffer" }) -- buffer completions
	use({ "hrsh7th/cmp-path" }) -- path completions
	use({ "saadparwaiz1/cmp_luasnip" }) -- snippet completions
	use({ "hrsh7th/cmp-nvim-lsp" })
	use({ "hrsh7th/cmp-nvim-lua" })

	-- snippets
	use({ "L3MON4D3/LuaSnip" }) --snippet engine
	use({ "rafamadriz/friendly-snippets" }) -- a bunch of snippets to use

	-- LSP
	-- use { "williamboman/nvim-lsp-installer" } -- simple to use language server installer
	use({ "neovim/nvim-lspconfig" }) -- enable LSP
	use({ "williamboman/mason.nvim" })
	use({ "williamboman/mason-lspconfig.nvim" })
	-- use { "jose-elias-alvarez/null-ls.nvim" } -- for formatters and linters
	use({ "jose-elias-alvarez/null-ls.nvim" }) -- for formatters and linters
	use({ "RRethy/vim-illuminate" })
	use({ "github/copilot.vim" })

	-- Telescope
	use({ "nvim-telescope/telescope.nvim", requires = { { "nvim-lua/plenary.nvim" } } })
	use({ "nvim-telescope/telescope-fzf-native.nvim", run = "make" })
	use({ "nvim-telescope/telescope-project.nvim" })
	use({ "nvim-telescope/telescope-file-browser.nvim" })
	use({ "jremmen/vim-ripgrep" })
	-- use { "nvim-lua/popup.nvim" }

	-- -- fzf
	-- use { "junegunn/fzf.vim"}

	-- Treesitter
	use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" })

	-- the primeagen's plugins setup
	use({ "mbbill/undotree" })
	use({ "tpope/vim-fugitive" })
	use({ "ThePrimeagen/harpoon" })
	use({ "folke/zen-mode.nvim" })
	-- worktree
	use({ "ThePrimeagen/git-worktree.nvim" })
	-- use { "ThePrimeagen/refactoring.nvim" }
	-- use { "ThePrimeagen/vim-be-good" }

	-- Git
	use({ "lewis6991/gitsigns.nvim" })

	use {"ggandor/leap.nvim",
  -- config = function()
  --   local leap = require "leap"
  --   leap.set_keymaps {
  --     normal = "s",
  --     visual = "S",
  --   }
  -- end,
  }
	-- use({
	-- 	"chentoast/marks.nvim",
	-- 	event = "BufReadPre",
	-- 	config = function()
	-- 		require("marks").setup()
	-- 	end,
	-- })
-- use {
--   'phaazon/mind.nvim',
--   branch = 'v2.2',
--   requires = { 'nvim-lua/plenary.nvim' },
--   config = function()
--     require'mind'.setup()
--   end
-- }

	-- -- DAP
	-- use { "ravenxrz/DAPInstall.nvim" }
	-- use { "mfussenegger/nvim-dap" }
	-- use { "rcarriga/nvim-dap-ui" }
	-- use { "theHamsta/nvim-dap-virtual-text"}
	-- use {"nvim-telescope/telescope-dap.nvim"}
	-- use { "leoluz/nvim-dap-go"}
	-- use { "mfussenegger/nvim-dap-python"}

	-- -- remote ssh
	-- use {"chipsenkbeil/distant.nvim",
	-- config = function()
	--   require('distant').setup {
	--     -- Applies Chip's personal settings to every machine you connect to
	--     --
	--     -- 1. Ensures that distant servers terminate with no connections
	--     -- 2. Provides navigation bindings for remote directories
	--     -- 3. Provides keybinding to jump into a remote file's parent directory
	--     ['*'] = require('distant.settings').chip_default()
	--   }
	-- end}
	-- Add custom plugins to packer from ~/.config/nvim/lua/custom/plugins.lua
	-- local has_plugins, plugins = pcall(require, 'custom.plugins')
	-- if has_plugins then
	--   plugins(use)
	-- end

	if is_bootstrap then
		require("packer").sync()
	end
end)

-- When we are bootstrapping a configuration, it doesn't
-- make sense to execute the rest of the init.lua.
--
-- You'll need to restart nvim, and then it will work.
if is_bootstrap then
	print("==================================")
	print("    Plugins are being installed")
	print("    Wait until Packer completes,")
	print("       then restart nvim")
	print("==================================")
	return
end
