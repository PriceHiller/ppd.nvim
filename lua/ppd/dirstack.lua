local config = require("ppd.config")

---@alias ppd.Dirstack.scope "global" | "tab" | "window"

---@class ppd.DirStack
---@field scope ppd.Dirstack.scope
---@field autocmd integer?
---@field watch_cd_enabled boolean
---@field augroup integer
---@field stack string[]
local DirStack = {}

--- Create a new Dirstack
---@param scope ppd.Dirstack.scope
---@return ppd.DirStack
function DirStack.new(scope)
    local valid_scopes = {
        "global",
        "tab",
        "window",
    }
    vim.validate {
        scope = {
            scope,
            function(sc)
                return vim.tbl_contains(valid_scopes, sc)
            end,
            "a valid DirStack scope",
        },
    }

    local self = setmetatable({
        scope = scope,
        stack = {},
        augroup = vim.api.nvim_create_augroup("Ppd" .. scope:upper(), { clear = false }),
    }, { __index = DirStack })

    -- Put at minimum, a single directory on the stack by default so it's possible to unwind to the
    if scope == "global" then
        self:push(vim.fn.getcwd(-1, -1))
    elseif scope == "tab" then
        self:push(vim.fn.getcwd(-1, 0))
    else
        self:push(vim.fn.getcwd(0))
    end

    -- Start the watch *after* we have a single base directory on the path
    self:watch_cd()

    return self
end

--- Creates an autocmd if not already called to watch cd events for the
--- relevant scope and push the directories onto the stack if `auto_cd` is
--- enabled
function DirStack:watch_cd()
    self.watch_cd_enabled = true
    if self.autocmd then
        return
    end

    self.autocmd = vim.api.nvim_create_autocmd("DirChanged", {
        group = self.augroup,
        desc = "Ppd " .. self.scope .. " Listener for Auto CD",
        pattern = self.scope,
        callback = function(args)
            if config.auto_cd and self.watch_cd_enabled then
                local new_dir = args.file
                self:push(new_dir)
            end
        end,
    })
end

function DirStack:unwatch_cd()
    self.watch_cd_enabled = false
end

--- Get the string representation of the stack
---@return string
function DirStack:repr()
    return table.concat(self.stack, " ")
end

--- Removes one or more directories off the stack and returns them
---@private
---@param count integer? The number of directories to pop or nil for one
---@return string[] removed_paths The paths removed in order from the stack
function DirStack:pop(count)
    count = count or 1
    local removed_paths = {}
    while not self:empty() and count > 0 do
        count = count - 1
        table.insert(removed_paths, table.remove(self.stack))
    end

    return removed_paths
end

--- Get whether the stack is empty, empty being defined as only one element
---@return boolean is_empty true if the stack is empty
function DirStack:empty()
    return #self.stack == 1
end

--- Push a path onto the stack
---@private
---@param path string
function DirStack:push(path)
    path = vim.fn.fnamemodify(vim.fn.fnamemodify(path, ":p:h"), ":~")
    if not ((config.dedup.all and self:check_dup_all(path)) or (config.dedup.top and self:check_dup_top(path))) then
        table.insert(self.stack, path)
    end
end

--- Peek the top of the stack
---@return string? top_path The path at the top of the stack if it exists
function DirStack:peek()
    return self.stack[#self.stack]
end

--- Changes directory accounting for the current scope
---@private
---@param path string A path to change the directory to
function DirStack:cd(path)
    local cmd = ({
        ["global"] = vim.cmd.cd,
        ["tab"] = vim.cmd.tcd,
        ["window"] = vim.cmd.lcd,
    })[self.scope]
    self:unwatch_cd()
    cmd(path)
    self:watch_cd()
end

--- Checks if the topmost element in the stack is the same as the given path
---@param path string
---@return boolean dup_found true if the topmost element is the same as the given path
function DirStack:check_dup_top(path)
    return self:peek() == path
end

--- Checks if any element within the current stack is the same as the given path
---@param path string
---@return boolean dup_found true if a duplicate value is located in the stack
function DirStack:check_dup_all(path)
    return vim.iter(self.stack):any(function(val)
        return val == path
    end)
end

--- Change the current directory for the relevant scope to the given path and push it onto the stack
---@param path string
function DirStack:pushd(path)
    if not path or path:len() == 0 then
        vim.notify(self:repr())
        return
    end

    self:cd(path)
    self:push(path)

    if config.notify.on_pushd then
        vim.notify(self:repr())
    end
end

--- Removes one or more directories off the stack and changes the path to it
---@param count integer? The number of directories to pop or nil for one
function DirStack:popd(count)
    count = count or 1
    self:pop(count)

    local top_path = self:peek()
    if top_path then
        self:cd(top_path)
    end

    if config.notify.on_popd then
        vim.notify(self:repr())
    end
end

return DirStack
