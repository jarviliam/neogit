local popup = require("neogit.lib.popup")
local actions = require("neogit.popups.bisect.actions")

local M = {}

function M.create()
  local p = popup
    .builder()
    :name("NeogitBisectPopup")
    :option("n", "no-checkout", "Don't checkout commits")
    :option("p", "first-parent", "Follow only first parent of a merge")
    :new_action_group()
    :action("B", "Start", actions.start_bisect)
    :action("s", "Start script", actions.start_bisect)
    :build()

  p:show()

  return p
end

return M
