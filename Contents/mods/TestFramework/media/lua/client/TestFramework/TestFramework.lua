if not isDebugEnabled() then return end -- Only support testing in debug mode!

if not ___GLOBAL_TEST_FRAMEWORK___ then
    local TestUtils = require "TestFramework/TestUtils"
    local TestModule = require "TestFramework/TestModule"
    local TestRunner = require "TestFramework/TestRunner"
    local CodeCoverage = require "TestFramework/CodeCoverage"

    local TestFramework = {
        hideExamples = true, -- Set to false to show example test modules in the UI
        modules = {},
        onRegisteredCallbacks = {},

        _coreFiles = {
            "client/TestFramework/TestUtils.lua",
            "client/TestFramework/AsyncTest.lua",
            "client/TestFramework/TestFramework.lua",
            "client/TestFramework/UI/TestFrameworkSettingsUi.lua",
            "client/TestFramework/UI/TestFrameworkUi.lua",
            "client/TestFramework/UI/CodeCoverageUi.lua",
        },
        _binderFile = "client/TestFramework/UI/TestFrameworkUiBinder.lua"
    }
    ___GLOBAL_TEST_FRAMEWORK___ = TestFramework

    TestFramework.registerTestModule = function(modName, moduleName, testProvider)
        TestUtils.assertString(modName)
        TestUtils.assertString(moduleName)
        TestUtils.assertFunction(testProvider)

        if not TestFramework.modules[modName] then
            TestFramework.modules[modName] = {}
        end

        TestFramework.modules[modName][moduleName] = TestModule:new(modName, moduleName, testProvider)
        TestFramework.OnModuleRegistered(modName, moduleName)
    end

    TestFramework.addCodeCoverage = function(tests, target, name)
        tests.___codeCoverageTargets = tests.___codeCoverageTargets or {}
        table.insert(tests.___codeCoverageTargets, {name = name, target = target})
    end

    TestFramework.addCodeCoverageIgnoreInherited = function(tests, target, name)
        tests.___codeCoverageTargets = tests.___codeCoverageTargets or {}
        table.insert(tests.___codeCoverageTargets, {name = name, target = target, ignoreInherited = true})
    end

    TestFramework.registerFileForReload = function (filePath)
        table.insert(TestFramework._coreFiles, filePath)
    end

    TestFramework.OnModuleRegistered = function(modName, moduleName)
        for _, callback in pairs(TestFramework.onRegisteredCallbacks) do
            callback(modName, moduleName)
        end
    end

    TestFramework.OnModuleRegisteredSubscribe = function(callback)
        TestFramework.onRegisteredCallbacks[callback] = callback
    end

    TestFramework.OnModuleRegisteredUnsubscribe = function(callback)
        TestFramework.onRegisteredCallbacks[callback] = nil
    end


    TestFramework.getModules = function(modName)
        local modules = TestFramework.modules[modName]
        if not modules then
            return error("No test modules found for mod: "..modName)
        end
        return modules
    end

    TestFramework.getModule = function (modName, moduleName)
        local modules = TestFramework.getModules(modName)
        if not modules then return end

        local module = modules[moduleName]
        if not module then
            return error("No test module found with name: "..modName.."."..moduleName)
        end
        return module
    end

    TestFramework.RunAll = function(completionCallback, progressCallback)
        local testsByModule = {}
        for _, modModules in pairs(TestFramework.modules) do
            for _, module in pairs(modModules) do
                testsByModule[module] = module:getTests()
            end
        end
        TestRunner:new():runTests(testsByModule, completionCallback, progressCallback)
    end

    TestFramework.RunByMod = function(modName, completionCallback, progressCallback)
        local modules = TestFramework.getModules(modName)
        if not modules then return end

        local testsByModule = {}
        for _, module in pairs(modules) do
            testsByModule[module] = module:getTests()
        end

        TestRunner:new():runTests(testsByModule, completionCallback, progressCallback)
    end

    TestFramework.RunByModule = function(modName, moduleName, completionCallback, progressCallback)
        local module = TestFramework.getModule(modName, moduleName)
        if module then
            local testsByModule = {
                [module] = module:getTests()
            }
            TestRunner:new():runTests(testsByModule, completionCallback, progressCallback)
        end
    end

    TestFramework.RunByTest = function(modName, moduleName, testName, completionCallback, progressCallback)
        local module = TestFramework.getModule(modName, moduleName)
        if module then
            local testsByModule = {
                [module] = module:getTestByName(testName)
            }
            TestRunner:new():runTests(testsByModule, completionCallback, progressCallback)
        end
    end

    local function getPathMap()
        if ___GLOBAL_TEST_FRAMEWORK_PATH_MAP___ then
            return ___GLOBAL_TEST_FRAMEWORK_PATH_MAP___
        end

        local pathMap = {}

        local c = getLoadedLuaCount();

        for i = 0, c-1 do
            local path = getLoadedLua(i);
            local name = getShortenedFilename(path);

            pathMap[name] = path
        end

        ___GLOBAL_TEST_FRAMEWORK_PATH_MAP___ = pathMap
        return pathMap
    end

    local function reloadWithSafeErrors(pathMap, fileName)
        local fullPath = pathMap[fileName]
        if fullPath then
            reloadLuaFile(fullPath)
        else
            pcall(function()
                error(fileName.." not found.")
            end)
        end
    end

    function TestFramework.reload()
        local modules = TestFramework.modules

        local carryOverModules = {}
        local reloadModules = {}
        for modName, modModules in pairs(modules) do
            for moduleName, module in pairs(modModules) do
                if not module:getData().filePath then
                    carryOverModules[modName] = carryOverModules[modName] or {}
                    carryOverModules[modName][moduleName] = module
                else
                    table.insert(reloadModules, module:getData().filePath)
                end
            end
        end

        ___GLOBAL_TEST_FRAMEWORK___ = nil

        CodeCoverage.clearCoverage()

        local pathMap = getPathMap()
        for _, file in ipairs(TestFramework._coreFiles) do
            reloadWithSafeErrors(pathMap, file)
        end

        for modName, modModules in pairs(carryOverModules) do
            for moduleName, module in pairs(modModules) do
                ___GLOBAL_TEST_FRAMEWORK___.registerTestModule(modName, moduleName, module.testProvider)
            end
        end

        for _, file in ipairs(reloadModules) do
            reloadWithSafeErrors(pathMap, file)
        end

        reloadWithSafeErrors(pathMap, TestFramework._binderFile)
    end
end

return ___GLOBAL_TEST_FRAMEWORK___
