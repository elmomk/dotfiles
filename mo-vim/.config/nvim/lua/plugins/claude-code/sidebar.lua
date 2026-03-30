-- sidebar.lua — Minimal sidebar showing files Claude Code has touched

local M = {}

local snapshots = require("plugins.claude-code.snapshots")
local watcher = require("plugins.claude-code.watcher")
local session = require("plugins.claude-code.session")

local sidebar_buf = nil
local sidebar_win = nil
local WIDTH = 36

local displayed_files = {}
local ns = vim.api.nvim_create_namespace("claude_sidebar")

-- Highlight groups (set once on first open)
local hl_defined = false
local function define_highlights()
	if hl_defined then return end
	hl_defined = true

	-- Catppuccin mocha palette
	vim.api.nvim_set_hl(0, "ClaudeHeader",    { fg = "#cba6f7", bold = true })           -- mauve
	vim.api.nvim_set_hl(0, "ClaudeActive",    { fg = "#a6e3a1" })                        -- green
	vim.api.nvim_set_hl(0, "ClaudeInactive",  { fg = "#6c7086", italic = true })          -- overlay0
	vim.api.nvim_set_hl(0, "ClaudeCount",     { fg = "#89b4fa" })                        -- blue
	vim.api.nvim_set_hl(0, "ClaudeSep",       { fg = "#313244" })                        -- surface0
	vim.api.nvim_set_hl(0, "ClaudeLive",      { fg = "#f9e2af" })                        -- yellow
	vim.api.nvim_set_hl(0, "ClaudeSession",   { fg = "#89b4fa" })                        -- blue
	vim.api.nvim_set_hl(0, "ClaudeDir",       { fg = "#6c7086" })                        -- overlay0
	vim.api.nvim_set_hl(0, "ClaudeFile",      { fg = "#cdd6f4" })                        -- text
	vim.api.nvim_set_hl(0, "ClaudeHelp",      { fg = "#585b70" })                        -- surface2
end

local function is_open()
	return sidebar_win and vim.api.nvim_win_is_valid(sidebar_win)
		and sidebar_buf and vim.api.nvim_buf_is_valid(sidebar_buf)
end

--- Collect changed files from watcher + session
local function collect_files(session_files)
	local cwd = vim.fn.getcwd()
	local files = {}
	local seen = {}

	for filepath in pairs(watcher.get_changed_files()) do
		seen[filepath] = true
		local rel = filepath:sub(1, #cwd) == cwd and filepath:sub(#cwd + 2) or filepath
		table.insert(files, { abs = filepath, rel = rel, live = true })
	end

	for _, filepath in ipairs(session_files or {}) do
		if not seen[filepath] then
			local rel = filepath:sub(1, #cwd) == cwd and filepath:sub(#cwd + 2) or filepath
			table.insert(files, { abs = filepath, rel = rel, live = false })
		end
	end

	table.sort(files, function(a, b) return a.rel < b.rel end)
	return files
end

--- Split path into directory and filename
local function split_path(rel)
	local dir, name = rel:match("^(.+/)([^/]+)$")
	if not dir then
		return "", rel
	end
	return dir, name
end

local function do_render(session_files)
	if not is_open() then return end

	displayed_files = collect_files(session_files)

	local lines = {}
	local hls = {} -- { line, group, col_start?, col_end? }

	-- Header
	lines[1] = "  Claude Code"
	hls[#hls + 1] = { 0, "ClaudeHeader" }

	-- Status
	local cwd = vim.fn.getcwd()
	local active = session.find_active_session(cwd)
	if active then
		lines[2] = "  pid " .. active.pid
		hls[#hls + 1] = { 1, "ClaudeActive" }
	else
		lines[2] = "  no session"
		hls[#hls + 1] = { 1, "ClaudeInactive" }
	end

	-- Separator
	lines[3] = string.rep("─", WIDTH)
	hls[#hls + 1] = { 2, "ClaudeSep" }

	-- File list
	if #displayed_files == 0 then
		lines[4] = ""
		lines[5] = "  Waiting for changes..."
		hls[#hls + 1] = { 4, "ClaudeInactive" }
	else
		local header_n = #lines
		for i, file in ipairs(displayed_files) do
			local indicator = file.live and "  " or "  "
			local dir, name = split_path(file.rel)

			local line = indicator .. dir .. name
			-- Truncate if too long
			if #line > WIDTH then
				local avail = WIDTH - #indicator - #name - 2
				if avail > 3 then
					dir = "…" .. dir:sub(-(avail - 1))
				else
					dir = ""
				end
				line = indicator .. dir .. name
			end

			table.insert(lines, line)

			local ln = header_n + i - 1
			-- Indicator color
			hls[#hls + 1] = { ln, file.live and "ClaudeLive" or "ClaudeSession", 0, #indicator }
			-- Directory color
			if dir ~= "" then
				hls[#hls + 1] = { ln, "ClaudeDir", #indicator, #indicator + #dir }
			end
			-- Filename color
			hls[#hls + 1] = { ln, "ClaudeFile", #indicator + #dir, -1 }
		end
	end

	-- Footer
	table.insert(lines, "")
	table.insert(lines, string.rep("─", WIDTH))
	hls[#hls + 1] = { #lines - 1, "ClaudeSep" }

	local count_line = "  " .. #displayed_files .. " files"
	table.insert(lines, count_line)
	hls[#hls + 1] = { #lines - 1, "ClaudeCount" }

	table.insert(lines, "  cr d  r   q")
	hls[#hls + 1] = { #lines - 1, "ClaudeHelp" }

	-- Write to buffer
	vim.bo[sidebar_buf].modifiable = true
	vim.api.nvim_buf_set_lines(sidebar_buf, 0, -1, false, lines)
	vim.bo[sidebar_buf].modifiable = false

	-- Apply highlights
	vim.api.nvim_buf_clear_namespace(sidebar_buf, ns, 0, -1)
	for _, h in ipairs(hls) do
		pcall(vim.api.nvim_buf_add_highlight, sidebar_buf, ns, h[2], h[1], h[3] or 0, h[4] or -1)
	end
end

function M.render()
	if not is_open() then return end

	session.get_claude_edited_files_async(function(files)
		vim.schedule(function()
			do_render(files)
		end)
	end)
end

local function file_at_cursor()
	if not is_open() then return nil end
	local row = vim.api.nvim_win_get_cursor(sidebar_win)[1]
	local idx = row - 3  -- 3 header lines (title, status, separator)
	if idx >= 1 and idx <= #displayed_files then
		return displayed_files[idx]
	end
	return nil
end

function M.open()
	if is_open() then
		M.render()
		return
	end

	define_highlights()

	sidebar_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[sidebar_buf].buftype = "nofile"
	vim.bo[sidebar_buf].bufhidden = "wipe"
	vim.bo[sidebar_buf].swapfile = false
	vim.bo[sidebar_buf].filetype = "claude-sidebar"

	vim.cmd("topleft vsplit")
	sidebar_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(sidebar_win, sidebar_buf)
	vim.api.nvim_win_set_width(sidebar_win, WIDTH)

	local wo = vim.wo[sidebar_win]
	wo.number = false
	wo.relativenumber = false
	wo.signcolumn = "no"
	wo.cursorcolumn = false
	wo.foldcolumn = "0"
	wo.wrap = false
	wo.winfixwidth = true
	wo.cursorline = true
	wo.statusline = " "

	local opts = { buffer = sidebar_buf, nowait = true, silent = true }

	-- Enter or d: open file with inline diff in the main window
	local function open_with_diff()
		local f = file_at_cursor()
		if f then
			vim.cmd("wincmd p")
			vim.cmd("edit " .. vim.fn.fnameescape(f.abs))
			require("plugins.claude-code.diff").show(f.abs)
		end
	end

	vim.keymap.set("n", "<CR>", open_with_diff, opts)
	vim.keymap.set("n", "d", open_with_diff, opts)

	vim.keymap.set("n", "r", function() M.render() end, opts)
	vim.keymap.set("n", "q", function() M.close() end, opts)

	M.render()
	vim.cmd("wincmd p")
end

function M.close()
	if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
		vim.api.nvim_win_close(sidebar_win, true)
	end
	sidebar_win = nil
	sidebar_buf = nil
end

function M.toggle()
	if is_open() then M.close() else M.open() end
end

function M.setup()
	watcher.on_change(function(_, relpath)
		vim.notify("  " .. relpath, vim.log.levels.INFO, { title = "Claude" })
		if is_open() then M.render() end
	end)
end

return M
