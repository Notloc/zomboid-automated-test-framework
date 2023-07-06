local TestFrameworkUi = require("TestFramework/UI/TestFrameworkUi")
local TestFramework = require("TestFramework/TestFramework")

if not ___TEST_FRAMEWORK_BINDED then
    ___TEST_FRAMEWORK_BINDED = false
end

if not ___TestFrameworkBinder then
    ___TestFrameworkBinder = {}
end

function ___TestFrameworkBinder.onKey(key)
    local openKey = getCore():getKey("test_framework_open_test_window")
    if key == openKey then
        local uiInstance = ___TestFrameworkBinder.uiInstance
        if uiInstance then
            local wasVisible = uiInstance:isVisible()
            uiInstance:removeFromUIManager()
            ___TestFrameworkBinder.previousUiInstance = uiInstance
            ___TestFrameworkBinder.uiInstance = nil -- Throw away the instance, easier to work on features this way

            if wasVisible then
                return
            end
        end

        local width = 425
        local height = 580

        uiInstance = TestFrameworkUi:new(getCore():getScreenWidth()-width, 0, width, height)
        uiInstance:initialise()
        uiInstance:addToUIManager()
        uiInstance:setVisible(true)
        ___TestFrameworkBinder.uiInstance = uiInstance

        if ___TestFrameworkBinder.previousUiInstance then
            ___TestFrameworkBinder.applyState(___TestFrameworkBinder.previousUiInstance, uiInstance)
        end

        TestFramework.OnModuleRegisteredSubscribe(function(a,b)
            uiInstance:rebuildScrollPanel()
        end)
    end
end

function ___TestFrameworkBinder.applyState(oldUi, newUi)
    local x = oldUi:getX()
    local y = oldUi:getY()
    local collapseState = oldUi:getCollapseState()
    
    newUi:setX(x)
    newUi:setY(y)
    newUi:setCollapseState(collapseState)
end

if ___TestFrameworkBinder.uiInstance then
    local oldUi = ___TestFrameworkBinder.uiInstance
    ___TestFrameworkBinder.uiInstance = nil
    ___TestFrameworkBinder.onKey(getCore():getKey("test_framework_open_test_window"))
    local newUi = ___TestFrameworkBinder.uiInstance
    ___TestFrameworkBinder.applyState(oldUi, newUi)

    oldUi:removeFromUIManager()
end

if not ___TEST_FRAMEWORK_BINDED then
    Events.OnLoad.Add(function ()
        Events.OnKeyPressed.Add(function(key)
            ___TestFrameworkBinder.onKey(key)
        end)
    end)
end

___TEST_FRAMEWORK_BINDED = true
