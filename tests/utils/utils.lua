local path_utils = require("tests.utils.paths")
local M = {}

M.paths = path_utils

--- Register the main plugin on the runtimepath
M.rtp_register_plugin = function()
    vim.opt.runtimepath:append(path_utils.static.plugin_dir())
end

return M
