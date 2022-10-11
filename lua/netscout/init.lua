local M = {}

M.default_config = {
    platforms = {
        V5 = {
            builder = "172.27.12.13",
            folder  = "3.7.10"
        },
        VStream = {
            builder = "172.27.12.13",
            folder  = "3.7.10"
        }
    },
    commands = {
        sync = { cmdline = "sync.bat" },
        compile = { cmdline = "compile.bat" },
        clean = { cmdline = "clean.bat" }
    },
    target = "",
    scripts_folder = ""
}

M.pathSeparator = function()
     if (vim.loop.os_uname().sysname:find('Windows', 1, true) ~= nil) then
        return "\\"
    end
    return '/'
end

M.default_values = {
    current_platform = "",
    current_remote   = "",
    remotes = {},
    last_executed_command = nil,
    current_dest = "",
    destinations = {}
}
M.values = M.default_values


local status_file = vim.fn.stdpath('state') .. M.pathSeparator() .. 'netscout.nvim.lua'

local function loadStatus()
    local test = io.open(status_file, "r")
    if test ~= nil then
        local contents = test:read "*a"
        test:close()
        M.values = require('netscout.utils').deserialize(contents)[1]
    end
end

local function saveStatus()
    local result, _ = require('netscout.utils').serialize(M.values)
    local test = assert(io.open(status_file, "w"))
    test:write(result)
    test:close()
end

M.pickPlatform = function()
    local platforms = { M.values.current_platform }
    for k,_ in pairs(M.config.platforms) do
        if k ~= M.values.current_platform then
            table.insert(platforms, k)
        end
    end

    vim.ui.select(platforms,
    { prompt = "Select platform", },
    function(platform, _)
        if platform then
            M.values.current_platform = platform
            saveStatus()
        end
    end)
end

M.pickRemote = function()

    function ListRemotes(...)
        local remotes = {}
        for k,_ in pairs(M.values.remotes) do
            table.insert(remotes, k)
        end
        return remotes.join("\n")
    end

    vim.ui.input( { prompt = "Select remote: ",
    completion = 'custom, ListRemotes',
    default = M.values.current_remote },
    function(remote)
        if remote then
            M.values.current_remote = remote
            if M.values.remotes[remote] == nil then
                table.insert(M.values.remotes, remote)
                saveStatus()
            end
        end
    end)
    vim.api.nvim_command('mode')
end

M.pickDest = function()

    function ListDestinations(...)
        local destinations = {}
        for k,_ in pairs(M.values.destinations) do
            table.insert(destinations, k)
        end
        return destinations.join("\n")
    end

    vim.ui.input( { prompt = "Select destination folder: ",
    completion = 'custom, ListDestinations',
    default = M.values.current_dest },
    function(dest)
        if dest then
            M.values.current_dest = dest
            if M.values.destinations[dest] == nil then
                table.insert(M.values.destinations, dest)
                saveStatus()
            end
        end
    end)
    vim.api.nvim_command('mode')
end

M.launchCommand = function()
    local commands = { }
    if M.values.last_executed_command then
        table.insert(commands, M.values.last_executed_command)
    end

    for k,_ in pairs(M.config.commands) do
        if k ~= M.values.last_executed_command then
            table.insert(commands, k)
        end
    end

    vim.ui.select(commands,
    { prompt = "Select command:", },
    function(command, _)
        if command then
            M.values.last_executed_command = command
            saveStatus()
            local title = command:gsub("\"", "")
            local command_line = M.config.scripts_folder .. M.pathSeparator() .. M.config.commands[command].cmdline ..
                                 " \"" .. M.config.platforms[M.values.current_platform].builder .. "\" \"" ..  M.config.platforms[M.values.current_platform].folder .. "\" \"" ..  M.values.current_remote .. "\" \"" .. M.values.current_dest .. "\" \"" .. vim.fn.getcwd() .. "\" " ..
                                 (M.config.commands[command].args or "")

            --print("Generated command line: " .. command_line)

            vim.api.nvim_command('FloatermNew --title="' .. title .. '_on_' .. M.values.current_platform .. '" --autoclose=0 ' .. command_line)
        end
    end)
end

M.toggleCurrentTerminal = function()
    vim.api.nvim_command('FloatermToggle ')
end

M.cycleTerminal = function()
    vim.api.nvim_command('FloatermNext ')
end

M.printStatus = function()
    local platform = (M.values.current_platform:len() > 0) and M.values.current_platform or "No plat"
    local remote = (M.values.current_remote:len() > 0) and M.values.current_remote or "No remote"
    local dest = (M.values.current_dest:len() > 0) and M.values.current_dest or "No dest"
    return "<" .. platform  .. "> [" .. remote .. "] " .. dest
end

M.setup = function(opts)
    M.config = opts or M.default_config
    loadStatus()
end

return M
