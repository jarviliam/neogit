local cli = require("neogit.lib.git.cli")
local Finder = require("neogit.lib.finder")
local util = require("neogit.lib.util")
local M = {}

local function isDir(path)
  return vim.api.nvim_call_function("isdirectory", { path })
end

local function appendToGitignore(rule)
  local file = vim.fn.expand(".gitignore")
  local contents = vim.fn.readfile(file)
  table.insert(contents, rule)
  vim.fn.writefile(contents, file)
end

--- [TODO:description]
---@param popup Popup
---@return string
function M.ignore_toplevel(popup)
  local untracked = popup.state.env.untracked.items
  local default_value = nil
  if #untracked ~= 0 then
    default_value = untracked[1].name
    if default_value:sub(1, 1) == "/" then
      default_value = default_value:sub(2)
    end
  end
  -- Fetch list of files
  local files = cli["ls-files"].full_name.others.args("--", default_value).call_sync():trim().stdout
  -- Fetch list of dirs
  local dirs = cli["ls-files"].full_name.no_empty_directory.directory.exclude_standard.others
    .args("--", default_value)
    .call_sync()
    :trim().stdout
  -- Ensure list is directories
  local filtered_dirs = util.filter(dirs, isDir)
  -- Combine tables
  local combined_results = util.merge(files, filtered_dirs)

  table.sort(combined_results, function(a, b)
    return a < b
  end)

  local results_with_wildcard = {}
  for _, v in ipairs(combined_results) do
    table.insert(results_with_wildcard, "/" .. v)
    local extension = v:match("%.([^.]+)$")
    if extension ~= nil then
      local directoryPath = v:match("^(.*/)")
      local directory_wildcard = "/" .. directoryPath
      if directoryPath:sub(-1) ~= "/" then
        directory_wildcard = directory_wildcard .. "/*." .. extension
      else
        directory_wildcard = directory_wildcard .. "*." .. extension
      end
      table.insert(results_with_wildcard, "/" .. directoryPath .. "*." .. extension)
      table.insert(results_with_wildcard, "*." .. extension)
    end
  end
  local result = util.filter_unique(results_with_wildcard)

  if default_value ~= nil then
    default_value = "/" .. default_value
    if not vim.tbl_contains(result, default_value) then
      local extension = default_value:match("%.([^.]+)$")
      default_value = "*." .. extension
      if not vim.tbl_contains(result, default_value) then
        default_value = nil
      end
    end
  end
  Finder.create({ allow_multi = false }):add_entries(result):find(function(item)
    appendToGitignore(item)
    cli.add.args(".gitignore").call_sync()
  end)
  return ""
end

return M
