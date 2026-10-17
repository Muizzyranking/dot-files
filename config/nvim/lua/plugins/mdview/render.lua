---@class mdview.render
local M = {}

---@class mdview.RenderCtx
---@field file_dir string
---@field root string

-- cmark-gfm flags:
--   --unsafe     keep raw HTML from the markdown. The page is local and the content is yours.
--   --sourcepos  add data-sourcepos="line:col-line:col" so the page can sync the scroll.
--   -e ...       GitHub-flavoured extensions.
local CMARK = {
	"cmark-gfm",
	"--unsafe",
	"--sourcepos",
	"-e",
	"table",
	"-e",
	"strikethrough",
	"-e",
	"autolink",
	"-e",
	"tasklist",
}

---Undo percent-encoding, e.g. "my%20image.png" becomes "my image.png".
---@param s string
---@return string
local function unescape(s)
	return (s:gsub("%%(%x%x)", function(h)
		return string.char(tonumber(h, 16))
	end))
end

---Percent-encode a relative path for a URL. Keeps "/" as the separator.
---@param s string
---@return string
local function escape_path(s)
	return (s:gsub("[^%w/%-%._~]", function(c)
		return ("%%%02X"):format(c:byte())
	end))
end

---@param raw string
---@param ctx mdview.RenderCtx
---@return string|nil
local function local_url(raw, ctx)
	raw = (raw:gsub("&amp;", "&"))
	if raw == "" or raw:match("^%a[%w+.-]*:") or raw:match("^[/#]") then
		return nil
	end
	local path = unescape((raw:gsub("[?#].*$", "")))
	local abs = vim.fs.normalize(ctx.file_dir .. "/" .. path)
	local rel = vim.fs.relpath(ctx.root, abs)
	if not rel then
		return nil
	end
	return "/src/" .. escape_path(rel)
end

---@param html string
---@param ctx mdview.RenderCtx
---@return string
local function rewrite(html, ctx)
	local function map(v)
		return local_url(v, ctx)
	end

	html = html:gsub('(%ssrc=")([^"]*)"', function(pre, v)
		local u = map(v)
		return u and (pre .. u .. '"') or nil
	end)
	html = html:gsub("(%ssrc=')([^']*)'", function(pre, v)
		local u = map(v)
		return u and (pre .. u .. "'") or nil
	end)

	-- srcset is a list of "url descriptor" candidates separated by commas.
	html = html:gsub('(%ssrcset=")([^"]*)"', function(pre, v)
		local parts = {}
		for cand in v:gmatch("[^,]+") do
			local lead, url, rest = cand:match("^(%s*)(%S+)(.*)$")
			if url then
				parts[#parts + 1] = lead .. (map(url) or url) .. rest
			end
		end
		return pre .. table.concat(parts, ",") .. '"'
	end)

	return html
end

---@return boolean
function M.available()
	return vim.fn.executable("cmark-gfm") == 1
end

---@param text string
---@param ctx mdview.RenderCtx
---@param cb fun(html: string|nil, err: string|nil)
---@return vim.SystemObj
function M.markdown(text, ctx, cb)
	return vim.system(
		CMARK,
		{ stdin = text, text = true },
		vim.schedule_wrap(function(res)
			if res.code ~= 0 then
				return cb(nil, res.stderr)
			end
			cb(rewrite(res.stdout or "", ctx))
		end)
	)
end

return M
