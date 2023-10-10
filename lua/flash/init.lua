local M = {}

M.buf = require("flash.buffers")
M.HEAD = nil

local make_entry = require 'telescope.make_entry'
local Path = require("plenary.path")
local os_sep = Path.path.sep
local scan = require 'plenary.scandir'

M.FLASH = vim.fn.getcwd()
local problems = {}

local data_path = vim.fn.stdpath("data")
local cache_problems = string.format("%s/flash.json", data_path)


-- Stack functions
M.push = function(name, simname, opts)
    local sim = {}
    sim["sim"] = simname
    sim["opts"] = opts
    sim["runDirs"] = {}
    problems[name] = sim
    M.save()
    M.HEAD = name
end

M.switch = function(name)
    M.HEAD = name
end

M.getProblems = function()
    return problems
end

M.add = function(opts, name)
    name = name or M.HEAD
    local sim = problems[name]
    sim["opts"] = sim["opts"] .. " " .. opts
    problems[name] = sim
end

M.save = function()
    problems["HEAD"] = M.HEAD
    Path:new(cache_problems):write(vim.fn.json_encode(problems), "w")
end

M.load = function()
    return vim.json.decode(Path:new(cache_problems):read())
end

M.init = function(FLASH_DIR)
    -- initialize by trying to read problems from cached table if it exists
    M.FLASH = FLASH_DIR or './'
    local ok, probs = pcall(M.load, cache_problems)
    if ok then
        problems = probs
        M.HEAD = next(problems, nil)
    end
end

-- end stack
--
-- FLASH directory related actions

local getObjDir = function(name)
    name = name or M.HEAD
    local objdir = "nvim/object_" .. name
    return objdir
end

M.getSimDir = function(name)
    name = name or M.HEAD
    return "source/Simulation/SimulationMain" .. os_sep .. problems[name]["sim"]
end

M.setup = function(name)
    M.HEAD = name or M.HEAD
    local objdir = getObjDir(M.HEAD)
    vim.fn.jobstart({ 'mkdir', '-p', M.FLASH .. os_sep .. objdir })
    local setupPY = M.FLASH .. "/bin/setup.py"
    local opts = problems[M.HEAD]["opts"] .. " -objdir=" .. objdir
    local prob = problems[M.HEAD]["sim"]
    M.buf.get_buf()
    local command = { setupPY, prob }
    for w in opts:gmatch("%g+") do table.insert(command, w) end
    M.buf.run_buf(command, { cwd = M.FLASH .. "/bin" })
end

local copy2run = function(name, file, runName)
    runName = runName or ''
    name = name or M.HEAD
    local rd = problems[name]["RD"]
    local rundir = M.FLASH .. os_sep .. getObjDir(name) .. os_sep .. problems[name]["runDirs"][rd]
    vim.fn.system("cp " .. file .. " " .. rundir .. os_sep .. runName)
end

M.addRunDir = function(name, runDir, parfile)
    name = name or M.HEAD
    parfile = parfile or M.FLASH .. os_sep .. getObjDir(name) .. os_sep .. "flash.par"
    if not problems[name]["runDirs"] then
        print(vim.inspect(problems[name]["runDirs"]))
        problems[name]["runDirs"] = {}
    end
    if runDir then
        -- table.insert(problems[name]["runDirs"], runDir)
        problems[name]["runDirs"][runDir] = runDir
        problems[name]["RD"] = runDir
        vim.fn.system("mkdir -p " .. M.FLASH .. os_sep .. getObjDir(name) .. os_sep .. runDir)
        copy2run(name, parfile, 'flash.par')
        local dataFiles = problems[name]["dataFiles"]
        if dataFiles then
            for _, df in pairs(dataFiles) do
                copy2run(name, M.FLASH .. os_sep .. M.getSimDir(name) .. os_sep .. df)
            end
        end
    end
end

M.compile = function(opts)
    opts = opts or ""
    local objdir = getObjDir(M.HEAD)
    local command = "make " .. opts
    M.buf.run_buf(command, { cwd = M.FLASH .. "/" .. objdir })
end

M.run = function(opts)
    opts = opts or '-np 1'
    local objdir = getObjDir(M.HEAD)
    local command = 'mpirun ' .. opts .. ' ' .. M.FLASH .. os_sep .. objdir .. '/flash4'
    -- TODO: run in data directory
    local rd = problems[M.HEAD]["RD"]
    local rundir = objdir
    if rd then
        rundir = objdir .. os_sep .. problems[M.HEAD]["runDirs"][rd]
    end
    M.buf.run_buf(command, { cwd = M.FLASH .. os_sep .. rundir })
end

M.dataFiles = function()
    local objdir = M.FLASH .. os_sep .. getObjDir(M.HEAD)
    local simdir = problems[M.HEAD]["sim"]

    print(simdir)
    local all_dirs = vim.split(simdir, os_sep)

    local files = {}
    local getConfigs = function(dir)
        scan.scan_dir(dir, {
            hidden = false,
            depth = 1,
            search_pattern = "Config",
            on_insert = function(entry)
                table.insert(files, entry)
            end,
        })
    end
    local dataFiles = {}
    local absDir = M.FLASH .. os_sep .. "source/Simulation/SimulationMain"
    for i, dir in pairs(all_dirs) do
        absDir = absDir .. os_sep .. dir
        getConfigs(absDir)
        local file = files[i]
        local gout = vim.fn.system('grep "^\\s*DATAFILES" ' .. file)
        gout = string.gsub(gout, " ", "")
        local result = vim.split(string.gsub(gout, "DATAFILES", ""), "\n")
        for _, f in pairs(result) do
            if f ~= "" then
                table.insert(dataFiles, f)
            end
        end
        problems[M.HEAD]["dataFiles"] = dataFiles
    end
end

-- local FLASH_DIR = os.getenv('FLASH_DIR')
-- M.init(FLASH_DIR)
-- M.dataFiles()
-- M.addRunDir(M.HEAD, "RUN01")


return M
