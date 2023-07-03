if not isDebugEnabled() then return end -- Only support testing in debug mode!

if not ___GLOBAL_TEST_FRAMEWORK___ then
    local TestUtils = require "TestFramework/TestUtils"
    local TestModule = require "TestFramework/TestModule"
    local TestRunner = require "TestFramework/TestRunner"

    local TestFramework = {
        hideExamples = true,
        modules = {},
        onRegisteredCallbacks = {},
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
end

return ___GLOBAL_TEST_FRAMEWORK___
