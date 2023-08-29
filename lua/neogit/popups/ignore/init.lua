local popup = require("neogit.lib.popup")
local actions = require("neogit.popups.ignore.actions")

local M = {}

local noop = function() end

--- [TODO:description]
---@param opts table
function M.create(opts)
  local p = popup
    .builder()
    :name("Ignore")
    :action("t", "shared at toplevel (.gitignore)", actions.ignore_toplevel)
    :action("s", "shared in subdirectory (path/to/.gitignore)", noop)
    :action("p", "privately (path/to/.gitignore)", noop)
    :env({
      untracked = opts.untracked,
    })
    :build()
  p:show()
end

return M
