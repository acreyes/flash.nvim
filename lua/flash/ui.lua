local M = {}

local fl = require("flash")
local prompts = require("flash.prompts")
local buf = require("flash.buffers")

local scan = require 'plenary.scandir'
local Path = require 'plenary.path'
local os_sep = Path.path.sep

local getSims= function()
    local names = {}
    local probs = fl.getProblems()
    for i,_ in pairs(probs) do
        if i ~= 'HEAD' then
            table.insert(names,i)
        end
    end
    return names
end

vim.api.nvim_create_user_command('Fsetup',
    function(opts)
        local name = opts.fargs[1] or fl.HEAD
        fl.setup(name)
    end,
    {nargs='?',
     complete = function(_, _, _)
         return getSims()
     end,
})

vim.api.nvim_create_user_command('Fmake',
    function(opts)
        local args = ''
        for _, opt in pairs(opts.fargs) do
            args = args..' '..opt
        end
        fl.compile(args)
    end,
    {nargs = '*',
})

vim.api.nvim_create_user_command('Fmpirun',
    function(opts)
        local args = ''
        for _, opt in pairs(opts.fargs) do
            args = args .. ' '..opt
        end
        fl.run(args)
    end,
    {nargs = '*',
})

vim.api.nvim_create_user_command('Fpush',
    function(opts)
        local name = opts.fargs[1]
        prompts.push(name)
    end,
    {nargs = 1,
 })

vim.api.nvim_create_user_command('FaddRun',
    function(opts)
        local runDir = opts.fargs[1]
        prompts.addRunDir(fl.HEAD, runDir)
    end,
    {nargs = 1,
})


 return M
