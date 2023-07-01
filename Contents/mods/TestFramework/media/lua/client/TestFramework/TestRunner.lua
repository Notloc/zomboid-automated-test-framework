local CodeCoverage = require("TestFramework/CodeCoverage")

local TestRunner = {}

function TestRunner:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function TestRunner.terminate()
    Events.OnTick.Remove(TestRunner.onTickFunction)

    local self = TestRunner.activeRunner
    if not self then
        return
    end

    for i=#self.modules, 1, -1 do
        local module = self.modules[i]
        self:_unhookCodeCoverage(module)
    end

    TestRunner.activeRunner = false
end

function TestRunner:runTests(testsByModule, completionCallback, progressCallback)
    if TestRunner.activeRunner then
        return error("TestRunner is already running.")
    end

    if not completionCallback then
        return error("TestRunner requires a completion callback.")
    end

    if type(completionCallback) ~= "function" then
        return error("TestRunner completion callback must be a function.")
    end

    if not progressCallback then
        progressCallback = function(a,b) end
    end

    self.currentTest = 1
    self.testsByModule = testsByModule

    self.currentModule = 1
    self.modules = {}
    for module, _ in pairs(testsByModule) do
        table.insert(self.modules, module)
    end

    self.results = {}
    self.activeAsyncTest = nil
    self.activeAsyncTestName = nil
    self.completionCallback = completionCallback
    self.progressCallback = progressCallback

    TestRunner.activeRunner = self

    for _, module in pairs(self.modules) do
        self:_hookCodeCoverage(module)
    end
    Events.OnTick.Add(TestRunner.onTickFunction)
end

TestRunner.onTickFunction = function()
    local self = TestRunner.activeRunner
    if not self then
        TestRunner.terminate()
        return error("TestRunner has no active runner.")
    end

    if self.currentModule > #self.modules then
        TestRunner.terminate()
        self.completionCallback(self.results)

        local coverageResults = CodeCoverage.coverageTable
        return nil
    end

    local module = self.modules[self.currentModule]

    if self.testDataList == nil then
        local tests = self.testsByModule[module]

        self.testDataList = {}
        for name, test in pairs(tests) do
            table.insert(self.testDataList, {name = name, test = test})
        end
    end

    if self.currentTest > #self.testDataList then
        self.currentModule = self.currentModule + 1
        self.currentTest = 1
        self.testDataList = nil
        return
    end

    if self.activeAsyncTest then
        self.activeAsyncTest:tick()
        if self.activeAsyncTest.completed then
            self.results[self.activeAsyncTestName] = self.activeAsyncTest.results
            self.progressCallback(self.activeAsyncTestName, self.activeAsyncTest.results)
            self.activeAsyncTest = nil
            self.activeAsyncTestName = nil
        else
            return -- Don't increment currentTest yet
        end
    else
        local testData = self.testDataList[self.currentTest]
        local test = testData.test
        local name = testData.name
        local value = self:_runTest(test)

        if type(value) == "table" and value.___IS_ASYNC_TEST___ then
            self.activeAsyncTest = value
            self.activeAsyncTestName = name
            return -- Don't increment currentTest yet
        else
            self.results[name] = value
            self.progressCallback(name, value)
        end
    end
    self.currentTest = self.currentTest + 1
end

local function getMostRecentError()
    local errors = getLuaDebuggerErrors()
    if errors:size() == 0 then
        return "[Unknown Error]"
    end

    if errors:size() == 1 then
        return errors:get(0)
    end

    -- The pcall creates an error as well, hence why we grab both
    return errors:get(errors:size() - 1) .. "\n\n" .. errors:get(errors:size() - 2)
end

function TestRunner:_runTest(test)
    local passed, val = pcall(test)
    if passed then
        return val or {passed=true}
    end

    local err = getMostRecentError()
    return {passed=false, error=err}
end

function TestRunner:_hookCodeCoverage(module)
    local targets = module:getCodeCoverageTargets()
    print("Hooking code coverage for " .. module.moduleName)
    for _, data in pairs(targets) do
        local name = data.name
        print("Hooking " .. name)
    end

    for _, data in pairs(targets) do
        local name = data.name
        local target = data.target
        local ignoreInherited = data.ignoreInherited or false
        CodeCoverage.hook(name, target, ignoreInherited)
    end
end

function TestRunner:_unhookCodeCoverage(module)
    local targets = module:getCodeCoverageTargets()
    for _, data in pairs(targets) do
        local target = data.target
        CodeCoverage.unhook(target)
    end
end

return TestRunner
