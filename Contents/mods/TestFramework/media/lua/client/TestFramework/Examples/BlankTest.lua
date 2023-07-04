if not getActivatedMods():contains("TEST_FRAMEWORK") or not isDebugEnabled() then return end -- Testing is only supported in debug mode and users should not have to have this mod enabled to play your mod
local TestFramework = require("TestFramework/TestFramework") -- Will be nil if debug mode is not enabled
local TestUtils = require("TestFramework/TestUtils")
local AsyncTest = require("TestFramework/AsyncTest")

if true then return end -- Remove this line to enable this test module

TestFramework.registerTestModule("YOUR_MOD_NAME", "NAME_FOR_THIS_GROUP_OF_TEST", function ()
    local Tests = {}

    -- This function is called before the module is run
    Tests._setup = function () end

    -- This function is called after the module finishes running
    Tests._teardown = function () end

    --    Add code coverage for an object
    --    Tracks what functions are called during testing
    --    Optional 4th boolean to ignore inherited functions
    --TestFramework.addCodeCoverage(Tests, YOUR_OBJECT, "READABLE_NAME_FOR_THIS_OBJECT")

    -- Regular test
    Tests.test_name = function ()
        TestUtils.assert(true)
    end

    -- Async test
    Tests.async_test_name = function ()
        return AsyncTest:new()
        :next(function ()
            TestUtils.assert(true)
        end)
    end

    return Tests
end)
