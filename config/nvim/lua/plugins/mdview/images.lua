---@class mdview.images
local M = {}

local uv = vim.uv

local MIME = {
	png = "image/png",
	jpg = "image/jpeg",
	jpeg = "image/jpeg",
	gif = "image/gif",
	webp = "image/webp",
	avif = "image/avif",
	bmp = "image/bmp",
	svg = "image/svg+xml",
}

local CSP = "Content-Security-Policy: sandbox"

---@return integer, string, string, string|nil
local function not_found()
	return 404, "text/plain", "not found", nil
end

---@param path string
---@return string|nil
local function safe_rel(path)
	local segs = {}
	for seg in path:sub(6):gmatch("[^/]+") do
		seg = seg:gsub("%%(%x%x)", function(h)
			return string.char(tonumber(h, 16))
		end)
		if seg == "." or seg == ".." or seg:find("/", 1, true) or seg:find("\0", 1, true) then
			return nil
		end
		segs[#segs + 1] = seg
	end
	if #segs == 0 then
		return nil
	end
	return table.concat(segs, "/")
end

---@param root string
---@param root_real string
---@param path string
---@param max_bytes integer
---@return integer code, string ctype, string body, string|nil extra
function M.serve(root, root_real, path, max_bytes)
	local rel = safe_rel(path)
	local ctype = rel and MIME[(rel:match("%.(%w+)$") or ""):lower()]
	if not rel or not ctype then
		return not_found()
	end

	local real = uv.fs_realpath(root .. "/" .. rel)
	if not real or real:sub(1, #root_real + 1) ~= root_real .. "/" then
		return not_found()
	end

	local st = uv.fs_stat(real)
	if not st or st.type ~= "file" or st.size > max_bytes then
		return not_found()
	end

	local f = io.open(real, "rb")
	if not f then
		return not_found()
	end
	local data = f:read("*a")
	f:close()
	return 200, ctype, data, CSP
end

return M
