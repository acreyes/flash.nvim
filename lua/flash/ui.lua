local M = {}

local fl = require("flash")
local buf = require("flash.buffers")

local Path = require 'plenary.path'
local action_set = require 'telescope.actions.set'
local action_state = require 'telescope.actions.state'
local transform_mod = require('telescope.actions.mt').transform_mod
local actions = require 'telescope.actions'
local conf = require('telescope.config').values
local finders = require 'telescope.finders'
local make_entry = require 'telescope.make_entry'
local os_sep = Path.path.sep
local pickers = require 'telescope.pickers'
local scan = require 'plenary.scandir'
local entry_display = require 'telescope.pickers.entry_display'


local getSim = function(name)
    local data = {}
    scan.scan_dir(fl.FLASH..'/source/Simulation/SimulationMain', {
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
                local current_picker = action_state.get_current_picker(prompt_bufnr)

                local dirs = {}
                local selection = action_state.get_selected_entry()
                local simDir = string.gsub(selection.value, fl.FLASH..'/source/Simulation/SimulationMain/', '')

                actions.close(prompt_bufnr)
                M.push(name, simDir:sub(1,-2))
            end)
            return true
        end,
    }):find()
end

M.push = function(name, simname)
    if not name then
        name = vim.fn.input('name: ')
        getSim(name)
    else
        local opts = vim.fn.input('setup flags: ')
        fl.push(name, simname, opts)
    end
end



return M
