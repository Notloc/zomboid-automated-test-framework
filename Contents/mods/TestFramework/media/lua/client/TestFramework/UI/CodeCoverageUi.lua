require "ISUI/ISPanel"

local CodeCoverage = require "TestFramework/CodeCoverage"
local TestFramework = require "TestFramework/TestFramework"

local ScrollPanel = require "TestFramework/UI/ScrollPanel"
local VerticalLayout = require "TestFramework/UI/VerticalLayout"
local HorizontalLayout = require "TestFramework/UI/HorizontalLayout"
local CollapseList = require "TestFramework/UI/CollapseList"

local CodeCoverageUi = ISPanel:derive("CodeCoverageUi")

local BORDER_COLOR = {r=1, g=1, b=1, a=0.4}
local RED = {r=0.7, g=0, b=0, a=0.4}
local GREEN = {r=0, g=0.7, b=0, a=0.4}

function CodeCoverageUi:new(x, y, width, height, modName, moduleName)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = {r=0, g=0, b=0, a=1}
    o.moveWithMouse = true
    o.modName = modName
    o.moduleName = moduleName

    CodeCoverageUi.instances[o] = true
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
        return GREEN
    else
        return RED
    end
end

function CodeCoverageUi:buildScrollPanel()
    self.scrollPanel:clearElements()
    local scrollbarWidth = 13

    local layout = VerticalLayout:new(0, 0, self.scrollPanel:getWidth()-scrollbarWidth, self.scrollPanel:getHeight())
    layout.marginX = 6
    layout.marginY = 8
    layout.paddingY = 2

    local coverageTargets = {}

    if self.modName and self.moduleName then
        local module = TestFramework.getModule(self.modName, self.moduleName)
        if not module then return end
        coverageTargets = module:getCodeCoverageTargets()
    elseif self.modName then
        local modules = TestFramework.getModules(self.modName)
        if not modules then return end

        local seenTargets = {}

        for _, module in pairs(modules) do
            local targets = module:getCodeCoverageTargets()
            for _, target in ipairs(targets) do
                if not seenTargets[target.target] then
                    seenTargets[target.target] = true
                    table.insert(coverageTargets, target)
                end
            end
        end
    else
        return
    end

    self.collapseMap = {}

    local width = self.scrollPanel:getWidth() - layout.marginX*2 - scrollbarWidth - 2
    for _, data in ipairs(coverageTargets) do
        local name = data.name

        local coverageTable = CodeCoverage.coverageTable
        local coverage = coverageTable[data.target]

        if coverage then
            local coveredCount = 0
            local totalCount = 0

            local names = {}
            for functionName, wasCovered in pairs(coverage) do
                table.insert(names, functionName)
                if wasCovered then
                    coveredCount = coveredCount + 1
                end
                totalCount = totalCount + 1
            end
            table.sort(names)

            local percent = totalCount == 0 and 0 or math.floor(coveredCount / totalCount * 100)

            local targetCollapseList = CollapseList:new(0, 0, width, 24)
            local horizontalLayout = HorizontalLayout:new(0, 0, width-targetCollapseList.marginX, 24)
            horizontalLayout.borderColor = BORDER_COLOR
            horizontalLayout.marginY = 2

            local modLabel = ISLabel:new(0, 0, 20, name, 1, 1, 1, 1, UIFont.Medium)
            local spacer = ISLabel:new(0, 0, 20, "    ", 1, 1, 1, 1, UIFont.Small)
            local percentLabel = ISLabel:new(0, 0, 20, percent .. "%", 1, 1, 1, 1, UIFont.Large)
            horizontalLayout:addSpacer(5)
            horizontalLayout:addElement(modLabel)
            horizontalLayout:addElement(spacer)
            horizontalLayout:addRightAnchoredChild(percentLabel, 7, 0)
            targetCollapseList:addElement(horizontalLayout)

            for _, functionName in pairs(names) do
                local wasCovered = coverage[functionName]

                local width = width - targetCollapseList.marginX
                local horizontalLayout = HorizontalLayout:new(0, 0, width, 24)
                horizontalLayout.borderColor = BORDER_COLOR
                horizontalLayout.marginY = 2
                horizontalLayout.marginLeft = 8

                local testLabel = ISLabel:new(0, 0, 20, functionName, 1, 1, 1, 1, UIFont.Medium)
                horizontalLayout:addSpacer(5)
                horizontalLayout:addElement(testLabel)
                horizontalLayout.backgroundColor = colorFromCoverage(wasCovered)
                targetCollapseList:addElement(horizontalLayout)
            end

            self.collapseMap[data.target] = targetCollapseList

            layout:addElement(targetCollapseList)
        end
    end

    self.scrollPanel:addElement(layout)
end

function CodeCoverageUi:setVisible(visible)
    ISPanel.setVisible(self, visible)
    if visible then
        self:buildScrollPanel()
    end

    if visible then
        CodeCoverageUi.instances[self] = true
    else
        CodeCoverageUi.instances[self] = nil
    end
end

function CodeCoverageUi:removeFromUIManager()
    ISPanel.removeFromUIManager(self)
    CodeCoverageUi.instances[self] = nil
end

function CodeCoverageUi:getCollapseState()
    local collapseState = {}
    for target, collapseList in pairs(self.collapseMap) do
        collapseState[target] = collapseList.isCollapsed
    end
    return collapseState
end

function CodeCoverageUi:setCollapseState(collapseState)
    if not self.collapseMap then return end

    for target, isCollapsed in pairs(collapseState) do
        local collapseList = self.collapseMap[target]
        if collapseList then
            collapseList:setCollapsed(isCollapsed)
        end
    end
end

CodeCoverageUi.instances = {}
CodeCoverageUi.rebuildUis = function()
    for ui, _ in pairs(CodeCoverageUi.instances) do
        local collapseState = ui:getCollapseState()
        local scroll = ui.scrollPanel:getYScroll()
        ui:buildScrollPanel()
        ui:setCollapseState(collapseState)
        ui.scrollPanel:setYScroll(scroll)
    end
end

CodeCoverageUi.closeAll = function()
    for ui, _ in pairs(CodeCoverageUi.instances) do
        ui:removeFromUIManager()
    end
end

CodeCoverageUi.prerender = function(self)
    ISPanel.prerender(self)

    local title = "Code Coverage: " .. (self.moduleName or self.modName)

    self:drawRect(0, 0, self.width, 30, 1, 0.15, 0.15, 0.25)
    self:drawTextCentre(title, self.width / 2 + 1, 3, 0, 0.1, 0.6, 1, UIFont.Large)
    self:drawTextCentre(title, self.width / 2, 2, 1, 1, 1, 1, UIFont.Large)
    self:drawRectBorder(0, 0, self.width, 30, 1, 1, 1, 1)
    self:drawRectBorder(2, 2, self.width-4, 30-4, 1, 1, 1, 1)

    self:drawRectBorder(0, 0, self.width, self.height, 1, 1, 1, 1)
end

return CodeCoverageUi
