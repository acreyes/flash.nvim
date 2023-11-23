local M = {}

M.buf = require("flash.buffers")
M.HEAD = nil

local make_entry = require 'telescope.make_entry'
local Path = require("plenary.path")
local os_sep = Path.path.sep
local scan = require 'plenary.scandir'

M.FLASH = vim.fn.getcwd()
M.problems = {}

local data_path = vim.fn.stdpath("data")
local cache_problems = string.format("%s/flash.json", data_path)

M.isCmake = function(name)
  name = name or M.HEAD
  local opts = M.problems[name]["opts"]
  local cmake = false
  local cmake_flags = {'cmake', 'python'}
  for _, cf in pairs(cmake_flags) do
    cmake = cmake or string.match(opts, cf)
  end

  return cmake
end

--
-- FLASH directory related actions

M.getObjDir = function(name)
    name = name or M.HEAD
    local objdir = "nvim/object_" .. name
    return objdir
end

M.getSimDir = function(name)
    name = name or M.HEAD
    return "source/Simulation/SimulationMain" .. os_sep .. M.problems[name]["sim"]
end

M.getExe = function(name)
   name = name or M.HEAD
    local objdir = M.getObjDir(M.HEAD)
    local rd = M.problems[name]["RD"]
    if not rd then
       print("Warning no Run Directory")
    end
    local exePath = M.FLASH .. os_sep .. objdir
    if M.isCmake(name) then
      exePath = exePath .. os_sep .. rd
    end
    return exePath .. os_sep .. "flash4"
end

M.getRunDir = function(name)
   name = name or M.HEAD
   local objdir = M.getObjDir(name)
   local rd = M.problems[name]["RD"]
   local rundir = objdir
   if rd then
      rundir = objdir .. os_sep .. M.problems[name]["runDirs"][rd]["runDirectory"]
   end
   return M.FLASH .. os_sep .. rundir
end

M.setup = function(name)
    M.HEAD = name or M.HEAD
    local objdir = M.getObjDir(M.HEAD)
    vim.fn.jobstart({ 'mkdir', '-p', M.FLASH .. os_sep .. objdir })
    local setupPY = M.FLASH .. "/bin/setup.py"
    local opts = M.problems[M.HEAD]["opts"] .. " -objdir=" .. objdir
    local prob = M.problems[M.HEAD]["sim"]
    M.buf.get_buf()
    local command = { setupPY, prob }
    for w in opts:gmatch("%g+") do table.insert(command, w) end
    M.buf.run_buf(command, { cwd = M.FLASH .. "/bin" })
    M.save()
end

local copy2run = function(name, file, runName)
    runName = runName or ''
    name = name or M.HEAD
    local rd = M.problems[name]["RD"]
    local rundir = M.FLASH .. os_sep .. M.getObjDir(name) .. os_sep .. rd
    vim.fn.system("cp " .. file .. " " .. rundir .. os_sep .. runName)
end

M.cmake = function(name, opts)
  name = name or M.HEAD
  if M.isCmake(name) then
    local objdir = M.FLASH .. os_sep .. M.getObjDir(name)
    local runDir = M.problems[name]["RD"]
    M.buf.run_buf("cmake " .. opts .. " " .. objdir, {cwd = objdir .. os_sep .. runDir})
  end
end

M.addRunDir = function(name, runDir, parfile)
    name = name or M.HEAD
    local objdir = M.FLASH .. os_sep .. M.getObjDir(name)
    parfile = parfile or objdir .. os_sep .. "flash.par"
    if not M.problems[name]["runDirs"] then
        M.problems[name]["runDirs"] = {}
    end
    if runDir then
        -- table.insert(problems[name]["runDirs"], runDir)
        M.problems[name]["runDirs"][runDir] = {runDirectory = runDir, par = parfile}
        M.problems[name]["RD"] = runDir
        vim.fn.system("mkdir -p " .. objdir .. os_sep .. runDir)
        local runPar = 'flash.par'
        if M.isCmake(name) then
          M.buf.run_buf("cmake " .. objdir, {cwd = objdir .. os_sep .. runDir})
          if string.match(parfile, 'py$') then
            runPar = 'flashPar.py'
          end
        end
        copy2run(name, parfile, runPar)
        M.getDataFiles()
        local dataFiles = M.problems[name]["dataFiles"]
        if dataFiles then
            for _, df in pairs(dataFiles) do
                copy2run(name, M.FLASH .. os_sep .. M.getSimDir(name) .. os_sep .. df)
            end
        end
    end
    M.save()
end

M.setRunDir = function(name, runDir)
    M.problems[name]["RD"] = runDir
    M.save()
end

M.compile = function(opts)
    opts = opts or ""
    local objdir = M.getObjDir(M.HEAD)
    local command = "make " .. opts
    local path = M.FLASH .. os_sep .. objdir
    if M.isCmake(M.HEAD) then
      path = path .. os_sep .. M.problems[M.HEAD]["RD"]
    end
    M.buf.run_buf(command, { cwd = path })
end

M.run = function(opts)
    opts = opts or '-np 1'
    local objdir = M.getObjDir(M.HEAD)
    local rd = M.problems[M.HEAD]["RD"]
    local rundir = objdir
    if rd then
        rundir = objdir .. os_sep .. M.problems[M.HEAD]["runDirs"][rd]["runDirectory"]
    end
    local exePath = M.FLASH .. os_sep .. objdir
    if M.isCmake(M.HEAD) then
      exePath = exePath .. os_sep .. rd
    end
    local command = 'mpirun ' .. opts .. ' ' ..  exePath .. os_sep ..  'flash4'
    M.buf.run_buf(command, { cwd = M.FLASH .. os_sep .. rundir })
end

M.getDataFiles = function()
    local simdir = M.problems[M.HEAD]["sim"]

    local all_dirs = vim.split(simdir, os_sep)

    local files = {}
    local getConfigs = function(dir)
        files = {}
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
    local file = ''
    -- print(vim.inspect(files))
    for i, dir in pairs(all_dirs) do
        absDir = absDir .. os_sep .. dir
        getConfigs(absDir)
        _, file = next(files)
        if file then
            local gout = vim.fn.system('grep "^\\s*DATAFILES" ' .. file)
            local result = vim.split(string.gsub(gout, "DATAFILES", ""), "\n")
            for _, f in pairs(result) do
                if f ~= "" then
                    local dFiles = vim.split(f, " ")
                    for _, df in pairs(dFiles) do
                      table.insert(dataFiles, df)
                    end
                end
            end
        end
        M.problems[M.HEAD]["dataFiles"] = dataFiles
    end
    M.save()
end

local checkDir = function(path)
  local isDir = vim.fn.isdirectory(path)
  if isDir == 0 then
    vim.fn.system("mkdir -p " .. path)
  end
  return isDir
end

-- checks the status of a simulation in the current FLASH directory
-- If name doesn't have an object directory, build it
-- loop over the run directories and rebuild them if they don't exist
local checkSim = function(name)
  name = name or M.HEAD
  local objdir = M.FLASH .. os_sep .. M.getObjDir(name)
  local isObj = checkDir(objdir)
  for rd, rdT in pairs(M.problems[name]["runDirs"]) do
    local isRun = checkDir(objdir .. os_sep .. rd)
    if isRun == 0 then
      if rdT['par'] then
        local parfile = rdT['par']
      end
      M.addRunDir(name, rd, parfile)
    end
  end
end


-- Stack functions
M.push = function(name, simname, opts)
    local sim = {}
    sim["sim"] = simname
    sim["opts"] = opts
    sim["runDirs"] = {}
    M.problems[name] = sim
    M.HEAD = name
    M.save()
end

M.editSetup = function(name, opts)
  name = name or M.HEAD
  M.problems[name]["opts"] = opts
  M.save()
end

M.switch = function(name)
    M.HEAD = name
    checkSim(M.HEAD)
    M.save()
end

M.getProblems = function()
    return M.problems
end

M.add = function(opts, name)
    name = name or M.HEAD
    local sim = M.problems[name]
    sim["opts"] = sim["opts"] .. " " .. opts
    M.problems[name] = sim
    M.save()
end

M.save = function()
    M.problems["HEAD"] = M.HEAD
    Path:new(cache_problems):write(vim.fn.json_encode(M.problems), "w")
end

M.load = function()
    return vim.json.decode(Path:new(cache_problems):read())
end

M.init = function(config)
    config = config or {}
    config = vim.tbl_extend("force",
    { FLASH='./',
    }, config)
    -- initialize by trying to read problems from cached table if it exists
    M.FLASH = config['FLASH']
    local ok, probs = pcall(M.load, cache_problems)
    if ok then
        M.problems = probs
        M.HEAD = M.problems['HEAD']
        checkSim(M.HEAD)
        -- M.HEAD = next(problems, nil)
    else
      print("problem!!!!")
    end
end

-- end stack

-- local FLASH_DIR = os.getenv('FLASH_DIR')
-- M.init(FLASH_DIR)
-- checkSim("test")
-- M.dataFiles()
-- M.addRunDir(M.HEAD, "RUN01")


return M
