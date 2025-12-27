local M = {}

local uv = vim.uv or vim.loop

-- CONSTANTS
local NS_PER_MS = 1e6
local ERROR_TITLE = "Profiler Error"

-- DATA STORAGE
-- We use local variables for speed (upvalues)
local registry = {} -- Stores accumulated data: registry[name] = { total_ns, self_ns, count }

-- STACK STATE (Parallel Arrays for optimization)
-- Instead of allocating table objects for every frame, we reuse these arrays.
local stack_names = {} -- [depth] -> string
local stack_start = {} -- [depth] -> number/cdata (timestamp)
local stack_deduction = {} -- [depth] -> number/cdata (accumulated child time)
local depth = 0 -- Current stack depth

-- SESSION STATE
local session_start_time = nil

--- Resets the profiler state.
function M.reset()
  registry = {}
  -- We don't need to clear the stack arrays, just resetting depth is enough
  -- to "invalidate" them effectively for the next run.
  depth = 0
  session_start_time = nil
  print("Profiler: State reset.")
end

--- Start a profiling section.
-- @param name string
function M.start(name)
  -- Capture time immediately to minimize overhead drift
  local now = uv.hrtime()

  if depth == 0 and not session_start_time then session_start_time = now end

  -- Increment stack depth
  depth = depth + 1

  -- Push state to parallel arrays
  stack_names[depth] = name
  stack_start[depth] = now
  -- Reset deduction for this new frame (no children have run yet)
  stack_deduction[depth] = 0
end

--- Stop the current profiling section.
-- @param name string
function M.stop(name)
  -- Capture time immediately
  local now = uv.hrtime()

  -- Safety Checks
  if depth == 0 then
    vim.notify("Profiler Error: Stack empty on stop('" .. name .. "')", vim.log.levels.ERROR, { title = ERROR_TITLE })
    return
  end

  if stack_names[depth] ~= name then
    vim.notify(
      string.format("Profiler Error: Mismatch. Expected '%s', got '%s'", stack_names[depth], name),
      vim.log.levels.ERROR,
      { title = ERROR_TITLE }
    )
    return
  end

  -- RETRIEVE STATE
  local start_t = stack_start[depth]
  local child_deduction = stack_deduction[depth]

  -- CALCULATE METRICS
  -- LuaJIT handles uint64_t (cdata) subtraction efficiently
  local total_ns = now - start_t
  local self_ns = total_ns - child_deduction

  -- STORE DATA
  -- Retrieve or initialize registry entry
  local entry = registry[name]
  if not entry then
    entry = { total = 0, self = 0, count = 0 }
    registry[name] = entry
  end

  entry.total = entry.total + total_ns
  entry.self = entry.self + self_ns
  entry.count = entry.count + 1

  -- POP STACK
  depth = depth - 1

  -- PROPAGATE OVERHEAD TO PARENT
  -- If there is a parent, add THIS section's total time to the parent's deduction accumulator.
  -- This ensures the parent's "Self Time" calculation excludes this child's execution.
  if depth > 0 then stack_deduction[depth] = stack_deduction[depth] + total_ns end
end

--- Generate a report.
function M.report()
  if depth > 0 then
    vim.notify(
      "Profiler Error: Cannot generate report, sections still open: " .. stack_names[depth],
      vim.log.levels.WARN
    )
    return
  end

  if not session_start_time then
    print("Profiler: No data collected.")
    return
  end

  local end_time = uv.hrtime()
  local total_session_ns = end_time - session_start_time

  -- Convert registry to list for sorting
  local report_lines = {}
  local results = {}

  for name, stats in pairs(registry) do
    table.insert(results, {
      name = name,
      count = stats.count,
      total_ms = tonumber(stats.total) / NS_PER_MS,
      self_ms = tonumber(stats.self) / NS_PER_MS,
    })
  end

  -- Sort by Total Time (descending)
  table.sort(results, function(a, b)
    return a.total_ms > b.total_ms
  end)

  -- Formatting helpers
  local function fmt_ms(ns)
    return string.format("%10.3f", ns)
  end
  local function fmt_pct(val, total)
    return string.format("%6.1f%%", (val / total) * 100)
  end

  -- Build UI Report
  table.insert(report_lines, "## Neovim Profiler Report")
  table.insert(report_lines, string.format("Total Session: %.3f ms", tonumber(total_session_ns) / NS_PER_MS))
  table.insert(report_lines, "")
  table.insert(
    report_lines,
    string.format("| %-30s | %6s | %10s | %10s | %7s |", "Section", "Calls", "Total(ms)", "Self(ms)", "% Sess")
  )
  table.insert(report_lines, string.rep("-", 80))

  for _, item in ipairs(results) do
    table.insert(
      report_lines,
      string.format(
        "| %-30s | %6d | %s | %s | %s |",
        item.name,
        item.count,
        fmt_ms(item.total_ms),
        fmt_ms(item.self_ms),
        fmt_pct(item.total_ms, tonumber(total_session_ns) / NS_PER_MS)
      )
    )
  end

  -- Display in a scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, report_lines)
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.cmd("vsplit")
  vim.api.nvim_win_set_buf(0, buf)
end

return M
