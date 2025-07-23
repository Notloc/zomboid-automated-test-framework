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
    o.data = nil

    return o
end

function TestModule:getData()
    if not self.data then
        self:parseTestProvider()
    end
    return self.data
end

function TestModule:parseTestProvider()
    local obj = self.testProvider()
    if type(obj) ~= "table" then
        return error("Test providers must return a table of test functions.")
    end

    self.testObject = obj
    self.tests = {}
    self.testNames = {}
    for key, test in pairs(obj) do
        if type(test) == "function" then
            if key == "_setup" then
                self.setup = test
            elseif key == "_teardown" then
                self.teardown = test
            else
                self.tests[key] = test
                table.insert(self.testNames, key)
            end
        elseif type(test) == "table" and key == "_moduleData" then
            self.data = test
        end
    end

    if not self.data then
        self.data = {}
    end
end

function TestModule:getTestNames()
    if not self.testNames then
        self:parseTestProvider()
    end
    return self.testNames
end

function TestModule:getTests()
    local modulePrefix = self.modName.."."..self.moduleName.."."
    self:parseTestProvider()

    local tests = {}
    for name, test in pairs(self.tests) do
        tests[modulePrefix..name] = test
    end
    return tests
end

function TestModule:getTestByName(testName)
    local fullName = self.modName.."."..self.moduleName.."."..testName
    self:parseTestProvider()

    if not self.tests[testName] then
        return error("No test found with name: "..fullName)
    end

    local test = self.tests[testName]
    return {[fullName] = test}
end

function TestModule:getCodeCoverageTargets()
    return self.testObject and self.testObject.___codeCoverageTargets or {}
end

function TestModule:runSetup()
    if self.setup then
        self.setup()
    end
end

function TestModule:runTeardown()
    if self.teardown then
        self.teardown()
    end
end

return TestModule
