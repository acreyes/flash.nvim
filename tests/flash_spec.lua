local FLASH = '/Users/adamreyes/Documents/research/repos/FLASH'
describe("flash", function()

    it("push sim", function()
        local fl = require("flash")
        fl.push("sedov", "sedov", "-auto +pm4dev +uhd -2d")
        local sim = {["sim"] = "sedov", ["opts"] =  "-auto +pm4dev +uhd -2d"}
        assert.are.same(sim, fl._problems["sedov"])
    end)

    it("write/read problems", function()
        local fl = require("flash")
        fl.setup(FLASH)
        fl.push("sedov", "sedov", "-auto +pm4dev +uhd -2d")
        fl.push("Sod"  , "Sod"  , "-auto +pm4dev +uhd -1d")
        local problems = fl.load()
        assert.are.same(problems, fl._problems)
    end)

    it("ammend opts", function()
        local fl = require("flash")
        fl.setup(FLASH)
        fl.push("sedov", "sedov", "-auto +pm4dev +uhd -2d")
        fl.add("sedov", "+3t")
        local sim = {["sim"] = "sedov", ["opts"] =  "-auto +pm4dev +uhd -2d +3t"}
        assert.are.same(sim, fl._problems["sedov"])
    end)

end)
