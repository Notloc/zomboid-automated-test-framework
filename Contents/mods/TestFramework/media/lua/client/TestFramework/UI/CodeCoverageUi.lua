require "ISUI/ISPanel"

local CodeCoverage = require "TestFramework/CodeCoverage"
local TestFramework = require "TestFramework/TestFramework"

local ScrollPanel = require "TestFramework/UI/ScrollPanel"
local VerticalLayout = require "TestFramework/UI/VerticalLayout"
local HorizontalLayout = require "TestFramework/UI/HorizontalLayout"
local CollapseList = require "TestFramework/UI/CollapseList"

CodeCoverageUi = ISPanel:derive("CodeCoverageUi")

function CodeCoverageUi:new(x, y, width, height, modName, moduleName)
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = {r=0, g=0, b=0, a=0.9}
    o.moveWithMouse = true
    o.modName = modName
    o.moduleName = moduleName

    return o
end

function CodeCoverageUi:createChildren()
    ISPanel.createChildren(self)
    self.closeButton = ISButton:new(self.width - 20 - 5, 5, 20, 20, "X", self, ISPanel.close)
    self.closeButton:setAnchorRight(true)
    self:addChild(self.closeButton)

    self.scrollPanel = ScrollPanel:new(0, 30, self.width, self.height-30)
    self:addChild(self.scrollPanel)
    self:buildScrollPanel()
end

local function colorFromCoverage(wasCovered)
    if wasCovered then
        return {r=0, g=0.7, b=0, a=0.5}
    else
        return {r=0.7, g=0, b=0, a=0.5}
    end
end

function CodeCoverageUi:buildScrollPanel()
    self.scrollPanel:clearElements()

    local layout = VerticalLayout:new(0, 0, self.scrollPanel:getWidth(), self.scrollPanel:getHeight())
    layout.marginX = 6
    layout.marginY = 8
    layout.paddingY = 6

    local module = TestFramework.getModule(self.modName, self.moduleName)
    if not module then return end

    local coverageTargets = module:getCodeCoverageTargets()

    local width = self.scrollPanel:getWidth() - layout.marginX*2
    for _, data in ipairs(coverageTargets) do
        local name = data.name

        local coverageTable = CodeCoverage.coverageTable
        local coverage = coverageTable[data.target]

        if coverage then
            local targetCollapseList = CollapseList:new(0, 0, width, 20)
            local horizontalLayout = HorizontalLayout:new(0, 0, width-targetCollapseList.marginX, 20)
            local modLabel = ISLabel:new(0, 0, 20, name, 1, 1, 1, 1, UIFont.Medium)
            horizontalLayout:addElement(modLabel)
            targetCollapseList:addElement(horizontalLayout)

            for functionName, wasCovered in pairs(coverage) do
                local width = width - targetCollapseList.marginX*2

                local horizontalLayout = HorizontalLayout:new(0, 0, width, 20)
                local spacer = ISLabel:new(0, 0, 20, "    ", 1, 1, 1, 1, UIFont.Small)
                local testLabel = ISLabel:new(0, 0, 20, functionName, 1, 1, 1, 1, UIFont.Small)
                horizontalLayout:addElement(spacer)
                horizontalLayout:addElement(testLabel)
                horizontalLayout.backgroundColor = colorFromCoverage(wasCovered)
                targetCollapseList:addElement(horizontalLayout)
            end

            layout:addElement(targetCollapseList)
        end
    end

    self.scrollPanel:addElement(layout)
end

function CodeCoverageUi:setVisible(visible)
    ISPanel.setVisible(self, visible)
    if visible then
        self:rebuildScrollPanel()
    end
end

CodeCoverageUi.prerender = function(self)
    ISPanel.prerender(self)

    local title = "Code Coverage: " .. self.moduleName

    self:drawRect(0, 0, self.width, 30, 1, 0.15, 0.15, 0.25)
    self:drawTextCentre(title, self.width / 2 + 1, 3, 0, 0.1, 0.6, 1, UIFont.Large)
    self:drawTextCentre(title, self.width / 2, 2, 1, 1, 1, 1, UIFont.Large)
    self:drawRectBorder(0, 0, self.width, 30, 1, 1, 1, 1)
    self:drawRectBorder(2, 2, self.width-4, 30-4, 1, 1, 1, 1)

    self:drawRectBorder(0, 0, self.width, self.height, 1, 1, 1, 1)
end