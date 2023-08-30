local cli = require("neogit.lib.git.cli")
local util = require("neogit.lib.util")

local M = {}

--- [TODO:description]
--- @return boolean
function M.is_bisect_inprogress()
  local git_dir = vim.fn.systemlist("git rev-parse --git-dir")[1]
  local bisect_log = git_dir .. "/BISECT_LOG"
  return vim.fn.filereadable(bisect_log) == 1
end

function M.write_output()
  --todo
  local git_dir = vim.fn.systemlist("git rev-parse --git-dir")[1]
end

--- [TODO:description]
---@return table
function M.get_revisions()
  local revisions = cli["for-each-ref"].format('"%(refname:short)"').call():trim().stdout
  for i, str in ipairs(revisions) do
    revisions[i] = string.sub(str, 2, -2)
  end
  return revisions
end

--- [TODO:description]
---@param a string commit
---@param b string commit
---@return boolean
function M.is_ancestor(a, b)
  local out = cli["merge-base"].arg_list({ a, b }).is_ancestor.call_ignoring_exit_code():trim().code
  return out ~= 1
end

--- Detects if there is staged/unstaged changes
---@return boolean
function M.has_changes()
  local unstaged = cli.diff.quiet.call_ignoring_exit_code().code
  local staged = cli.diff.quiet.cached.call_ignoring_exit_code().code
  return unstaged ~= 0 or staged ~= 0
end

--- Starts bisecting
---@param bad string Bad ref
---@param good string Good ref
function M.start(bad, good)
  if M.is_bisect_inprogress() then
    vim.notify("Not bisecting")
    return
  end

  vim.notify("Bisecting...")
  local out = cli["bisect"].arg_list({ "start", "bad", bad, "good", good }).call():trim().stdout
  vim.notify("Bisecting...done")
  local status = require("neogit.status")
  if status.status_buffer then
    status.status_buffer:focus()
    status.dispatch_refresh(true, "bisect")
  end
end

function M.update_status(state)
  state.bisect.in_progress = M.is_bisect_inprogress()
end

function M.reset()
  local out = cli["bisect"].args("reset").call():trim().stdout
  -- Magit deletes their own CMD output file here
  local status = require("neogit.status")
  if status.status_buffer then
    status.status_buffer:focus()
    status.dispatch_refresh(true, "bisect")
  end
end

M.register = function(meta)
  meta.update_status = M.update_status
end

return M
