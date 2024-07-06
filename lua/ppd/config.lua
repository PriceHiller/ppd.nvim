---@class ppd.Config.dedup
---@field top boolean Do not push duplicate directory onto the stack if the top element in the stack if the same
---@field all boolean Do not push any duplicate directories onto the stack if it already exists within the stack

---@class ppd.Config.notify
---@field on_pushd boolean Notify on every pushd call
---@field on_popd boolean Notify on every popd call

---@class ppd.Config
---@field dedup ppd.Config.dedup
---@field auto_cd boolean Automatically push elements onto the stack on DirChanged events
---@field notify ppd.Config.notify
local Config = {
    auto_cd = true,
    dedup = {
        top = true,
        all = false,
    },
    notify = {
        on_pushd = true,
        on_popd = true,
    },
}

local default_config = vim.deepcopy(Config)

---Update ppd's configuration with new options
---@param config ppd.Config
function Config:update(config)
    Config = vim.tbl_deep_extend("force", self, config)
end

function Config:reset()
    self:update(self:get_defaults())
end

function Config:get_defaults()
    return default_config
end

return Config
