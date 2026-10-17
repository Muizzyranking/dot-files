--- One preview session at a time. Owns the state, the render debounce, the autocmds,
--- and the lifecycles of the server and the browser window.
--- Required only when a preview starts.
---@class mdview.session
local M = {}

local config = require("plugins.mdview.config")
local util = require("plugins.mdview.util")
local render = require("plugins.mdview.render")
local images = require("plugins.mdview.images")
local server = require("plugins.mdview.server")
local browser = require("plugins.mdview.browser")

local uv = vim.uv

---@class mdview.Session
---@field buf integer             buffer currently previewed (follows BufEnter)
---@field file_dir string         directory of that buffer's file
---@field root string             image root, lexical; relative image paths resolve here
---@field root_real string        image root after symlinks; used for the containment check
---@field version integer         bumped on every successful render
---@field gen integer             bumped on every render request; drops stale results
---@field html string             last rendered body
---@field state string            JSON for /state: { version, line, total }
---@field line integer            cursor line in the previewed buffer
---@field total integer           line count of the previewed buffer
---@field page string             viewer page (assets/page.html)
---@field css string              stylesheet (assets/markdown.css)
---@field timer uv.uv_timer_t     debounce timer for renders
---@field pending? vim.SystemObj  render process in flight
---@field server? mdview.Server
---@field browser? vim.SystemObj  the Chrome app window
---@field group? integer          augroup holding this session's autocmds

---@type mdview.Session|nil
local S = nil

---Kill a process if it is still running. Ignores "already exited" errors.
---@param proc? vim.SystemObj
local function kill(proc)
	if proc then
		pcall(function()
			proc:kill(15)
		end)
	end
end

---Recompute the small JSON that the page polls. Built on the main thread so the server
---only has to send bytes.
---@param s mdview.Session
local function publish(s)
	s.state = vim.json.encode({ version = s.version, line = s.line, total = s.total })
end

---Map an HTTP path to a response. Runs inside a libuv callback: no vim.api calls here.
---@param s mdview.Session
---@return mdview.Handler
local function make_handler(s)
	return function(path)
		if path == "/" or path == "/index.html" then
			return 200, "text/html; charset=utf-8", s.page
		elseif path == "/state" then
			return 200, "application/json", s.state
		elseif path == "/body" then
			return 200, "text/html; charset=utf-8", s.html
		elseif path == "/markdown.css" then
			return 200, "text/css; charset=utf-8", s.css
		elseif path:sub(1, 5) == "/src/" then
			return images.serve(s.root, s.root_real, path, config.options.max_image_bytes)
		end
		return 404, "text/plain", "not found"
	end
end

---Work out the image root for a buffer: the user's option, or the file's directory.
---@param buf integer
---@return string
local function resolve_root(buf)
	local r = config.options.image_root
	if type(r) == "function" then
		r = r(buf)
	end
	if r == nil or r == "" then
		r = util.buf_dir(buf)
	end
	local root = vim.fs.normalize(vim.fn.fnamemodify(r, ":p"))
	return (root:gsub("/+$", ""))
end

---@param s mdview.Session
local function render_now(s)
	if S ~= s or not vim.api.nvim_buf_is_valid(s.buf) or not util.is_markdown(s.buf) then
		return
	end
	kill(s.pending)
	s.pending = nil

	s.gen = s.gen + 1
	local gen = s.gen
	local text = table.concat(vim.api.nvim_buf_get_lines(s.buf, 0, -1, false), "\n")

	s.pending = render.markdown(text, { file_dir = s.file_dir, root = s.root }, function(html, err)
		-- Drop the result if the session stopped or a newer render has started.
		if S ~= s or s.gen ~= gen then
			return
		end
		s.pending = nil
		if not html then
			util.notify.warn("render failed: " .. (err or "unknown error"))
			return
		end
		s.version = s.version + 1
		s.html = html
		publish(s)
	end)
end

---Debounce: restart the timer on every edit, and render once typing pauses.
---@param s mdview.Session
local function schedule_render(s)
	s.timer:stop()
	s.timer:start(
		config.options.render_debounce,
		0,
		vim.schedule_wrap(function()
			render_now(s)
		end)
	)
end

---Update the cursor position. Publishes only when something changed.
---@param s mdview.Session
local function update_pos(s)
	if vim.api.nvim_get_current_buf() ~= s.buf then
		return
	end
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local total = vim.api.nvim_buf_line_count(s.buf)
	if line == s.line and total == s.total then
		return
	end
	s.line, s.total = line, total
	publish(s)
end

---Point the session at another buffer and render it.
---@param s mdview.Session
---@param buf integer
local function retarget(s, buf)
	s.buf = buf
	s.file_dir = util.buf_dir(buf)
	s.root = resolve_root(buf)
	s.root_real = uv.fs_realpath(s.root) or s.root
	render_now(s)
	update_pos(s)
end

---Autocmds that exist only while a session is active. They are removed on stop.
---@param s mdview.Session
local function attach_autocmds(s)
	s.group = vim.api.nvim_create_augroup("MdViewSession", { clear = true })
	local group = s.group

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost" }, {
		group = group,
		callback = function(ev)
			if S and ev.buf == S.buf and util.is_markdown(ev.buf) then
				schedule_render(S)
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		group = group,
		callback = function()
			if S and vim.api.nvim_get_current_buf() == S.buf then
				update_pos(S)
			end
		end,
	})

	-- Switching to another markdown file re-targets the preview.
	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		callback = function(ev)
			if S and ev.buf ~= S.buf and util.is_markdown(ev.buf) and util.buf_path(ev.buf) ~= "" then
				retarget(S, ev.buf)
			end
		end,
	})

	-- Wiping or deleting the previewed buffer ends the session.
	vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
		group = group,
		callback = function(ev)
			if S and ev.buf == S.buf then
				M.stop()
			end
		end,
	})

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			M.stop()
		end,
	})
end

function M.start()
	if not config.is_enabled() then
		return
	end
	local buf = vim.api.nvim_get_current_buf()
	if not util.is_markdown(buf) then
		return util.notify.warn("not a markdown buffer")
	end
	if util.buf_path(buf) == "" then
		return util.notify.warn("save the buffer to a file first")
	end
	if S then
		return retarget(S, buf)
	end
	if vim.fn.executable("cmark-gfm") == 0 then
		return util.notify.error("cmark-gfm not found on PATH")
	end

	local page = util.read_file(util.assets .. "/page.html")
	if not page then
		return util.notify.error("missing " .. util.assets .. "/page.html")
	end
	local css = util.read_file(util.assets .. "/markdown.css") or ""

	-- Remove Chrome profiles left behind by Neovim processes that have exited.
	browser.cleanup_stale()

	---@type mdview.Session
	local s = {
		buf = buf,
		file_dir = util.buf_dir(buf),
		root = "",
		root_real = "",
		version = 0,
		gen = 0,
		html = "",
		state = "",
		line = 0,
		total = 1,
		page = page,
		css = css,
		timer = assert(uv.new_timer()),
	}

	local ok, srv = pcall(server.start, make_handler(s))
	if not ok then
		s.timer:close()
		return util.notify.error("failed to start server: " .. tostring(srv))
	end
	s.server = srv
	S = s

	publish(s)
	attach_autocmds(s)
	retarget(s, buf)

	-- The window gets its own profile, so the process we spawn is the window itself.
	local url = ("http://127.0.0.1:%d/index.html"):format(srv.port)
	local profile = ("%s/profiles/%d-%d"):format(util.cache_dir(), vim.fn.getpid(), srv.port)
	s.browser = browser.open(url, profile, function()
		if S == s then
			M.stop()
		end
	end)
end

---Stop the session: timer, render, autocmds, server, and window. Safe to call repeatedly.
function M.stop()
	local s = S
	if not s then
		return
	end
	S = nil
	s.timer:stop()
	s.timer:close()
	kill(s.pending)
	if s.group then
		pcall(vim.api.nvim_del_augroup_by_id, s.group)
	end
	if s.server then
		s.server.close()
	end
	kill(s.browser)
end

---@param buf? integer
---@return boolean
function M.is_active(buf)
	if not S then
		return false
	end
	return buf == nil or S.buf == buf
end

---Stop if the current buffer is the one being previewed, otherwise start or re-target.
function M.toggle()
	local buf = vim.api.nvim_get_current_buf()
	if M.is_active(buf) then
		M.stop()
	else
		M.start()
	end
end

---Details about the running preview, or nil when none is running.
---@return { buf: integer, port: integer, url: string }|nil
function M.status()
	if not S or not S.server then
		return nil
	end
	local port = S.server.port
	return {
		buf = S.buf,
		port = port,
		url = ("http://127.0.0.1:%d/index.html"):format(port),
	}
end

return M
