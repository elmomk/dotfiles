local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

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
	{
		"windwp/nvim-autopairs",
		opts = function()
			return require("plugins.config.autopairs")
		end,
	}, -- Autopairs, integrates with both cmp and treesitter
	{
		"numToStr/Comment.nvim",
		opts = function()
			return require("plugins.config.comment")
		end,
	},
	{
		"cbochs/portal.nvim",
		-- Ootional dependencies
		dependencies = { "cbochs/grapple.nvim" },
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		config = function()
			require("plugins.config.neotree")
		end,
		dependencies = {
			{ "kyazdani42/nvim-web-devicons" },
			{ "MunifTanjim/nui.nvim" },
			{
				"s1n7ax/nvim-window-picker",
				config = function()
					require("window-picker").setup()
				end,
			},
		},
	},
	{
		"akinsho/bufferline.nvim",
	},
	-- close buffers
	{ "moll/vim-bbye" },
	{ "nvim-lualine/lualine.nvim" },
	{
		"akinsho/toggleterm.nvim",
		opts = function()
			return require("plugins.config.toggleterm")
		end,
	},
	{
		"ahmedkhalf/project.nvim",
		opt = function()
			return require("plugins.config.project")
		end,
		config = function(_, opt)
			require("project_nvim").setup(opt)
		end,
	},
	{
		"lewis6991/impatient.nvim",
		config = function()
			require("impatient").enable_profile()
		end,
	},
	{ "lukas-reineke/indent-blankline.nvim" },
	{
		"goolord/alpha-nvim",
		opts = function()
			return require("plugins.config.alpha")
		end,
	},

	--	colorschemes
	{ "folke/lsp-colors.nvim" },
	-- { "folke/tokyonight.nvim",
	--     config = function()
	--   require("tokyonight").setup({
	--   style = "night"
	--   })
	--     end,
	--   },
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		config = function()
			local catppuccin = require("catppuccin")
			catppuccin.setup({
				flavour = "mocha",
			})
			catppuccin.load()
		end,
	},
	-- {
	-- 	"rebelot/kanagawa.nvim",
	-- 	config = function(_)
	-- 		require("kanagawa").setup({ transparent = true })
	-- 		require("kanagawa").load("dragon")
	-- 	end,
	-- },

	-- Debugging
  { "simrat39/rust-tools.nvim",
   config = function ()
  local rt = require("rust-tools")
   rt.setup({
   server = {
    on_attach = function(_, bufnr)
      -- Hover actions
      vim.keymap.set("n", "<Leader>mh", rt.hover_actions.hover_actions, { buffer = bufnr })
      -- Code action groups
      vim.keymap.set("n", "<Leader>ma", rt.code_action_group.code_action_group, { buffer = bufnr })
    end,
  },
  })
   end
  },
	{
		"mfussenegger/nvim-dap",
		opt = true,
		event = "BufReadPre",
		module = { "dap" },
		wants = { "nvim-dap-virtual-text", "DAPInstall.nvim", "nvim-dap-ui", "nvim-dap-python"}, --, "which-key.nvim" },
		dependencies = {
			"Pocco81/DAPInstall.nvim",
			"theHamsta/nvim-dap-virtual-text",
			"rcarriga/nvim-dap-ui",
			"mfussenegger/nvim-dap-python",
			"nvim-telescope/telescope-dap.nvim",
			{ "leoluz/nvim-dap-go", module = "dap-go" },
			{ "jbyuki/one-small-step-for-vimkind", module = "osv" },
		},
		-- config = function()
		-- 	require("plugins.config.dap").setup()
		-- end,
	},
	{
		"someone-stole-my-name/yaml-companion.nvim",
		dependencies = {
			{ "neovim/nvim-lspconfig" },
			{ "nvim-lua/plenary.nvim" },
			{ "nvim-telescope/telescope.nvim" },
		},
		config = function()
			require("telescope").load_extension("yaml_schema")
		end,
	},
	{
		"rmagatti/goto-preview",
		config = function()
			require("goto-preview").setup()
		end,
	},
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

	{
		"L3MON4D3/LuaSnip",
		opts = function()
			return require("plugins.config.snippets")
		end,
	}, --snippet engine
	{ "rafamadriz/friendly-snippets" }, -- a bunch of snippets to use

	{ "williamboman/nvim-lsp-installer" }, -- simple to use language server installer
	{ "neovim/nvim-lspconfig" }, -- enable LSP
	{ "williamboman/mason.nvim" },
	{ "williamboman/mason-lspconfig.nvim" },
	{ "jose-elias-alvarez/null-ls.nvim" }, -- for formatters and linters
	{
		"RRethy/vim-illuminate",
	},
	{
		"jcdickinson/codeium.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"hrsh7th/nvim-cmp",
		},
		config = function()
			require("codeium").setup({})
		end,
	},
	-- {
	-- 	"ExaFunction/codeium.vim",
	-- 	config = function()
	-- 		-- Change '<C-g>' here to any keycode you like.
	-- 		vim.keymap.set("i", "<C-g>", function()
	-- 			return vim.fn["codeium#Accept"]()
	-- 		end, { expr = true })
	-- 		-- vim.keymap.set("i", "<c-;>", function()
	-- 		-- 	return vim.fn["codeium#CycleCompletions"](1)
	-- 		-- end, { expr = true })
	-- 		-- vim.keymap.set("i", "<c-,>", function()
	-- 		-- 	return vim.fn["codeium#CycleCompletions"](-1)
	-- 		-- end, { expr = true })
	-- 		vim.keymap.set("i", "<c-x>", function()
	-- 			return vim.fn["codeium#Clear"]()
	-- 		end, { expr = true })
	-- 	end,
	-- },
	{ "hrsh7th/cmp-copilot" },
	{
		"github/copilot.vim",
		config = function()
			return require("plugins.config.copilot")
		end,
	},

	{
		"nvim-telescope/telescope.nvim",
		opts = function()
			return require("plugins.config.telescope")
		end,
		dependencies = {
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			{ "nvim-telescope/telescope-project.nvim" },
			{ "nvim-telescope/telescope-file-browser.nvim" },
			{ "nvim-lua/plenary.nvim" },
		},
	},
	{ "jremmen/vim-ripgrep" },
	-- { "nvim-lua/popup.nvim" },

	{ "junegunn/fzf.vim" },

	{
		"nvim-treesitter/nvim-treesitter",
		opts = function()
			return require("plugins.config.treesitter")
		end,
		build = ":TSUpdate",
		dependencies = {
			{ "nvim-treesitter/playground" },
		},
	},

	{ "mbbill/undotree" },
	{ "tpope/vim-fugitive" },
	{
		"ThePrimeagen/harpoon",
		-- keys = {
		--     { "<leader>a",  require("harpoon.mark").add_file,        silent = false,         desc = "add file to harpoon" },
		--     { "<leader>q",  require("harpoon.ui").toggle_quick_menu, silent = false,         desc = "toggle harpoon quick menu" },
		--   }
	},
	{
		"folke/zen-mode.nvim",
		opts = function()
			return require("plugins.config.zen")
		end,
	},
	{ "ThePrimeagen/git-worktree.nvim" },
	-- { "ThePrimeagen/refactoring.nvim" },
	-- { "ThePrimeagen/vim-be-good" },

	{
		"lewis6991/gitsigns.nvim",
		lazy = false,
		opts = function()
			return require("plugins.config.gitsigns")
		end,
	},

	{
		"ggandor/leap.nvim",
		config = function()
			require("leap").add_default_mappings()
		end,
	},
	-- { "folke/neoconf.nvim" }
	-- { "LazyVim/LazyVim" },
	{ "ggandor/leap.nvim" },
	-- { "folke/which-key.nvim" },
	-- todo comments
	{
		"folke/todo-comments.nvim",
		cmd = { "TodoTrouble", "TodoTelescope" },
		event = "BufReadPost",
		config = true,
    -- stylua: ignore
    keys = {
      { "]t",         function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
      { "[t",         function() require("todo-comments").jump_prev() end, desc = "Previous todo comment" },
      { "<leader>xt", "<cmd>TodoTrouble<cr>",                              desc = "Todo (Trouble)" },
      { "<leader>xT", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>",      desc = "Todo/Fix/Fixme (Trouble)" },
      { "<leader>st", "<cmd>TodoTelescope<cr>",                            desc = "Todo" },
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
	-- {
	-- 	"lukas-reineke/indent-blankline.nvim",
	-- 	event = "BufReadPost",
	-- 	opts = {
	-- 		-- char = "▏",
	-- 		char = "│",
	-- 		filetype_exclude = { "help", "alpha", "dashboard", "neo-tree", "NvimTree", "Trouble", "lazy" },
	-- 		show_trailing_blankline_indent = false,
	-- 		show_current_context = true,
	-- 		show_current_context_start = true,
	-- 	},
	-- },
	-- noicer ui
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {
			-- cmdline = {
			--      view = "cmdline",
			-- 	format = {
			-- 		search_down = {
			-- 			view = "cmdline",
			-- 		},
			-- 		search_up = {
			-- 			view = "cmdline",
			-- 		},
			-- 	},
			-- },
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
      {
        "<S-Enter>",
        function() require("noice").redirect(vim.fn.getcmdline()) end,
        mode = "c",
        desc =
        "Redirect"
      },
      {
        "<leader>snl",
        function() require("noice").cmd("last") end,
        desc =
        "Noice Last Message"
      },
      {
        "<leader>snh",
        function() require("noice").cmd("history") end,
        desc =
        "Noice History"
      },
      { "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice All" },
      {
        "<c-f>",
        function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end,
        silent = true,
        expr = true,
        desc =
        "Scroll forward",
        mode = {
          "i", "n", "s" }
      },
      {
        "<c-b>",
        function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end,
        silent = true,
        expr = true,
        desc =
        "Scroll forward",
        mode = {
          "i", "n", "s" }
      },
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
      -- { "<leader>qs", function() require("persistence").load() end,                desc = "Restore Session" },
      -- { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    },
	},

	-- makes some plugins dot-repeatable like leap
	-- { "tpope/vim-repeat", event = "VeryLazy" },
}

vim.opt.rtp:prepend(lazypath)

require("lazy").setup(plugins, { silent = true })
