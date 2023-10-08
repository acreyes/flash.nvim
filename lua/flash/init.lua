local M = {}

M.buf = require("flash.buffers")
M.HEAD = nil

local Path = require("plenary.path")

local FLASH = '.'
local problems = {}

local data_path = vim.fn.stdpath("data")
local cache_problems = string.format("%s/flash.json", data_path)


M.push = function(name, simname, opts)
    local sim = {}
    sim["sim"] = simname
    sim["opts"] = opts
    problems[name] = sim
    M.save()
    M.HEAD = name
end

M.switch = function(name)
    M.HEAD = name
end

M.add = function(opts, name)
    name = name or M.HEAD
    local sim = problems[name]
    sim["opts"] = sim["opts"] .. " " .. opts
    problems[name] = sim
end

M.save = function()
    Path:new(cache_problems):write(vim.fn.json_encode(problems), "w")
end

M.load = function()
    return vim.json.decode(Path:new(cache_problems):read())
end

M.init = function(FLASH_DIR)
    -- initialize by trying to read problems from cached table if it exists
    FLASH = FLASH_DIR or './'
    local ok, probs = pcall(M.load, cache_problems)
    if ok then
        problems = probs
    end
end

M.getProblems = function()
    return problems
end

local getObjDir = function(name)
    local objdir = "nvim/object_" .. name
    return objdir
end

M.setup = function(name)
    M.HEAD = name or M.HEAD
    local objdir = getObjDir(M.HEAD)
    -- TODO: configure data directory with DATAFILES & parfile
    vim.fn.jobstart({'mkdir', '-p', FLASH..'/'..objdir})
    local setupPY = FLASH .. "/bin/setup.py"
    local opts = problems[M.HEAD]["opts"] .. " -objdir=" .. objdir
    local prob = problems[M.HEAD]["sim"]
    M.buf.get_buf()
    local command = {setupPY, prob}
    for w in opts:gmatch("%g+") do table.insert(command, w) end
    M.buf.run_buf(command, {cwd=FLASH .. "/bin"})
end

M.compile = function(opts)
    opts = opts or ""
    local objdir = getObjDir(M.HEAD)
    local command = "make " .. opts
    M.buf.run_buf(command, {cwd = FLASH .. "/" .. objdir})
end

M.run = function(opts)
    opts = opts or '-np 1'
    local objdir = getObjDir(M.HEAD)
    local dataDir = objdir .. '/data'
    local command = 'mpirun ' .. opts .. ' ./flash4'
    -- TODO: run in data directory
    M.buf.run_buf(command, {cwd = FLASH .. "/" .. objdir})
end


-- for testing
-- FLASH = '/Users/adamreyes/Documents/research/repos/FLASH'
-- M.setup()
local FLASH_DIR = os.getenv('FLASH_DIR')
M.init(FLASH_DIR)
M.push("sedov", "sedov", "-auto +pm4dev +uhd -2d")
M.buf.get_buf()
-- M.setup()
-- M.compile("-j 8")
-- M.run('-np 4')
vim.keymap.set("n", "<leader>sh", M.setup)
vim.keymap.set("n", "<leader>ch", M.compile)
vim.keymap.set("n", "<leader>rh", M.run)
vim.keymap.set("n", "<leader><leader>k", M.buf.kill_all)
vim.keymap.set("n", "<leader>si", M.buf.send_stdin)
-- M.buf.write_stdout({"hello world"})
-- M.buf.write_stdout({"hello there world"})
-- print(data_path)

return M
-- /Users/adamreyes/Documents/research/repos/FLASH/bin/setup.py sedov -auto +pm4dev +uhd -2d -objdir=nvim/object_sedov

