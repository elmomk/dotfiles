local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local opts = { silent = true }

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
--
-- vim.cmd([[
--   augroup lazy_user_config
--     autocmd!
--     autocmd BufWritePost lazy.lua | Lazy update
--   augroup end
-- ]])

local plugins = {
	{ "folke/lazy.nvim" },
	{ "folke/trouble.nvim" }, -- enables lsp trouble shooting
	{ "ellisonleao/glow.nvim", config = true, cmd = "Glow" }, -- show markdown files
	{ "windwp/nvim-autopairs" }, -- Autopairs, integrates with both cmp and treesitter
	{ "numToStr/Comment.nvim" },
	{ "JoosepAlviste/nvim-ts-context-commentstring" },
	-- { "kyazdani42/nvim-web-devicons" },
	{ "kyazdani42/nvim-tree.lua" },
	{
		"nvim-neo-tree/neo-tree.nvim",
		dependencies = {
			{ "kyazdani42/nvim-web-devicons" },
			{ "MunifTanjim/nui.nvim" },
		},
	},
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

	-- The completion plugin
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			{ "hrsh7th/cmp-buffer" }, -- buffer completions
			{ "hrsh7th/cmp-path" }, -- path completions
			{ "saadparwaiz1/cmp_luasnip" }, -- snippet completions
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "hrsh7th/cmp-nvim-lua" },
		},
	},

	{ "L3MON4D3/LuaSnip" }, --snippet engine
	{ "rafamadriz/friendly-snippets" }, -- a bunch of snippets to use

	{ "williamboman/nvim-lsp-installer" }, -- simple to use language server installer
	{ "neovim/nvim-lspconfig" }, -- enable LSP
	{ "williamboman/mason.nvim" },
	{ "williamboman/mason-lspconfig.nvim" },
	{ "jose-elias-alvarez/null-ls.nvim" }, -- for formatters and linters
	{ "RRethy/vim-illuminate" },
	{ "github/copilot.vim" },

	{ "nvim-lua/plenary.nvim" },
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			{ "nvim-telescope/telescope-project.nvim" },
			{ "nvim-telescope/telescope-file-browser.nvim" },
		},
	},
	{ "jremmen/vim-ripgrep" },
	{ "nvim-lua/popup.nvim" },

	{ "junegunn/fzf.vim" },

	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate", dependencies = {
		{ "nvim-treesitter/playground" },
	} },

	{ "mbbill/undotree" },
	{ "tpope/vim-fugitive" },
	{ "ThePrimeagen/harpoon" },
	{ "folke/zen-mode.nvim" },
	{ "ThePrimeagen/git-worktree.nvim" },
	{ "ThePrimeagen/refactoring.nvim" },
	-- { "ThePrimeagen/vim-be-good" },

	{ "lewis6991/gitsigns.nvim" },

	{ "ggandor/leap.nvim" },
	-- { "folke/neoconf.nvim" }
	-- { "folke/which-key.nvim" },
	-- todo comments
	{
		"folke/todo-comments.nvim",
		cmd = { "TodoTrouble", "TodoTelescope" },
		event = "BufReadPost",
		config = true,
  -- stylua: ignore
  keys = {
    { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
    { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous todo comment" },
    { "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
    { "<leader>xT", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
    { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Todo" },
  },
	},

	-- {
	--   "stevearc/dressing.nvim",
	--   lazy = true,
	--   -- init = function()
	--   --   ---@diagnostic disable-next-line: duplicate-set-field
	--   --   vim.ui.select = function(...)
	--   --     require("lazy").load({ plugins = { "dressing.nvim" } })
	--   --     return vim.ui.select(...)
	--   --   end
	--   --   ---@diagnostic disable-next-line: duplicate-set-field
	--   --   vim.ui.input = function(...)
	--   --     require("lazy").load({ plugins = { "dressing.nvim" } })
	--   --     return vim.ui.input(...)
	--   --   end
	--   -- end,
	-- },

	-- indent guides for Neovim
	{
		"lukas-reineke/indent-blankline.nvim",
		event = "BufReadPost",
		opts = {
			-- char = "▏",
			char = "│",
			filetype_exclude = { "help", "alpha", "dashboard", "neo-tree", "NvimTree", "Trouble", "lazy" },
			show_trailing_blankline_indent = false,
			show_current_context = true,
			show_current_context_start = true,
		},
	},
	-- noicer ui
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
			},
		},
  -- stylua: ignore
  keys = {
    { "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect"},
    { "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
    { "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice History" },
    { "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice All" },
    { "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, desc = "Scroll forward", mode = {"i", "n", "s"} },
    { "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, desc = "Scroll forward", mode = {"i", "n", "s"} },
  },
		dependencies = {
			-- Better `vim.notify()`
			{
				"rcarriga/nvim-notify",
				keys = {
					{
						"<leader>n",
						function()
							require("notify").dismiss({ silent = true, pending = true })
						end,
						desc = "Delete all Notifications",
					},
				},
				opts = {
					timeout = 3000,
					max_height = function()
						return math.floor(vim.o.lines * 0.75)
					end,
					max_width = function()
						return math.floor(vim.o.columns * 0.75)
					end,
				},
			},
		},
	},

	-- -- measure startuptime
	-- {
	--   "dstein64/vim-startuptime",
	--   cmd = "StartupTime",
	--   config = function()
	--     vim.g.startuptime_tries = 10
	--   end,
	-- },

	-- session management
	{
		"folke/persistence.nvim",
		event = "BufReadPre",
		opts = { options = { "buffers", "curdir", "tabpages", "winsize", "help" } },
  -- stylua: ignore
  keys = {
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
  },
	},

	-- makes some plugins dot-repeatable like leap
	-- { "tpope/vim-repeat", event = "VeryLazy" },
}
vim.opt.rtp:prepend(lazypath)

require("lazy").setup(plugins, opts)
