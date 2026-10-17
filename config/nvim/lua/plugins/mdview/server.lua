---@class mdview.server
local M = {}

local uv = vim.uv

---@alias mdview.Handler fun(path: string): integer, string, string, string|nil

---@class mdview.Server
---@field port integer
---@field close fun()

local STATUS = {
	[200] = "200 OK",
	[400] = "400 Bad Request",
	[403] = "403 Forbidden",
	[404] = "404 Not Found",
	[405] = "405 Method Not Allowed",
	[413] = "413 Payload Too Large",
	[500] = "500 Internal Server Error",
}
local MAX_HEAD = 8192
local IDLE_MS = 5000

---@param code integer
---@param ctype string
---@param body string
---@param extra? string
---@return string
local function response(code, ctype, body, extra)
	local head = {
		"HTTP/1.1 " .. STATUS[code],
		"Content-Type: " .. ctype,
		"Content-Length: " .. #body,
		"Cache-Control: no-store",
		"X-Content-Type-Options: nosniff",
	}
	if extra then
		head[#head + 1] = extra
	end
	head[#head + 1] = "Connection: close"
	return table.concat(head, "\r\n") .. "\r\n\r\n" .. body
end

---Start a server on an OS-chosen port.
---@param handler mdview.Handler
---@return mdview.Server
function M.start(handler)
	local server = assert(uv.new_tcp())
	assert(server:bind("127.0.0.1", 0))
	local port = assert(server:getsockname()).port

	local hosts = { ["127.0.0.1:" .. port] = true, ["localhost:" .. port] = true }

	---@type table<uv.uv_tcp_t, uv.uv_timer_t>  client -> idle timer
	local conns = {}

	local function finish(client)
		local timer = conns[client]
		if timer then
			conns[client] = nil
			timer:stop()
			timer:close()
		end
		if not client:is_closing() then
			client:close()
		end
	end

	local function reply(client, code, ctype, body, extra)
		client:write(response(code, ctype, body, extra), function()
			finish(client)
		end)
	end

	local function dispatch(client, head)
		local method, target = head:match("^(%u+) (%S+) HTTP/1%.%d")
		if not method then
			return reply(client, 400, "text/plain", "bad request")
		end
		local host = head:match("\r\n[Hh]ost: ([^\r\n]+)")
		if not hosts[host or ""] then
			return reply(client, 403, "text/plain", "forbidden")
		end
		if method ~= "GET" then
			return reply(client, 405, "text/plain", "method not allowed")
		end
		local ok, code, ctype, body, extra = pcall(handler, (target:match("^[^?]*")))
		if not ok then
			return reply(client, 500, "text/plain", "internal error")
		end
		reply(client, code, ctype, body, extra)
	end

	server:listen(32, function(err)
		if err then
			return
		end
		local client = uv.new_tcp()
		if not client then
			return
		end
		server:accept(client)

		local timer = assert(uv.new_timer())
		conns[client] = timer
		timer:start(IDLE_MS, 0, function()
			finish(client)
		end)

		local buf = ""
		client:read_start(function(rerr, chunk)
			if rerr or not chunk then
				return finish(client)
			end
			buf = buf .. chunk
			if #buf > MAX_HEAD then
				client:read_stop()
				return reply(client, 413, "text/plain", "too large")
			end
			-- Wait for the end of the headers. GET requests have no body we need.
			if buf:find("\r\n\r\n", 1, true) then
				client:read_stop()
				dispatch(client, buf)
			end
		end)
	end)

	return {
		port = port,
		close = function()
			if not server:is_closing() then
				server:close()
			end
			for client in pairs(conns) do
				finish(client)
			end
		end,
	}
end

return M
