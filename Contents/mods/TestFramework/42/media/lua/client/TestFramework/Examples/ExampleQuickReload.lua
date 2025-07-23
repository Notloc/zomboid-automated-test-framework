if not getActivatedMods():contains("TEST_FRAMEWORK") or not isDebugEnabled() then return end
local TestFramework = require("TestFramework/TestFramework") 
local TestUtils = require("TestFramework/TestUtils")
local AsyncTest = require("TestFramework/AsyncTest")

if TestFramework.hideExamples then return end

-- Abuse globals to make quicks reloads visually obvious for example purposes
-- EXAMPLE ONLY, THIS IS NOT NORMAL USAGE, DO NOT DO THIS
if not ___TEST_FRAMEWORK_EXAMPLE_QUICK_RELOAD_GLOBAL_COUNT___ then 
    ___TEST_FRAMEWORK_EXAMPLE_QUICK_RELOAD_GLOBAL_COUNT___ = 0
else
    ___TEST_FRAMEWORK_EXAMPLE_QUICK_RELOAD_GLOBAL_COUNT___ = ___TEST_FRAMEWORK_EXAMPLE_QUICK_RELOAD_GLOBAL_COUNT___ + 1
end

if not ___TEST_FRAMEWORK_EXAMPLE_QUICK_RELOAD_GLOBAL_BOOL___ then
    ___TEST_FRAMEWORK_EXAMPLE_QUICK_RELOAD_GLOBAL_BOOL___ = true
else
    ___TEST_FRAMEWORK_EXAMPLE_QUICK_RELOAD_GLOBAL_BOOL___ = false
end
-- END OF ABUSE

-- Register your test like normal
TestFramework.registerTestModule("Test Framework Examples", "Quick Reload Example", function ()

    -- To easily register a module for quick reload, use the following method to create your test module table 
    -- The filepath should lead to your test's file, starting with either "client/", "server/, or "shared/"
    -- This is case sensitive
    -- Use unix style path separators '/'
    local Tests = TestUtils.newTestModule("client/TestFramework/Examples/ExampleQuickReload.lua")

    -- With that done, the "Quick Reload" button in the Test Framework UI will now reload your test module

    -- The global variables are used below to make obvious changes in the UI when quick reloading this example module
    -- Normally you would be expected to be updating or adding tests, not whatever this is
    if ___TEST_FRAMEWORK_EXAMPLE_QUICK_RELOAD_GLOBAL_BOOL___ then
        Tests.test_method1_pass = function ()
            TestUtils.assert(1 == 1)
        end

        Tests.test_method2_pass = function ()
            TestUtils.assert(1 == 1)
        end

        Tests.test_method3_pass = function ()
            TestUtils.assert(1 == 1)
        end

        Tests["quick_reload_#"..___TEST_FRAMEWORK_EXAMPLE_QUICK_RELOAD_GLOBAL_COUNT___] = function ()
            TestUtils.assert(1 == 1)
        end
    else
        Tests.test_method1_fail = function ()
            TestUtils.assert(1 ~= 1)
        end

        Tests.test_method2_fail = function ()
            TestUtils.assert(1 ~= 1)
        end

        Tests.test_method3_fail = function ()
            TestUtils.assert(1 ~= 1)
        end

        Tests["quick_reload_#"..___TEST_FRAMEWORK_EXAMPLE_QUICK_RELOAD_GLOBAL_COUNT___] = function ()
            TestUtils.assert(1 ~= 1)
        end
    end

    return Tests
end)
