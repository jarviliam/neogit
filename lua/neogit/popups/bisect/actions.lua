local M = {}

local cli = require("neogit.lib.git.cli")
local bisect = require("neogit.lib.git.bisect")
local FuzzyFinderBuffer = require("neogit.buffers.fuzzy_finder")

local special_refs = {
  "HEAD",
  "ORIG_HEAD",
  "FETCH_HEAD",
  "MERGE_HEAD",
  "CHERRY_PICK_HEAD",
}

function M.start_bisect(popup)
  if bisect.is_bisect_inprogress() then
    vim.notify("Bisect already in progress")
    return
  end

  local current_head = cli["symbolic-ref"].args("HEAD").short.call():trim().stdout
  current_head = current_head[1]
  local revisions = bisect.get_revisions()
  table.insert(revisions, 1, current_head)
  table.insert(revisions, 2, "Custom input")
  local bad_selection = FuzzyFinderBuffer.new(revisions)
    :open_async { prompt_prefix = "Bad revision", allow_multi = false }
  if bad_selection == nil then
    vim.notify("No commit selected")
    return
  end
  if bad_selection == "Custom input" then
    bad_selection = vim.fn.input("Bad revision: ")
  end
  local good_selection = FuzzyFinderBuffer.new(revisions)
    :open_async { prompt_prefix = "Good revision", allow_multi = false }
  if good_selection == nil then
    vim.notify("No commit selected")
    return
  end
  if good_selection == "Custom input" then
    good_selection = vim.fn.input("Good revision: ")
  end
  if not bisect.is_ancestor(good_selection, bad_selection) then
    vim.notify(
      "The good revision ("
        .. good_selection
        .. ") has to be an ancestor of the bad one ("
        .. bad_selection
        .. ")"
    )
    return
  end
  if bisect.has_changes() then
    vim.notify("Cannot bisect with uncommitted changes")
    return
  end
  vim.notify("Bisecting...")
  local out =
    cli["bisect"].arg_list({ "start", "bad", bad_selection, "good", good_selection }).call():trim().stdout

  return bad_selection
end

--- After bisecting, cleanup bisection state and return to original `HEAD'.
---@param popup Popup
function M.reset_bisect(popup)
  if vim.fn.input("Reset bisect? (y or n)") == "y" then
    return bisect.reset()
  end
end

return M
