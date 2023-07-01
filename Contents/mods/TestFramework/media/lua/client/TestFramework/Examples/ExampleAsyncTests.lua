if not getActivatedMods():contains("TEST_FRAMEWORK") or not isDebugEnabled() then return end
local TestFramework = require("TestFramework/TestFramework")
local TestUtils = require("TestFramework/TestUtils")
local AsyncTest = require("TestFramework/AsyncTest")

-- Don't register this test module because it is just an example.
if TestFramework.hideExamples then return end

TestFramework.registerTestModule("Test Framework Examples", "Async Tests", function ()
    local Tests = {}

    -- This asynchronous test will equip a baseball bat into the player's hands.
    Tests.equipBaseballBat = function ()
        local playerObj = getSpecificPlayer(0)

        -- First we create the async test object
        local asyncTest = AsyncTest:new()
        
        -- Now we begin building the queue of steps that will comprise the test.
        -- The delay between each step is one game tick by default.
        -- Certain types of steps, such as wait and repeatUntil, can be used to control the delay.
        
        -- Spawn the baseball bat in the player's inventory and start the equip action
        asyncTest:next(function ()
            local baseballBat = playerObj:getInventory():AddItem("Base.BaseballBat")
            TestUtils.assert(baseballBat)
            ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, baseballBat, 50, true, true))
        end)

        -- Hold here until the timed action queue is empty (equip action is finished)
        -- The second parameter is optional. It is the timeout in milliseconds before automatic failure. If not specified, it will default to 10000ms
        asyncTest:repeatUntil(function ()
            return #ISTimedActionQueue.getTimedActionQueue(playerObj).queue == 0
        end, 5000)

        -- Validate that the player has the baseball bat equipped in both hands
        asyncTest:next(function() 
            TestUtils.assert(playerObj:getPrimaryHandItem():getFullType() == "Base.BaseballBat")
        end)

        -- Return the async test object so that it can be executed by the test framework
        return asyncTest
    end

    -- The same test as above, but written in a more compact style
    Tests.equipBaseballBatClean = function ()
        local playerObj = getSpecificPlayer(0)
        return AsyncTest:new()
            :next(function ()
                local baseballBat = playerObj:getInventory():AddItem("Base.BaseballBat")
                TestUtils.assert(baseballBat)
                ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, baseballBat, 50, true, true))
            end)

            :repeatUntil(function ()
                return #ISTimedActionQueue.getTimedActionQueue(playerObj).queue == 0
            end, 5000)

            :next(function() 
                TestUtils.assert(playerObj:getPrimaryHandItem():getFullType() == "Base.BaseballBat")
            end)
    end

    -- A simple asynchronous test that just waits 3 seconds then passes
    Tests.wait3Seconds = function ()
        return AsyncTest:new()
            :wait(3000)
    end

    -- Example of how to share data between steps
    Tests.sharedDataTest = function ()
        -- Create a table to hold the shared data
        -- It will be captured by the closure of each step
        local data = {}

        return AsyncTest:new()
            -- Write to the shared data, local variables will be lost between steps
            :next(function ()
                -- data.a will be available in the next step
                data.a = 5

                -- myTestVariable will not be available in the next step
                local myTestVariable = 10
            end)
            :next(function ()
                TestUtils.assert(data.a == 5)
            end)
    end

    return Tests
end)
