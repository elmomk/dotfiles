-- session.lua — Read Claude Code session data to find which files were edited
-- Caches results to avoid repeatedly parsing large JSONL files.

local M = {}

local sessions_dir = vim.fn.expand("~/.claude/sessions")
local projects_dir = vim.fn.expand("~/.claude/projects")

-- Cache: { jsonl_path, mtime, files[] }
local cache = { jsonl_path = nil, mtime = 0, files = {} }

--- Find the active Claude Code session for a given directory
---@param cwd string
---@return { pid: number, sessionId: string, cwd: string }|nil
function M.find_active_session(cwd)
	local handle = vim.uv.fs_scandir(sessions_dir)
	if not handle then
		return nil
	end

	local best = nil

	while true do
		local name, typ = vim.uv.fs_scandir_next(handle)
		if not name then
			break
		end
		if typ == "file" and name:match("%.json$") then
			local path = sessions_dir .. "/" .. name
			local fd = vim.uv.fs_open(path, "r", 438)
			if fd then
				local stat = vim.uv.fs_stat(path)
				if stat then
					local data = vim.uv.fs_read(fd, stat.size, 0)
					vim.uv.fs_close(fd)
					if data then
						local ok, sess = pcall(vim.fn.json_decode, data)
						if ok and sess and sess.cwd == cwd and sess.pid then
							local rc = os.execute("kill -0 " .. sess.pid .. " 2>/dev/null")
							if rc == 0 then
								if not best or (sess.startedAt or 0) > (best.startedAt or 0) then
									best = sess
								end
							end
						end
					end
				else
					vim.uv.fs_close(fd)
				end
			end
		end
	end

	return best
end

--- Find the most recently modified JSONL for a cwd (scans project dirs)
---@param cwd string
---@return string|nil jsonl_path
function M.find_latest_jsonl(cwd)
	local handle = vim.uv.fs_scandir(projects_dir)
	if not handle then
		return nil
	end

	local best_path = nil
	local best_mtime = 0

	while true do
		local name, typ = vim.uv.fs_scandir_next(handle)
		if not name then
			break
		end
		if typ == "directory" then
			local dir_path = projects_dir .. "/" .. name
			local dir_handle = vim.uv.fs_scandir(dir_path)
			if dir_handle then
				while true do
					local fname, ftyp = vim.uv.fs_scandir_next(dir_handle)
					if not fname then
						break
					end
					if ftyp == "file" and fname:match("%.jsonl$") then
						local fpath = dir_path .. "/" .. fname
						local stat = vim.uv.fs_stat(fpath)
						if stat and stat.mtime.sec > best_mtime then
							-- Quick check first line for cwd match
							local fd = vim.uv.fs_open(fpath, "r", 438)
							if fd then
								local chunk = vim.uv.fs_read(fd, 4096, 0)
								vim.uv.fs_close(fd)
								if chunk then
									local line = chunk:match("^[^\n]+")
									if line and line:find(cwd, 1, true) then
										best_path = fpath
										best_mtime = stat.mtime.sec
									end
								end
							end
						end
					end
				end
			end
		end
	end

	return best_path
end

--- Parse JSONL for edited files (async via jobstart, non-blocking)
---@param jsonl_path string
---@param callback fun(files: string[])
function M.get_edited_files_async(jsonl_path, callback)
	local script = string.format([[
import json
seen = set()
with open(%q, "r") as f:
    for line in f:
        try:
            entry = json.loads(line)
        except:
            continue
        msg = entry.get("message", {})
        content = msg.get("content", [])
        if isinstance(content, list):
            for block in content:
                if isinstance(block, dict) and block.get("type") == "tool_use":
                    name = block.get("name", "")
                    inp = block.get("input", {})
                    if name in ("Write", "Edit") and "file_path" in inp:
                        fp = inp["file_path"]
                        if fp not in seen:
                            seen.add(fp)
                            print(fp)
]], jsonl_path)

	local output = {}

	vim.fn.jobstart({ "python3", "-c", script }, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			for _, line in ipairs(data) do
				if line ~= "" then
					table.insert(output, line)
				end
			end
		end,
		on_exit = function()
			callback(output)
		end,
	})
end

--- High-level async: get edited files, uses cache to skip re-parsing
---@param callback fun(files: string[])
---@param cwd string|nil
function M.get_claude_edited_files_async(callback, cwd)
	cwd = cwd or vim.fn.getcwd()

	local jsonl_path = M.find_latest_jsonl(cwd)
	if not jsonl_path then
		callback({})
		return
	end

	-- Check cache: if same file and same mtime, return cached result
	local stat = vim.uv.fs_stat(jsonl_path)
	if stat and jsonl_path == cache.jsonl_path and stat.mtime.sec == cache.mtime then
		callback(cache.files)
		return
	end

	-- Parse async
	M.get_edited_files_async(jsonl_path, function(files)
		cache.jsonl_path = jsonl_path
		cache.mtime = stat and stat.mtime.sec or 0
		cache.files = files
		callback(files)
	end)
end

--- Synchronous version (for initial load or when async isn't possible)
---@param cwd string|nil
---@return string[]
function M.get_claude_edited_files(cwd)
	cwd = cwd or vim.fn.getcwd()

	local jsonl_path = M.find_latest_jsonl(cwd)
	if not jsonl_path then
		return {}
	end

	local stat = vim.uv.fs_stat(jsonl_path)
	if stat and jsonl_path == cache.jsonl_path and stat.mtime.sec == cache.mtime then
		return cache.files
	end

	-- Fallback sync parse
	local script = string.format([[
import json
seen = set()
with open(%q, "r") as f:
    for line in f:
        try:
            entry = json.loads(line)
        except:
            continue
        msg = entry.get("message", {})
        content = msg.get("content", [])
        if isinstance(content, list):
            for block in content:
                if isinstance(block, dict) and block.get("type") == "tool_use":
                    name = block.get("name", "")
                    inp = block.get("input", {})
                    if name in ("Write", "Edit") and "file_path" in inp:
                        fp = inp["file_path"]
                        if fp not in seen:
                            seen.add(fp)
                            print(fp)
]], jsonl_path)

	local files = vim.fn.systemlist("python3 -c " .. vim.fn.shellescape(script) .. " 2>/dev/null")
	local result = {}
	for _, fp in ipairs(files) do
		if fp ~= "" then
			table.insert(result, fp)
		end
	end

	cache.jsonl_path = jsonl_path
	cache.mtime = stat and stat.mtime.sec or 0
	cache.files = result

	return result
end

return M
