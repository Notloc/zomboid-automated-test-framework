if not getActivatedMods():contains("TEST_FRAMEWORK") or not isDebugEnabled() then return end
local TestFramework = require("TestFramework/TestFramework") 
local TestUtils = require("TestFramework/TestUtils")
local AsyncTest = require("TestFramework/AsyncTest")

if TestFramework.hideExamples then return end

local ExampleClass = require "TestFramework/Examples/CodeCoverageObject"

TestFramework.registerTestModule("Test Framework Examples", "Code Coverage", function ()
    local Tests = {}
    TestFramework.addCodeCoverage(Tests, ExampleClass, "ExampleClass")

    Tests.test_method1 = function ()
        ExampleClass.method1()
    end

    Tests.test_method2 = function ()
        ExampleClass.method2()
    end

    Tests.test_method4 = function ()
        ExampleClass.method4()
    end

    return Tests
end)
