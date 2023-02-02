local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
local opts = { silent = true }
vim.keymap.set("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
local plugins = {
	{ "folke/trouble.nvim" }, -- enables lsp trouble shooting
	{ "ellisonleao/glow.nvim" }, -- show markdown files
	{ "windwp/nvim-autopairs" }, -- Autopairs, integrates with both cmp and treesitter
	{ "numToStr/Comment.nvim" },
	{ "JoosepAlviste/nvim-ts-context-commentstring" },
	{ "kyazdani42/nvim-web-devicons" },
	{ "kyazdani42/nvim-tree.lua" },
	{ "akinsho/bufferline.nvim" },
	{ "moll/vim-bbye" },
	{ "nvim-lualine/lualine.nvim" },
	{ "akinsho/toggleterm.nvim" },
	{ "ahmedkhalf/project.nvim" },
	{ "lewis6991/impatient.nvim" },
	{ "lukas-reineke/indent-blankline.nvim" },
	{ "goolord/alpha-nvim" },

--	colorschemes
	{ "folke/lsp-colors.nvim" },
	{ "folke/tokyonight.nvim" },
  { "rebelot/kanagawa.nvim" },

	{ "hrsh7th/nvim-cmp" }, -- The completion plugin
	{ "hrsh7th/cmp-buffer" }, -- buffer completions
	{ "hrsh7th/cmp-path" }, -- path completions
	{ "saadparwaiz1/cmp_luasnip" }, -- snippet completions
	{ "hrsh7th/cmp-nvim-lsp" },
	{ "hrsh7th/cmp-nvim-lua" },

	{ "L3MON4D3/LuaSnip" }, --snippet engine
	{ "rafamadriz/friendly-snippets" }, -- a bunch of snippets to use

	{ "williamboman/nvim-lsp-installer" }, -- simple to use language server installer
	{ "neovim/nvim-lspconfig" }, -- enable LSP
	{ "williamboman/mason.nvim" },
	{ "williamboman/mason-lspconfig.nvim" },
	{ "jose-elias-alvarez/null-ls.nvim" }, -- for formatters and linters
	{ "RRethy/vim-illuminate" },
	{ "github/copilot.vim" },

	{ "nvim-telescope/telescope.nvim", dependencies = { { "nvim-lua/plenary.nvim" } } },
	{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	{ "nvim-telescope/telescope-project.nvim" },
	{ "nvim-telescope/telescope-file-browser.nvim" },
	{ "jremmen/vim-ripgrep" },
	{ "nvim-lua/popup.nvim" },

	{ "junegunn/fzf.vim"},

	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
	{ "nvim-treesitter/playground" },

	{ "mbbill/undotree" },
	{ "tpope/vim-fugitive" },
	{ "ThePrimeagen/harpoon" },
	{ "folke/zen-mode.nvim" },
	{ "ThePrimeagen/git-worktree.nvim" },
	{ "ThePrimeagen/refactoring.nvim" },
	{ "ThePrimeagen/vim-be-good" },

	{ "lewis6991/gitsigns.nvim" },

	{"ggandor/leap.nvim"},
  -- { "folke/neoconf.nvim" }
}
vim.opt.rtp:prepend(lazypath)

require("lazy").setup(plugins, opts)
