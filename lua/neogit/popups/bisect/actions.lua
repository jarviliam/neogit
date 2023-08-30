local M = {}

local cli = require("neogit.lib.git.cli")
local util = require("neogit.lib.util")
local FuzzyFinderBuffer = require("neogit.buffers.fuzzy_finder")

local special_refs = {
  "HEAD",
  "ORIG_HEAD",
  "FETCH_HEAD",
  "MERGE_HEAD",
  "CHERRY_PICK_HEAD",
}

--- [TODO:description]
--- @return boolean
local function is_bisect_inprogress()
  local git_dir = vim.fn.systemlist("git rev-parse --git-dir")[1]
  local bisect_log = git_dir .. "/BISECT_LOG"
  return vim.fn.filereadable(bisect_log) == 1
end

--- [TODO:description]
---@return table
local function get_revisions()
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
local function is_ancestor(a, b)
  local out = cli["merge-base"].arg_list({ a, b }).is_ancestor.call_ignoring_exit_code():trim().code
  return out ~= 1
end

function M.start_bisect(popup)
  if is_bisect_inprogress() then
    vim.notify("Bisect already in progress")
    return
  end

  local current_head = cli["symbolic-ref"].args("HEAD").short.call():trim().stdout
  current_head = current_head[1]
  local revisions = get_revisions()
  table.insert(revisions, 1, current_head)
  local bad_selection = FuzzyFinderBuffer.new(revisions)
    :open_async { prompt_prefix = "Bad revision", allow_multi = false }
  if bad_selection == nil then
    vim.notify("No commit selected")
    return
  end
  local good_selection = FuzzyFinderBuffer.new(revisions)
    :open_async { prompt_prefix = "Good revision", allow_multi = false }
  if good_selection == nil then
    vim.notify("No commit selected")
    return
  end
  if not is_ancestor(good_selection, bad_selection) then
    vim.notify(
      "The good revision ("
        .. good_selection
        .. ") has to be an ancestor of the bad one ("
        .. bad_selection
        .. ")"
    )
    return
  end
  local out = cli["bisect"].arg_list({ "bad", bad_selection, "good", good_selection }).call():trim().stdout
  return bad_selection
end

return M
