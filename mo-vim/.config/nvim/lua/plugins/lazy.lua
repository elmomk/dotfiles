vim.g.python3_host_prog = '$HOME/venv/bin/python3'
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

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
		dependencies = { "cbochs/grapple.nvim" },
	},
  ---@type LazySpec
{
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  keys = {
    -- 👇 in this section, choose your own keymappings!
    {
      "<leader>-",
      "<cmd>Yazi<cr>",
      desc = "Open yazi at the current file",
    },
    {
      -- Open in the current working directory
      "<leader>cw",
      "<cmd>Yazi cwd<cr>",
      desc = "Open the file manager in nvim's working directory" ,
    },
    {
      -- NOTE: this requires a version of yazi that includes
      -- https://github.com/sxyazi/yazi/pull/1305 from 2024-07-18
      '<c-up>',
      "<cmd>Yazi toggle<cr>",
      desc = "Resume the last yazi session",
    },
  },
  ---@type YaziConfig
  opts = {
    -- if you want to open yazi instead of netrw, see below for more info
    open_for_directories = false,
    keymaps = {
      show_help = '<f1>',
    },
  },
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

	{ "aquasecurity/vim-tfsec" },
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
		-- pin version to avoid breaking changes
		--  6c84bc75c64f778e9f1dcb798ed41c7fcb93b639
		commit = "6c84bc75c64f778e9f1dcb798ed41c7fcb93b639",
	},

	{
		"L3MON4D3/LuaSnip",
		opts = function()
			return require("plugins.config.snippets")
		end,
	}, --snippet engine
	{ "rafamadriz/friendly-snippets" }, -- a bunch of snippets to use
	{ "neovim/nvim-lspconfig" }, -- enable LSP
	{
		"williamboman/mason.nvim",
		-- build = ":MasonUpdate",
	},
	{ "williamboman/mason-lspconfig.nvim" },
	{ "nvimtools/none-ls.nvim" }, -- for formatters and linters (replacement for null-ls)
	{
		"RRethy/vim-illuminate",
	},
	{
		"jcdickinson/codeium.nvim",
		dependencies = {
			-- "jcdickinson/http.nvim",
			"nvim-lua/plenary.nvim",
			"hrsh7th/nvim-cmp",
		},
		config = function()
			require("codeium").setup({})
		end,
	},
	-- {
	-- 	"CopilotC-Nvim/CopilotChat.nvim",
	-- 	-- python -m venv venv
	-- 	-- pip install python-dotenv requests pynvim==0.5.0 prompt-toolkit tiktoken
	-- 	opts = {
	-- 		show_help = "no", -- Show help text for CopilotChatInPlace, default: yes
	-- 		debug = false, -- Enable or disable debug mode, the log file will be in ~/.local/state/nvim/CopilotChat.nvim.log
	-- 		disable_extra_info = "no", -- Disable extra information (e.g: system prompt) in the response.
	-- 		language = "English", -- Copilot answer language settings when using default prompts. Default language is English.
	-- 		-- proxy = "socks5://127.0.0.1:3000", -- Proxies requests via https or socks.
	-- 		-- temperature = 0.1,
 --      prompts = { -- Set dynamic prompts for CopilotChat commands
 --        Explain = 'Explain how it works.',
 --        Tests = 'Gnerate unit tests.',
 --      }
	-- 	},
	-- 	build = function()
	-- 		vim.notify("Please update the remote plugins by running ':UpdateRemotePlugins', then restart Neovim.")
	-- 	end,
	-- 	event = "VeryLazy",
	-- },
	-- {
	-- 	"github/copilot.vim",
	-- 	dependencies = {
	-- 		"hrsh7th/cmp-copilot",
	-- 	},
	-- 	config = function()
	-- 		return require("plugins.config.copilot")
	-- 	end,
	-- },

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
		"folke/flash.nvim",
		event = "VeryLazy",
		---@type Flash.Config
		opts = {},
		keys = {
			{
				"s",
				mode = { "n", "x", "o" },
				function()
					-- default options: exact mode, multi window, all directions, with a backdrop
					require("flash").jump()
				end,
				desc = "Flash",
			},
			{
				"S",
				mode = { "n", "o", "x" },
				function()
					-- show labeled treesitter nodes around the cursor
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
			{
				"r",
				mode = "o",
				function()
					-- jump to a remote location to execute the operator
					require("flash").remote()
				end,
				desc = "Remote Flash",
			},
			{
				"R",
				mode = { "n", "o", "x" },
				function()
					-- show labeled treesitter nodes around the search matches
					require("flash").treesitter_search()
				end,
				desc = "Treesitter Search",
			},
		},
	},
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
--	{
--		"folke/noice.nvim",
--		event = "VeryLazy",
--		opts = {
--			lsp = {
--				override = {
--					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
--					["vim.lsp.util.stylize_markdown"] = true,
--					["cmp.entry.get_documentation"] = true,
--				},
--			},
--			presets = {
--				bottom_search = true,
--				command_palette = true,
--				long_message_to_split = true,
--				inc_rename = true,
--				lsp_doc_border = true,
--				cmdline_output_to_split = true,
--			},
--		},
--		keys = {
--			{
--				"<S-Enter>",
--				function()
--					require("noice").redirect(vim.fn.getcmdline())
--				end,
--				mode = "c",
--				desc = "Redirect",
--			},
--			{
--				"<leader>snl",
--				function()
--					require("noice").cmd("last")
--				end,
--				desc = "Noice Last Message",
--			},
--			{
--				"<leader>snh",
--				function()
--					require("noice").cmd("history")
--				end,
--				desc = "Noice History",
--			},
--			{
--				"<leader>sna",
--				function()
--					require("noice").cmd("all")
--				end,
--				desc = "Noice All",
--			},
--			{
--				"<c-f>",
--				function()
--					if not require("noice.lsp").scroll(4) then
--						return "<c-f>"
--					end
--				end,
--				silent = true,
--				expr = true,
--				desc = "Scroll forward",
--				mode = {
--					"i",
--					"n",
--					"s",
--				},
--			},
--			{
--				"<c-b>",
--				function()
--					if not require("noice.lsp").scroll(-4) then
--						return "<c-b>"
--					end
--				end,
--				silent = true,
--				expr = true,
--				desc = "Scroll forward",
--				mode = {
--					"i",
--					"n",
--					"s",
--				},
--			},
--		},
--		dependencies = {
--			{
--				"rcarriga/nvim-notify",
--				keys = {
--					{
--						"<leader>n",
--						function()
--							require("notify").dismiss({ silent = true, pending = true })
--						end,
--						desc = "Delete all Notifications",
--					},
--				},
--				opts = {
--					timeout = 3000,
--					max_height = function()
--						return math.floor(vim.o.lines * 0.75)
--					end,
--					max_width = function()
--						return math.floor(vim.o.columns * 0.75)
--					end,
--				},
--			},
--		},
--	},
--
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
}

vim.opt.rtp:prepend(lazypath)

require("lazy").setup(plugins, { silent = true })
