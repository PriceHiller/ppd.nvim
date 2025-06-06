local M = {}

local utils = require("tests.utils.utils")
local root = utils.paths.Root:push(".deps/")

---@class ppd.test.MinPlugin A plugin to download and register on the package path
---@alias ppd.test.PluginName string The plugin name, will be used as part of the git clone destination
---@alias ppd.test.PluginCloneInfo string | string[] The git url a plugin located at or a table of arguments to be passed to `git clone`
---@alias ppd.test.MinPlugins table<ppd.test.PluginName, ppd.test.PluginCloneInfo>

---Downloads a plugin from a given url and registers it on the 'runtimepath'
---@param plugin_name ppd.test.PluginName
---@param plugin_clone_args ppd.test.PluginCloneInfo
function M.load_plugin(plugin_name, plugin_clone_args)
    local package_root = root:push("plugins/")
    local install_destination = package_root:push(plugin_name):get()

    vim.opt.runtimepath:append(install_destination)

    if not vim.loop.fs_stat(package_root:get()) then
        vim.fn.mkdir(package_root:get(), "p")
    end

    -- If the plugin install path already exists, we don't need to clone it again.
    if not vim.loop.fs_stat(install_destination) then
        print(string.format("[LOAD PLUGIN] Downloading plugin '%s' to '%s'", plugin_name, install_destination))
        if type(plugin_clone_args) == "table" then
            plugin_clone_args = table.concat(plugin_clone_args, " ")
        end
        vim.fn.system {
            "git",
            "clone",
            "--depth=1",
            plugin_clone_args,
            install_destination,
        }
        if vim.v.shell_error > 0 then
            error(
                string.format("[LOAD PLUGIN] Failed to clone plugin: '%s' to '%s'!", plugin_name, install_destination),
                vim.log.levels.ERROR
            )
        end
    end
    print(("[LOAD PLUGIN] Loaded plugin '%s'"):format(plugin_name))
end

---Do the initial setup. Downloads plugins, ensures the minimal init does not pollute the filesystem by keeping
---everything self contained to the CWD of the minimal init file. Run prior to running tests, reproducing issues, etc.
---@param plugins ppd.test.MinPlugins
function M.setup(plugins)
    print("[SETUP] Setting up minimal init")

    -- Instead of disabling swap and a bunch of other stuff, we override default xdg locations for
    -- Neovim so our test client is as close to a normal client in terms of options as possible
    local xdg_root = root:push("xdg")
    local std_paths = {
        "cache",
        "data",
        "config",
        "state",
    }
    local clean = (vim.env.TEST_CLEANUP and vim.env.TEST_CLEANUP:lower() or true)
    if clean then
        vim.fn.delete(xdg_root:get(), "rf")
    elseif clean == "false" or clean == "0" then
        print("[CLEANUP]: `TEST_CLEANUP` was disabled, not cleaning " .. xdg_root:get())
    end
    for _, std_path in pairs(std_paths) do
        local xdg_str = "XDG_" .. std_path:upper() .. "_HOME"
        local xdg_path = xdg_root:push(std_path):get()
        print(("[SETUP] Set vim.env.%s -> %s"):format(xdg_str, xdg_path))
        vim.env[xdg_str] = xdg_path
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.fn.mkdir(xdg_path, "p")
    end

    -- Empty the package path so we use only the plugins specified
    vim.opt.packpath = {}

    -- Install required plugins
    if plugins ~= nil then
        for plugin_name, plugin_clone_args in pairs(plugins) do
            M.load_plugin(plugin_name, plugin_clone_args)
        end
    end

    -- Ensure `ppd` is registed on the runtimepath, set it up, and initialize it
    utils.rtp_register_plugin()
    require("ppd").setup()

    print("[SETUP] Finished setting up minimal init")
end

M.setup {
    ["plenary.nvim"] = "https://github.com/nvim-lua/plenary.nvim",
}
