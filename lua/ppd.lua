local config = require("ppd.config")
local dirstack = require("ppd.dirstack")
local M = {}

local stacks = {}

M.stacks = function()
    return stacks
end

M.reset_stacks = function()
    stacks = {
        global = dirstack.new("global"),
        tab = dirstack.new("tab"),
        window = dirstack.new("window"),
    }
end

local user_cmds_created = false
M.create_user_commands = function()
    if user_cmds_created then
        return
    end

    ---@param scope string
    ---@param cmds string[]
    local function create_user_cmd(scope, cmds)
        local desc_scope = (scope:gsub("^%l", string.upper))
        vim.api.nvim_create_user_command(cmds[1], function(o)
            local stack = stacks[scope]
            stack:pushd(vim.trim(o.args))
        end, {
            nargs = "?",
            desc = ("%s Pushd"):format(desc_scope),
            complete = "dir",
        })

        vim.api.nvim_create_user_command(cmds[2], function(o)
            local stack = stacks[scope]
            stack:popd(tonumber(o.args))
        end, {
            nargs = "?",
            desc = ("%s Popd"):format(desc_scope),
        })
    end

    vim.iter({
        global = { "Pushd", "Popd" },
        tab = { "TPushd", "TPopd" },
        window = { "LPushd", "LPopd" },
    }):each(create_user_cmd)

    user_cmds_created = true
end

--- Set up the plugin config
---@param user_config ppd.Config?
M.setup = function(user_config)
    config:update(user_config or {})
    M.create_user_commands()
    M.reset_stacks()
end

M.Config = config

return M
