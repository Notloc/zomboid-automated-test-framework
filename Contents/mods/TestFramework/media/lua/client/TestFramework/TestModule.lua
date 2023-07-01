local TestUtils = require "TestFramework/TestUtils"

local TestModule = {}

function TestModule:new(modName, moduleName, testProvider)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.modName = modName
    o.moduleName = moduleName
    o.testProvider = testProvider
    o.testObject = nil
    o.tests = nil


    return o
end

function TestModule:prepareTests()
    local obj = self.testProvider()
    if type(obj) ~= "table" then
        return error("Test providers must return a table of test functions.")
    end

    self.testObject = obj
    self.tests = {}
    self.testNames = {}
    for key, test in pairs(obj) do
        if type(test) == "function" then
            self.tests[key] = test
            table.insert(self.testNames, key)
        end
    end
end

function TestModule:getTestNames()
    if not self.testNames then
        self:prepareTests()
    end
    return self.testNames
end

function TestModule:getTests()
    local modulePrefix = self.modName.."."..self.moduleName.."."
    self:prepareTests()

    local tests = {}
    for name, test in pairs(self.tests) do
        tests[modulePrefix..name] = test
    end
    return tests
end

function TestModule:getTestByName(testName)
    local fullName = self.modName.."."..self.moduleName.."."..testName
    self:prepareTests()

    if not self.tests[testName] then
        return error("No test found with name: "..fullName)
    end

    local test = self.tests[testName]
    return {[fullName] = test}
end

function TestModule:getCodeCoverageTargets()
    return self.testObject and self.testObject.___codeCoverageTargets or {}
end

return TestModule
