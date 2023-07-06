require "ISUI/ISUIElement"

local TestFramework = require("TestFramework/TestFramework")
local TestFrameworkSettingsUi = ISUIElement:derive("TestFrameworkSettingsUi")

function TestFrameworkSettingsUi:new(x, y, width, height, CodeCoverageUiClass)
    local o = ISUIElement:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.CodeCoverageUiClass = CodeCoverageUiClass

    return o
end

function TestFrameworkSettingsUi:createChildren()
    
    local y = 10

    -- toggle break on error
    self.breakOnError = ISTickBox:new(self:getWidth() - 120, y, 120, 20, "Break on error?", self, TestFrameworkSettingsUi.onBreakOnError)
    self.breakOnError:addOption("Break On Error", nil)
    self:addChild(self.breakOnError)
    
    self.quickReload = ISButton:new(10, y, 100, 20, "Quick Reload", self, TestFrameworkSettingsUi.onQuickReload)
    self:addChild(self.quickReload)

end

function TestFrameworkSettingsUi:onBreakOnError()
    local breakOnError = UIManager.isShowLuaDebuggerOnError()
    UIManager.setShowLuaDebuggerOnError(not breakOnError)
end

function TestFrameworkSettingsUi:onQuickReload()
    self.CodeCoverageUiClass.closeAll()
    TestFramework.reload()
end

function TestFrameworkSettingsUi:prerender()
    self:drawRect(0, 0, self.width, self.height, 0.5, 0.1, 0.1, 0.1)
    self:drawRectBorder(0, 0, self.width, self.height, 1, 1.0, 1.0, 1.0)

    self.breakOnError:setSelected(1, UIManager.isShowLuaDebuggerOnError())
end

return TestFrameworkSettingsUi
