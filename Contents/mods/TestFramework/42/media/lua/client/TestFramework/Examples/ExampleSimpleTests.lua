if not getActivatedMods():contains("TEST_FRAMEWORK") or not isDebugEnabled() then return end
local TestFramework = require("TestFramework/TestFramework")
local TestUtils = require("TestFramework/TestUtils")

-- Don't register this test module because it is just an example.
if TestFramework.hideExamples then return end

TestFramework.registerTestModule("Test Framework Examples", "Simple Tests", function ()
    local Tests = {}

    Tests.simpleTestPass = function ()
        TestUtils.assert(true)
    end

    Tests.simpleTestFail = function ()
        TestUtils.fail("This test should fail.")
    end

    Tests.complexTestPass = function ()
        TestUtils.assert(true)

        local testTable = { a = 1, b = 2 }
        TestUtils.assertTable(testTable)
        TestUtils.assertNumber(testTable.a)
        TestUtils.assertNumber(testTable.b)

        TestUtils.assertString("Hello World")

        TestUtils.assertNumber(123)
        TestUtils.assertNumber(123.456)

        TestUtils.assertBoolean(true)

        local testFunction = function ()
            return 1
        end
        TestUtils.assertFunction(testFunction)
        TestUtils.assertNil(nil)
    end

    return Tests
end)
