-- snapshots.lua — Track file contents as nvim sees them
-- When a buffer loads, we snapshot its content. When Claude changes the file
-- externally, we can diff the new content against the snapshot.

local M = {}

-- filepath -> { lines = string[], mtime = number }
local store = {}

--- Snapshot a file's current content from disk
---@param filepath string absolute path
function M.take(filepath)
	local stat = vim.uv.fs_stat(filepath)
	if not stat then
		return
	end

	local fd = vim.uv.fs_open(filepath, "r", 438)
	if not fd then
		return
	end
	local data = vim.uv.fs_read(fd, stat.size, 0)
	vim.uv.fs_close(fd)

	if data then
		store[filepath] = {
			lines = vim.split(data, "\n", { plain = true }),
			mtime = stat.mtime.sec,
		}
	end
end

--- Get the snapshot for a file (nil if none)
---@param filepath string
---@return { lines: string[], mtime: number }|nil
function M.get(filepath)
	return store[filepath]
end

--- Check if a file has a snapshot
---@param filepath string
---@return boolean
function M.has(filepath)
	return store[filepath] ~= nil
end

--- Remove snapshot for a file
---@param filepath string
function M.remove(filepath)
	store[filepath] = nil
end

--- Get all tracked file paths
---@return string[]
function M.tracked_files()
	local files = {}
	for fp in pairs(store) do
		table.insert(files, fp)
	end
	return files
end

--- Clear all snapshots
function M.clear()
	store = {}
end

return M
