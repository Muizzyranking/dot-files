--- @class LazyEventModule
local M = {}

---------------------------------------------------------------
--- Setup a custom event for lazy loading
---@param event_name string Name of the custom event
---@param check_condition? function Optional condition to check before triggering the event
---------------------------------------------------------------
local function setup_event(event_name, check_condition)
  local Event = require("lazy.core.handler.event")

  -- Map the event so 'lazy.nvim' recognizes it
  Event.mappings[event_name] = { id = event_name, event = "User", pattern = event_name }
  Event.mappings["User " .. event_name] = Event.mappings[event_name]

  --- @type {event: string, buf: number, data?: any}[]
  local events = {}
  local done = false

  local function load()
    if #events == 0 or done then
      return
    end
    done = true

    -- Clean up existing autogroup
    vim.api.nvim_del_augroup_by_name("lazy_" .. event_name)

    --- @type table<string,string[]>
    local skips = {}
    for _, event in ipairs(events) do
      skips[event.event] = skips[event.event] or Event.get_augroups(event.event)
    end

    -- Trigger the custom event
    vim.api.nvim_exec_autocmds("User", { pattern = event_name, modeline = false })

    for _, event in ipairs(events) do
      if vim.api.nvim_buf_is_valid(event.buf) then
        Event.trigger({
          event = event.event,
          exclude = skips[event.event],
          data = event.data,
          buf = event.buf,
        })
        if vim.bo[event.buf].filetype then
          Event.trigger({
            event = "FileType",
            buf = event.buf,
          })
        end
      end
    end

    vim.api.nvim_exec_autocmds("CursorMoved", { modeline = false })
    events = {}
  end

  -- schedule wrap so that nested autocmds are executed
  -- and the UI can continue rendering without blocking
  load = vim.schedule_wrap(load)

  -- Set up the autocmds that fire the custom event
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufWritePre" }, {
    group = vim.api.nvim_create_augroup("lazy_" .. event_name, { clear = true }),
    callback = function(event)
      if not check_condition or check_condition() then
        table.insert(events, event)
        load()
      end
    end,
  })
end

---------------------------------------------------------------
--- Setup the custom LazyFile event
---------------------------------------------------------------
function M.setup_lazyfile()
  setup_event("LazyFile")
end

---------------------------------------------------------------
--- Setup the custom InGitRepo event
---------------------------------------------------------------
function M.setup_ingitrepo()
  setup_event("InGitRepo", Utils.is_in_git_repo)
end

return M
