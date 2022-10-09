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
    remotes = {}
}

M.values = {
    current_platform = "V5",
    current_remote   = "172.27.13.133",
    last_executed_command   = nil,
    current_terminal = nil,
    terminals = {}
}

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
            M.config.values = platform
        end
    end)
end

M.pickRemote = function()

    function ListRemotes(...)
        local remotes = {}
        for k,_ in pairs(M.config.remotes) do
            table.insert(remotes, k)
        end
        print(vim.inspect(remotes))
        return remotes.join("\n")
    end

    vim.ui.input( { prompt = "Select remote: ",
    completion = 'custom, ListRemotes',
    default = M.values.current_remote
},
function(remote)
    if remote then
        M.values.current_remote = remote
        if M.config.remotes[remote] == nil then
            table.insert(M.config.remotes, remote)
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
            local title = command:gsub("\"", "")
            vim.api.nvim_command('FloatermNew --title="' .. title .. '_on_' .. M.values.current_platform .. '" --autoclose=0 ' .. M.config.commands[command].cmdline )
        end
    end)
end

M.toggleCurrentTerminal = function()
    vim.api.nvim_command('FloatermToggle ')
end

M.cycleTerminal = function()
    vim.api.nvim_command('FloatermNext ')
end

M.setup = function(opts)
    M.config = opts or M.default_config
end

return M
