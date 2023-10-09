local M = {}

local fl = require("flash")
local buf = require("flash.buffers")


vim.api.nvim_create_user_command('Setup',
    function(opts)
        local name = opts.fargs[1] or fl.HEAD
        fl.setup(name)
    end,
    {nargs='?',
     complete = function(_, _, _)
         local names = {}
         local probs = fl.getProblems()
         for i,_ in pairs(probs) do
             if i ~= 'HEAD' then
                 table.insert(names,i)
             end
         end
         return names
     end,
})

vim.api.nvim_create_user_command('Make',
    function(opts)
        local args = ''
        for _, opt in pairs(opts.fargs) do
            args = args..' '..opt
        end
        fl.compile(args)
    end,
    {nargs = '*',
})

vim.api.nvim_create_user_command('Mpirun',
    function(opts)
        local args = ''
        for _, opt in pairs(opts.fargs) do
            args = args .. ' '..opt
        end
        fl.run(args)
    end,
    {nargs = '*'}
    )


return M
