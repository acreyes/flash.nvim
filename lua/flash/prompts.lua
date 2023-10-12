local M = {}

local fl = require("flash")

local Path = require 'plenary.path'
local action_set = require 'telescope.actions.set'
local action_state = require 'telescope.actions.state'
local actions = require 'telescope.actions'
local conf = require('telescope.config').values
local finders = require 'telescope.finders'
local make_entry = require 'telescope.make_entry'
local os_sep = Path.path.sep
local pickers = require 'telescope.pickers'
local scan = require 'plenary.scandir'
local builtin = require'telescope.builtin'

local getRun = function()
    local name = fl.HEAD
    local data = {}
    local sim = fl.getProblems()[name]
    if sim["RD"] then
        for rundir, _ in pairs(sim["runDirs"]) do
            table.insert(data, rundir)
        end
    end
    pickers.new({}, {
        prompt_title = 'Run Directories',
        finder = finders.new_table { results = data, entry_maker = make_entry.gen_from_file {} },
        sorter = conf.file_sorter {},
        attach_mappings = function(prompt_bufnr)
            action_set.select:replace(function()
                local selection = action_state.get_selected_entry()

                actions.close(prompt_bufnr)
                fl.setRunDir(name, selection.value)
            end)
            return true
        end,
    }):find()
end

local getHead = function()
    local data = {}
    local probs = fl.getProblems()
    for name, _ in pairs(probs) do
        if name ~= 'HEAD' then
            table.insert(data, name)
        end
    end

    pickers.new({}, {
        prompt_title = 'Problems',
        finder = finders.new_table { results = data, entry_maker = make_entry.gen_from_file {} },
        sorter = conf.file_sorter {},
        attach_mappings = function(prompt_bufnr)
            action_set.select:replace(function()
                local selection = action_state.get_selected_entry()

                actions.close(prompt_bufnr)
                M.switch(selection.value)
            end)
            return true
        end,
    }):find()
end

M.pickSim = function()
    local name = fl.HEAD
    local simdir = fl.FLASH .. os_sep .. fl.getSimDir(name)
    builtin.find_files{ cwd=simdir, path_display = { "truncate" } }
end

M.pickRun = function()
    local name = fl.HEAD
    local sim = fl.getProblems()[name]
    if sim['RD'] then
        local rundir = sim['RD']
        local searchdir = fl.FLASH .. os_sep .. fl.getObjDir(name) .. os_sep .. rundir
        builtin.find_files({cwd=searchdir, path_displys = {"truncate"}})
    else
        print('No Active Run Directory')
    end
end

M.pickObj = function()
    local name = fl.HEAD
    local searchdir = fl.FLASH .. os_sep .. fl.getObjDir(name)
    builtin.find_files({cwd=searchdir,
        path_displays={'truncate'},
        follow = 'true'
})
end

M.switch = function(name)
    if name then
        fl.switch(name)
    else
        getHead()
    end
end

M.switchRD = function()
    getRun()
end

M.addRunDir = function(name, runDir)
    name = name or fl.HEAD
    local data = {}
    scan.scan_dir(fl.FLASH .. os_sep .. fl.getSimDir(name), {
        hidden = false,
        depth = 1,
        search_pattern = ".*par",
        on_insert = function(entry)
            table.insert(data,entry)
        end,
    })
    pickers.new({}, {
        prompt_title = 'Simulation Directory',
        finder = finders.new_table { results = data, entry_maker = make_entry.gen_from_file {} },
        -- previewer = conf.file_previewer {},
        sorter = conf.file_sorter {},
        attach_mappings = function(prompt_bufnr)
            action_set.select:replace(function()
                local selection = action_state.get_selected_entry()
                local parfile = selection.value
                -- local parfile = fl.FLASH .. os_sep .. fl.getSimDir(name) .. os_sep .. selection.value
                -- local simDir = string.gsub(selection.value, fl.FLASH .. '/source/Simulation/SimulationMain/', '')

                actions.close(prompt_bufnr)
                fl.addRunDir(name, runDir, parfile)
            end)
            return true
        end,
    }):find()
end


local getSim = function(name)
    local data = {}
    scan.scan_dir(fl.FLASH .. '/source/Simulation/SimulationMain', {
        hidden = false,
        only_dirs = true,
        respect_gitignore = false,
        on_insert = function(entry)
            table.insert(data, entry .. os_sep)
        end,
    })

    table.insert(data, 1, '.' .. os_sep)

    pickers.new({}, {
        prompt_title = 'Simulation Directory',
        finder = finders.new_table { results = data, entry_maker = make_entry.gen_from_file {} },
        -- previewer = conf.file_previewer {},
        sorter = conf.file_sorter {},
        attach_mappings = function(prompt_bufnr)
            action_set.select:replace(function()
                local selection = action_state.get_selected_entry()
                local simDir = string.gsub(selection.value, fl.FLASH .. '/source/Simulation/SimulationMain/', '')

                actions.close(prompt_bufnr)
                M.push(name, simDir:sub(1, -2))
            end)
            return true
        end,
    }):find()
end

-- this is intended to only be called with the "name" argument
-- getSim will recursively call back to this function and provide
-- simname from a telescope prompt
M.push = function(name, simname)
    if not name then
        name = vim.fn.input('name: ')
    end
    if not simname then
        getSim(name)
    else
        local opts = vim.fn.input('setup flags: ')
        fl.push(name, simname, opts)
        local rundir = vim.fn.input('rundir: ')
        if rundir ~= '' then
            M.addRunDir(name, rundir)
        end
    end
end

M.editSetup = function()
  local name = fl.HEAD
  local opts = fl.getProblems()[name]["opts"]
  opts = vim.fn.input({prompt="Setup args: ",default= opts})
  fl.editSetup(name, opts)
end



return M
