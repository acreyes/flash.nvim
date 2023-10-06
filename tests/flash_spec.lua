local FLASH = os.getenv('FLASH_DIR')
describe("flash", function()

    it("push sim", function()
        local fl = require("flash")
        fl.push("Sedov", "Sedov", "-auto +pm4dev +uhd -2d")
        local sim = {["sim"] = "Sedov", ["opts"] =  "-auto +pm4dev +uhd -2d"}
        assert.are.same(sim, fl.getProblems()["Sedov"])
    end)

    it("write/read problems", function()
        local fl = require("flash")
        fl.init(FLASH)
        fl.push("Sedov", "Sedov", "-auto +pm4dev +uhd -2d")
        fl.push("Sod"  , "Sod"  , "-auto +pm4dev +uhd -1d")
        local problems = fl.load()
        assert.are.same(problems, fl.getProblems())
    end)

    it("ammend opts", function()
        local fl = require("flash")
        fl.init(FLASH)
        fl.push("Sod"  , "Sod"  , "-auto +pm4dev +uhd -1d")
        fl.push("Sedov", "Sedov", "-auto +pm4dev +uhd -2d")
        fl.add("+3t")
        fl.add("+3t", "Sod")
        local sim = {["sim"] = "Sedov", ["opts"] =  "-auto +pm4dev +uhd -2d +3t"}
        assert.are.same(sim, fl.getProblems()["Sedov"])
        local sim = {["sim"] = "Sod", ["opts"] =  "-auto +pm4dev +uhd -1d +3t"}
        assert.are.same(sim, fl.getProblems()["Sod"])
    end)

    it("switch", function()
        local fl = require("flash")
        fl.init(FLASH)
        fl.push("Sedov", "Sedov", "-auto +pm4dev +uhd -2d")
        assert.are.same(fl.HEAD, "Sedov")
        fl.push("Sod"  , "Sod"  , "-auto +pm4dev +uhd -1d")
        assert.are.same(fl.HEAD, "Sod")
        fl.switch("Sedov")
        assert.are.same(fl.HEAD, "Sedov")
    end)
end)
