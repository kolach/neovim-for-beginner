local M = {}

local utils = require "utils"

if not unpack then
  -- luacheck: push ignore 121
  unpack = table.unpack
  -- luacheck: pop
end

local vimspector_config_templates = {}

vimspector_config_templates["python"] = [[
{
  "configurations": {
    "<name>: Launch": {
      "adapter": "debugpy",
      "configuration": {
        "name": "Python: Launch",
        "type": "python",
        "request": "launch",
        "python": "%s",
        "stopOnEntry": true,
        "console": "externalTerminal",
        "debugOptions": [],
        "program": "${file}"
      }
    }
  }
}
]]

vimspector_config_templates["rust"] = [[
{
  "configurations": {
    "launch": {
      "adapter": "CodeLLDB",
      "filetypes": [ "rust" ],
      "configuration": {
        "request": "launch",
        "program": "${workspaceRoot}/target/debug/vimspector_test"
      }
    },
    "attach": {
      "adapter": "CodeLLDB",
      "filetypes": [ "rust", "c", "cpp", "jai" ],
      "configuration": {
        "request": "attach",
        "program": "${workspaceRoot}/${fileBasenameNoExtension}",
        "PID": "${PID}"
      }
    }
  }
}
]]

local function debuggers()
  vim.g.vimspector_install_gadgets = {
    "debugpy", -- Python
    "CodeLLDB", -- Rust
  }
end

--- Generate debug profile. Currently for Python only
function M.generate_debug_profile()
  -- Get current file type
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.api.nvim_buf_get_option(buf, "filetype")

  local debugTemplate = vimspector_config_templates[ft]
  if debugTemplate == nil then
    utils.info("Unsupported language - " .. ft, "Generate Debug Profile")
  else
    local templateArgs = {}
    if ft == "python" then
      table.insert(templateArgs, vim.fn.exepath "python")
    end

    local debugProfile = string.format(debugTemplate, unpack(templateArgs))

    -- Generate debug profile in a new window
    vim.api.nvim_exec("vsp", true)
    local win = vim.api.nvim_get_current_win()
    local bufNew = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(bufNew, ".vimspector.json")
    vim.api.nvim_win_set_buf(win, bufNew)

    local lines = {}
    for s in debugProfile:gmatch "[^\r\n]+" do
      table.insert(lines, s)
    end
    vim.api.nvim_buf_set_lines(bufNew, 0, -1, false, lines)
  end
end

function M.toggle_human_mode()
  if vim.g.vimspector_enable_mappings == nil then
    vim.g.vimspector_enable_mappings = "HUMAN"
    utils.info("Enabled HUMAN mappings", "Debug")
  else
    vim.g.vimspector_enable_mappings = nil
    utils.info("Disabled HUMAN mappings", "Debug")
  end
end

function M.setup()
  vim.cmd [[packadd! vimspector]] -- Load vimspector
  debuggers() -- Configure debuggers
end

return M
