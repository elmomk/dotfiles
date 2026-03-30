-- watcher.lua — Watch for file changes Claude Code makes
-- Uses per-file fs_event watchers (instant, zero-cost when idle) for open buffers.
-- No directory scanning — relies on session.lua for discovering files not yet opened.

local M = {}

local snapshots = require("plugins.claude-code.snapshots")

local augroup = vim.api.nvim_create_augroup("ClaudeCodeWatcher", { clear = true })

-- filepath -> uv_fs_event_t
local file_watchers = {}

-- filepath -> true (files changed externally)
local changed_files = {}

-- Callbacks registered by other modules
local on_change_callbacks = {}

---@param cb fun(filepath: string, relpath: string)
function M.on_change(cb)
	table.insert(on_change_callbacks, cb)
end

function M.get_changed_files()
	return changed_files
end

function M.is_changed(filepath)
	return changed_files[filepath] == true
end

function M.acknowledge(filepath)
	changed_files[filepath] = nil
end

function M.accept(filepath)
	snapshots.take(filepath)
	changed_files[filepath] = nil
end

function M.accept_all()
	for filepath in pairs(changed_files) do
		snapshots.take(filepath)
	end
	changed_files = {}
end

--- Mark a file as changed (called by session module for files not open in nvim)
function M.mark_changed(filepath)
	if changed_files[filepath] then
		return
	end

	local cwd = vim.fn.getcwd()
	local relpath = filepath
	if filepath:sub(1, #cwd) == cwd then
		relpath = filepath:sub(#cwd + 2)
	end

	changed_files[filepath] = true

	for _, cb in ipairs(on_change_callbacks) do
		pcall(cb, filepath, relpath)
	end
end

local function should_ignore(path)
	return path:match("/%.git/")
		or path:match("/node_modules/")
		or path:match("/target/")
		or path:match("%.swp$")
		or path:match("~$")
end

--- Start an fs_event watcher on a specific file (instant notification, zero polling)
local function watch_file(filepath)
	if file_watchers[filepath] or should_ignore(filepath) then
		return
	end

	local handle = vim.uv.new_fs_event()
	if not handle then
		return
	end

	handle:start(filepath, {}, vim.schedule_wrap(function(err, _, events)
		if err or not events or not events.change then
			return
		end

		local snap = snapshots.get(filepath)
		if not snap then
			return
		end

		local stat = vim.uv.fs_stat(filepath)
		if not stat or stat.mtime.sec == snap.mtime then
			return
		end

		-- Read and compare content
		local fd = vim.uv.fs_open(filepath, "r", 438)
		if not fd then
			return
		end
		local data = vim.uv.fs_read(fd, stat.size, 0)
		vim.uv.fs_close(fd)

		if not data then
			return
		end

		local old_text = table.concat(snap.lines, "\n")
		if data ~= old_text .. "\n" and data ~= old_text then
			M.mark_changed(filepath)

			-- Reload buffer if open
			for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_loaded(bufnr)
					and vim.api.nvim_buf_get_name(bufnr) == filepath then
					vim.api.nvim_buf_call(bufnr, function()
						vim.cmd("checktime")
					end)
					break
				end
			end
		end
	end))

	file_watchers[filepath] = handle
end

local function unwatch_file(filepath)
	if file_watchers[filepath] then
		file_watchers[filepath]:stop()
		file_watchers[filepath]:close()
		file_watchers[filepath] = nil
	end
end

function M.setup()
	vim.o.autoread = true

	-- Snapshot + watch on buffer open
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		group = augroup,
		callback = function(args)
			if vim.bo[args.buf].buftype ~= "" then
				return
			end
			local filepath = vim.api.nvim_buf_get_name(args.buf)
			if filepath == "" then
				return
			end
			if not snapshots.has(filepath) then
				snapshots.take(filepath)
			end
			watch_file(filepath)
		end,
	})

	-- Check for external changes on focus/cursor events
	vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
		group = augroup,
		callback = function()
			if vim.fn.getcmdwintype() == "" then
				vim.cmd("checktime")
			end
		end,
	})

	-- Belt-and-suspenders: catch anything FileChangedShellPost picks up
	vim.api.nvim_create_autocmd("FileChangedShellPost", {
		group = augroup,
		callback = function(args)
			local filepath = vim.api.nvim_buf_get_name(args.buf)
			if filepath ~= "" and snapshots.has(filepath) then
				M.mark_changed(filepath)
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		group = augroup,
		callback = function(args)
			local filepath = vim.api.nvim_buf_get_name(args.buf)
			if filepath ~= "" then
				unwatch_file(filepath)
			end
		end,
	})
end

function M.teardown()
	for filepath in pairs(file_watchers) do
		unwatch_file(filepath)
	end
	changed_files = {}
end

return M
