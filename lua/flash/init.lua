local M = {}

M.buf = require("flash.buffers")

local Path = require("plenary.path")

M._FLASH = './'
M._problems = {}

local data_path = vim.fn.stdpath("data")
local cache_config = string.format("%s/flash.json", data_path)


M.push = function(name, simname, opts)
    local sim = {}
    sim["sim"] = simname
    sim["opts"] = opts
    M._problems[name] = sim
    M.save()
end

M.add = function(name, opts)
    local sim = M._problems[name]
    sim["opts"] = sim["opts"] .. " " .. opts
    M._problems[name] = sim
end

M.save = function()
    Path:new(cache_config):write(vim.fn.json_encode(M._problems), "w")
end

M.load = function()
    return vim.json.decode(Path:new(cache_config):read())
end

M.setup = function(FLASH_DIR)
    M._Flash = FLASH_DIR or './'
    local ok, problems = pcall(M.load, cache_config)
    if ok then
        M._problems = problems
    end
end

M.buf.get_buf()
vim.fn.jobstart({"ls","-a",M._FLASH}, {
    stdout_buffered=true,
    on_stdout = function(_,data)
        if data then
            M.buf.write_stdout(data)
        end
    end,
})


-- for testing
-- M._FLASH = '/Users/adamreyes/Documents/research/repos/FLASH'
-- M.setup()
-- M.push("sedov", "sedov", "-auto +pm4dev +uhd -2d")
-- print(data_path)

return M
