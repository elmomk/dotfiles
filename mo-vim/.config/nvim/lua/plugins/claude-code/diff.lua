-- diff.lua — Inline diff highlighting for Claude Code changes
-- Shows added/changed/deleted lines directly in the buffer using extmarks.
-- No split windows. Toggle on/off with repeated calls.

local M = {}

local snapshots = require("plugins.claude-code.snapshots")

local ns = vim.api.nvim_create_namespace("claude_diff")

-- Track which buffers have active diffs (for toggle behavior)
local active_diffs = {}

-- Custom highlight groups (catppuccin mocha inspired)
local hl_defined = false
local function define_highlights()
	if hl_defined then return end
	hl_defined = true

	-- Added lines: green tint background
	vim.api.nvim_set_hl(0, "ClaudeDiffAdd", { bg = "#1a3a2a", fg = "#a6e3a1" })
	-- Changed lines: yellow tint background
	vim.api.nvim_set_hl(0, "ClaudeDiffChange", { bg = "#3a3520", fg = "#f9e2af" })
	-- Deleted lines: red tint background (virtual text)
	vim.api.nvim_set_hl(0, "ClaudeDiffDelete", { bg = "#3a1a1a", fg = "#f38ba8", strikethrough = true })
	-- Deleted line number indicator
	vim.api.nvim_set_hl(0, "ClaudeDiffDeleteNr", { fg = "#f38ba8" })
	-- Hunk separator
	vim.api.nvim_set_hl(0, "ClaudeDiffSep", { fg = "#585b70", italic = true })
end

--- Get the "before" lines for a file: snapshot first, git HEAD as fallback
---@param filepath string
---@return string[]|nil
local function get_before_lines(filepath)
	local snap = snapshots.get(filepath)
	if snap then
		return snap.lines
	end

	local cwd = vim.fn.getcwd()
	local relpath = filepath
	if filepath:sub(1, #cwd) == cwd then
		relpath = filepath:sub(#cwd + 2)
	end
	local lines = vim.fn.systemlist("git show HEAD:" .. vim.fn.shellescape(relpath) .. " 2>/dev/null")
	if vim.v.shell_error == 0 and #lines > 0 then
		return lines
	end

	return nil
end

--- Clear diff from a buffer
---@param bufnr number
local function clear(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	active_diffs[bufnr] = nil
end

--- Show inline diff for a file. Toggles off if already shown.
---@param filepath string|nil
function M.show(filepath)
	filepath = filepath or vim.api.nvim_buf_get_name(0)
	if filepath == "" then
		vim.notify("No file to diff", vim.log.levels.WARN)
		return
	end

	define_highlights()

	-- Open the file if not already in current buffer
	local bufnr = vim.api.nvim_get_current_buf()
	if vim.api.nvim_buf_get_name(bufnr) ~= filepath then
		vim.cmd("edit " .. vim.fn.fnameescape(filepath))
		bufnr = vim.api.nvim_get_current_buf()
	end

	-- Toggle: if diff is active on this buffer, clear it
	if active_diffs[bufnr] then
		clear(bufnr)
		return
	end

	local before_lines = get_before_lines(filepath)
	if not before_lines then
		vim.notify("No snapshot or git history for this file", vim.log.levels.WARN)
		return
	end

	local current_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local old_text = table.concat(before_lines, "\n") .. "\n"
	local new_text = table.concat(current_lines, "\n") .. "\n"

	local hunks = vim.diff(old_text, new_text, {
		result_type = "indices",
		algorithm = "histogram",
	})

	clear(bufnr)

	if not hunks or #hunks == 0 then
		vim.notify("No changes", vim.log.levels.INFO)
		return
	end

	local first_change = nil

	for _, hunk in ipairs(hunks) do
		local old_start, old_count, new_start, new_count = hunk[1], hunk[2], hunk[3], hunk[4]

		if old_count == 0 then
			-- Pure addition: highlight added lines green
			if not first_change then first_change = new_start end
			for line = new_start, new_start + new_count - 1 do
				pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, line - 1, 0, {
					line_hl_group = "ClaudeDiffAdd",
					sign_text = "+",
					sign_hl_group = "ClaudeDiffAdd",
				})
			end

		elseif new_count == 0 then
			-- Pure deletion: show deleted lines as virtual text
			if not first_change then first_change = math.max(1, new_start) end
			local virt_lines = {}
			for i = old_start, old_start + old_count - 1 do
				if before_lines[i] then
					table.insert(virt_lines, {
						{ "  - ", "ClaudeDiffDeleteNr" },
						{ before_lines[i], "ClaudeDiffDelete" },
					})
				end
			end
			if #virt_lines > 0 then
				local anchor = math.max(0, new_start - 1)
				pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, anchor, 0, {
					virt_lines = virt_lines,
					virt_lines_above = (new_start > 0),
				})
			end

		else
			-- Changed: highlight new version, show old as virtual text above
			if not first_change then first_change = new_start end

			-- Show what was removed
			local virt_lines = {}
			for i = old_start, old_start + old_count - 1 do
				if before_lines[i] then
					table.insert(virt_lines, {
						{ "  ~ ", "ClaudeDiffDeleteNr" },
						{ before_lines[i], "ClaudeDiffDelete" },
					})
				end
			end
			if #virt_lines > 0 then
				pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, new_start - 1, 0, {
					virt_lines = virt_lines,
					virt_lines_above = true,
				})
			end

			-- Highlight new lines
			for line = new_start, new_start + new_count - 1 do
				pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, line - 1, 0, {
					line_hl_group = "ClaudeDiffChange",
					sign_text = "~",
					sign_hl_group = "ClaudeDiffChange",
				})
			end
		end
	end

	active_diffs[bufnr] = true

	-- Jump to first change
	if first_change then
		pcall(vim.api.nvim_win_set_cursor, 0, { first_change, 0 })
		vim.cmd("normal! zz")
	end

	local cwd = vim.fn.getcwd()
	local relpath = filepath:sub(1, #cwd) == cwd and filepath:sub(#cwd + 2) or filepath
	vim.notify(
		" " .. relpath .. "  " .. #hunks .. " hunk(s)  press <leader>cd to dismiss",
		vim.log.levels.INFO
	)
end

--- Check if a buffer has an active diff
function M.is_active(bufnr)
	return active_diffs[bufnr or vim.api.nvim_get_current_buf()] == true
end

return M
