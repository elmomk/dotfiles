-- claude-code.nvim — See what Claude Code is changing in real time
-- <leader>cs  sidebar    <leader>cd  diff    <leader>cr  resume session

local watcher = require("plugins.claude-code.watcher")
local sidebar = require("plugins.claude-code.sidebar")
local diff = require("plugins.claude-code.diff")

local M = {}

function M.setup()
	watcher.setup()
	sidebar.setup()

	vim.api.nvim_create_user_command("ClaudeSidebar", sidebar.toggle, {})
	vim.api.nvim_create_user_command("ClaudeDiff", function() diff.show() end, {})
end

M.watcher = watcher
M.sidebar = sidebar
M.diff = diff

return M
