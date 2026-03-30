local servers = {
	"lua_ls",
	-- "cssls",
	-- "html",
	-- "tsserver",
	-- "pyright",
	"helm_ls",
	"bashls",
	"jsonls",
	"yamlls",
	"terraformls",
	"tflint",
	"marksman",
	"gopls",
	-- "staticcheck",
	"rust_analyzer",
	-- "awk_ls",
	"ansiblels",
	"dockerls",
	"golangci_lint_ls",
	-- "remark_ls",
	"zk", -- markdown
	-- "jedi_language_server", -- python
	-- "pyre", -- python
	-- "sourcery", -- python
	-- "pylsp", -- python
	"ruff", -- python
	-- "ruby_ls", -- ruby
	-- "solargraph", -- ruby
	-- "taplo", -- toml
	-- "snyk_ls",
}

local settings = {
	ui = {
		border = "none",
		icons = {
			package_installed = "✓",
			package_pending = "➜",
			package_uninstalled = "✗",
		},
	},
	log_level = vim.log.levels.INFO,
	max_concurrent_installers = 4,
}

require("mason").setup(settings)
require("mason-lspconfig").setup({
	ensure_installed = servers,
	automatic_installation = true,
})

-- Configure each server using vim.lsp.config (Neovim 0.11+)
local handlers = require("plugins.lsp.handlers")

for _, server in pairs(servers) do
	local opts = {
		on_attach = handlers.on_attach,
		capabilities = handlers.capabilities,
	}

	server = vim.split(server, "@")[1]

	local require_ok, conf_opts = pcall(require, "plugins.lsp.settings." .. server)
	if require_ok then
		opts = vim.tbl_deep_extend("force", conf_opts, opts)
	end

	vim.lsp.config(server, opts)
end

vim.lsp.enable(servers)
