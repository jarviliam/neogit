local popup = require("neogit.lib.popup")
local actions = require("neogit.popups.bisect.actions")

local M = {}

local function noop() end

--- [TODO:description]
---@param env table
---@return [TODO:return]
function M.create(env)
  local p = popup
    .builder()
    :name("NeogitBisectPopup")
    :option_if(not env.is_bisecting, "n", "no-checkout", "Don't checkout commits")
    :option_if(not env.is_bisecting, "p", "first-parent", "Follow only first parent of a merge")
    :new_action_group_if(not env.is_bisecting, "Actions")
    :action_if(not env.is_bisecting, "B", "Start", actions.start_bisect)
    :action_if(not env.is_bisecting, "s", "Start script", actions.start_bisect)
    :new_action_group_if(env.is_bisecting, "Actions")
    :action_if(env.is_bisecting, "b", "Bad", noop)
    :action_if(env.is_bisecting, "g", "Good", noop)
    :action_if(env.is_bisecting, "k", "Skip", noop)
    :action_if(env.is_bisecting, "r", "Reset", actions.reset_bisect)
    :build()

  p:show()

  return p
end

return M
