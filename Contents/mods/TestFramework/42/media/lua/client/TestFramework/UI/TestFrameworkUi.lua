require "ISUI/ISPanel"

local TestFramework = require "TestFramework/TestFramework"
local TestUtils = require "TestFramework/TestUtils"

local ScrollPanel = require "TestFramework/UI/ScrollPanel"
local VerticalLayout = require "TestFramework/UI/VerticalLayout"
local HorizontalLayout = require "TestFramework/UI/HorizontalLayout"
local CollapseList = require "TestFramework/UI/CollapseList"

local CodeCoverageUi = require "TestFramework/UI/CodeCoverageUi"
local TestFrameworkSettingsUi = require "TestFramework/UI/TestFrameworkSettingsUi"

local SETTINGS_HEIGHT = 40

local BORDER_COLOR = {r=1, g=1, b=1, a=0.4}
local RED = {r=0.7, g=0, b=0, a=0.4}
local GREEN = {r=0, g=0.7, b=0, a=0.4}

local TestFrameworkUi = ISPanel:derive("TestFrameworkUi")

TestFrameworkUi.new = function(self, x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = {r=0, g=0, b=0, a=0.9}
    o.moveWithMouse = true

    return o
end

function TestFrameworkUi:createChildren()
    ISPanel.createChildren(self)
    self.closeButton = ISButton:new(self.width - 20 - 5, 5, 20, 20, "X", self, ISPanel.close)
    self.closeButton:setAnchorRight(true)
    self:addChild(self.closeButton)

    self.settingsPanel = TestFrameworkSettingsUi:new(0, 30, self.width, SETTINGS_HEIGHT, CodeCoverageUi)
    self:addChild(self.settingsPanel)

    self.scrollPanel = ScrollPanel:new(0, 30+SETTINGS_HEIGHT, self.width, self.height-30-SETTINGS_HEIGHT)
    self:addChild(self.scrollPanel)
    self:rebuildScrollPanel()
end

local runTestsModLambda = function(modName, allTestButtons, moduleParentButtons)
    return function(self, modButton)
        self:runTestsMod(modName, modButton, allTestButtons, moduleParentButtons)
    end
end

local runTestsModuleLambda = function(modName, moduleName, allTestButtons)
    return function(self, moduleButton)
        self:runTestsModule(modName, moduleName, moduleButton, allTestButtons)
    end
end

local runTestsNameLambda = function(modName, moduleName, testName)
    return function(self, button)
        self:runTestsName(modName, moduleName, testName, button)
    end
end

local openCoverageLambda = function (modName, moduleName)
    return function(self, button)
        self:openCoverage(modName, moduleName)
    end
end

local openModCoverageLambda = function (modName)
    return function(self, button)
        self:openModCoverage(modName)
    end
end

local function colorButtonWithResults(button, results)
    local allPassed = true

    if type(results) == "boolean" or not results then
        allPassed = results
    elseif results.passed ~= nil then
        allPassed = results.passed
    else
        for _, result in pairs(results) do
            local passed = result.passed
            if not passed then
                allPassed = false
                break
            end
        end
    end

    if allPassed then
        button.backgroundColor = GREEN
        if button.parent then 
            button.parent.backgroundColor = GREEN
        end
    else
        button.backgroundColor = RED
        if button.parent then 
            button.parent.backgroundColor = RED
        end
    end

    return allPassed
end

local function flattenModButtonMap(modButtons, modName)
    local flattened = {}
    for moduleName, moduleButtons in pairs(modButtons) do
        for name, button in pairs(moduleButtons) do
            local fullName = modName .. "." .. moduleName .. "." .. name
            flattened[fullName] = button
        end
    end
    return flattened
end

local function flattenModuleButtonMap(moduleButtons, modName, moduleName)
    local flattened = {}
    for name, button in pairs(moduleButtons) do
        local fullName = modName .. "." .. moduleName .. "." .. name
        flattened[fullName] = button
    end
    return flattened
end

function TestFrameworkUi:clearButtons()
    for _, button in pairs(self.allButtons) do
        button.backgroundColor = {r=0, g=0, b=0, a=1}
        if button.parent then
            button.parent.backgroundColor = {r=0, g=0, b=0, a=1}
        end
    end
end

function TestFrameworkUi:runTestsMod(modName, modButton, allTestButtons, moduleParentButtons)
    self:clearButtons()
    local flattedTestButtons = flattenModButtonMap(allTestButtons, modName)

    TestFramework.RunByMod(modName,
        -- Completion callback
        function(results)
            colorButtonWithResults(modButton, results)

            for moduleName, buttonsByModule in pairs(allTestButtons) do
                local modulePassed = true

                local prefix = modName .. "." .. moduleName .. "."
                for name, button in pairs(buttonsByModule) do
                    local fullName = prefix .. name
                    local result = results[fullName]
                    modulePassed = colorButtonWithResults(button, result) and modulePassed 
                end

                local moduleButton = moduleParentButtons[modName..moduleName]
                if moduleButton then
                    colorButtonWithResults(moduleButton, modulePassed)
                end
            end

            CodeCoverageUi.rebuildUis()
        end,

        -- Progress callback
        function(name, result)
            local button = flattedTestButtons[name]
            if button then
                colorButtonWithResults(button, result)
                if button.parent then
                    TestFrameworkUi.updateErrorButton(button.parent, result.error)
                end
            end
        end
    )
end

function TestFrameworkUi:runTestsModule(modName, moduleName, moduleButton, allTestButtons)
    self:clearButtons()
    local flattenedTestButtons = flattenModuleButtonMap(allTestButtons, modName, moduleName)
    TestFramework.RunByModule(modName, moduleName, 
        function(results)
            colorButtonWithResults(moduleButton, results)

            local prefix = modName .. "." .. moduleName .. "."
            for name, button in pairs(allTestButtons) do
                local fullName = prefix .. name
                local result = results[fullName]
                colorButtonWithResults(button, result)
            end
        end,

        function(name, result)
            local button = flattenedTestButtons[name]
            if button then
                colorButtonWithResults(button, result)
                if button.parent then
                    TestFrameworkUi.updateErrorButton(button.parent, result.error)
                end
            end

            CodeCoverageUi.rebuildUis()
        end
    )
end

function TestFrameworkUi:runTestsName(modName, moduleName, testName, testButton)
    self:clearButtons()
    TestFramework.RunByTest(modName, moduleName, testName, function(results)
        local fullName = modName .. "." .. moduleName .. "." .. testName
        colorButtonWithResults(testButton, results[fullName])

        if testButton.parent then
            TestFrameworkUi.updateErrorButton(testButton.parent, results[fullName].error)
        end

        CodeCoverageUi.rebuildUis()
    end)
end

function TestFrameworkUi.openTestError(self, button)
    local error = button.test_error
    if error then
        local errorText = tostring(error)
        if type(error) == "table" then
            errorText = tostring(error.message)
        end
        local modal = ISModalDialog:new(0, 0, 300, 200, errorText, false, nil, nil, nil, nil)
        modal:initialise()
        modal:addToUIManager()
        modal:setAlwaysOnTop(true)
        modal:setCapture(true)
        modal.backgroundColor.a = 0.95
        modal.moveWithMouse = true
    end
end

function TestFrameworkUi.updateErrorButton(element, error)
    if element.errorButton then
        element.errorButton.test_error = error
        element.errorButton:setVisible(error ~= nil)
    end
end

function TestFrameworkUi:rebuildScrollPanel()
    self.scrollPanel:clearElements()
    local scrollbarWidth = 13

    local layout = VerticalLayout:new(0, 0, self.scrollPanel:getWidth()-scrollbarWidth, self.scrollPanel:getHeight())
    layout.marginX = 12
    layout.marginY = 8
    layout.paddingY = 6

    self.collapseMap = {}
    self.allButtons = {}

    local buttonsByMod = {}


    local width = self.scrollPanel:getWidth() - layout.marginX*2 - scrollbarWidth + 5
    for modName, moduleGroup in pairs(TestFramework.modules) do
        local modCollapseList = CollapseList:new(0, 0, width, 24)

        local horizontalLayout = HorizontalLayout:new(modCollapseList.marginX, 0, width-modCollapseList.marginX, 24)
        horizontalLayout.borderColor = BORDER_COLOR
        horizontalLayout.marginY = 2
        
        local modLabel = ISLabel:new(0, 0, 20, modName, 1, 1, 1, 1, UIFont.Medium)
        local modCoverageButton = ISButton:new(0, 0, 22, 22, "CC", self, openModCoverageLambda(modName))
        modCoverageButton:initialise()
        modCoverageButton.borderColor = {r=1, g=1, b=1, a=0.9}

        horizontalLayout:addSpacer(5)
        horizontalLayout:addElement(modLabel)
        horizontalLayout:addSpacer(10)
        horizontalLayout:addRightAnchoredChild(modCoverageButton, 88, 1)

        modCollapseList:addElement(horizontalLayout)

        local allTestButtons = {}
        local moduleParentButtons = {}
        buttonsByMod[modName] = allTestButtons

        local moduleNames = {}
        for moduleName, module in pairs(moduleGroup) do
            table.insert(moduleNames, moduleName)
        end
        table.sort(moduleNames)

        self.collapseMap[modName] = modCollapseList

        local width = width - modCollapseList.marginX
        for _, moduleName in ipairs(moduleNames) do
            local module = moduleGroup[moduleName]

            local moduleCollapseList = CollapseList:new(0, 0, width, 24)
            local width = width - moduleCollapseList.marginX

            local horizontalLayout = HorizontalLayout:new(modCollapseList.marginX, 0, width, 24)
            horizontalLayout.borderColor = BORDER_COLOR
            horizontalLayout.marginY = 2

            local moduleLabel = ISLabel:new(0, 0, 20, moduleName, 1, 1, 1, 1, UIFont.Medium)
            horizontalLayout:addSpacer(5)
            horizontalLayout:addElement(moduleLabel)

            local coverageButton = ISButton:new(0, 0, 24, 24, "CC", self, openCoverageLambda(modName, moduleName))
            coverageButton:initialise()
            horizontalLayout:addRightAnchoredChild(coverageButton, 76, 0)

            moduleCollapseList:addElement(horizontalLayout)

            local allModuleButtons = {}
            allTestButtons[moduleName] = allModuleButtons

            self.collapseMap[modName .. "." .. moduleName] = moduleCollapseList

            for _, testName in ipairs(module:getTestNames()) do
                local horizontalLayout = HorizontalLayout:new(modCollapseList.marginX, 0, width, 24)
                horizontalLayout.borderColor = BORDER_COLOR
                horizontalLayout.marginY = 2
                horizontalLayout.marginLeft = 8

                local testLabel = ISLabel:new(0, 0, 20, testName, 1, 1, 1, 1, UIFont.Small)
                local runTestsButton = ISButton:new(0, 0, 40, 24, "Run Test", self, runTestsNameLambda(modName, moduleName, testName))
                runTestsButton:initialise()
                runTestsButton:instantiate()
                
                table.insert(self.allButtons, runTestsButton)

                local showErrorButton = ISButton:new(0, 0, 24, 24, "E", self, TestFrameworkUi.openTestError)
                showErrorButton:initialise()
                showErrorButton:instantiate()
                showErrorButton:setVisible(false)

                horizontalLayout:addSpacer(5)
                horizontalLayout:addElement(testLabel)
                horizontalLayout:addRightAnchoredChild(runTestsButton, 0, 0)
                horizontalLayout:addRightAnchoredChild(showErrorButton, 58, 0)

                horizontalLayout.errorButton = showErrorButton

                moduleCollapseList:addElement(horizontalLayout)
                
                allModuleButtons[testName] = runTestsButton
            end
            
            local runTestsButton = ISButton:new(0, 0, 40, 24, "Run Module", self, runTestsModuleLambda(modName, moduleName, allModuleButtons))
            horizontalLayout:addRightAnchoredChild(runTestsButton, 0, 0)
            
            moduleParentButtons[modName..moduleName] = runTestsButton
            table.insert(self.allButtons, runTestsButton)

            modCollapseList:addElement(moduleCollapseList)
        end

        local runTestsButton = ISButton:new(0, 0, 85, 22, "Run All Tests", self, runTestsModLambda(modName, allTestButtons, moduleParentButtons))
        horizontalLayout:addRightAnchoredChild(runTestsButton, 1, 1)

        table.insert(self.allButtons, runTestsButton)

        layout:addElement(modCollapseList)
    end

    for _, button in ipairs(self.allButtons) do
        button.borderColor = {r=1, g=1, b=1, a=0.9}
    end

    self.scrollPanel:addElement(layout)
end

function TestFrameworkUi:setVisible(visible)
    ISPanel.setVisible(self, visible)
    if visible then
        self:rebuildScrollPanel()
    end
end

function TestFrameworkUi:openCoverage(modName, moduleName)
    local coverageUi = CodeCoverageUi:new(0, 0, 400, 600, modName, moduleName)
    coverageUi:initialise()
    coverageUi:addToUIManager()
end

function TestFrameworkUi:openModCoverage(modName)
    local coverageUi = CodeCoverageUi:new(0, 0, 400, 600, modName, nil)
    coverageUi:initialise()
    coverageUi:addToUIManager()
end

function TestFrameworkUi:getCollapseState()
    local collapseState = {}
    for k, v in pairs(self.collapseMap) do
        collapseState[k] = v.isCollapsed
    end
    return collapseState
end

function TestFrameworkUi:setCollapseState(collapseState)
    for k, v in pairs(collapseState) do
        if self.collapseMap[k] then
            self.collapseMap[k]:setCollapsed(v)
        end
    end
end

TestFrameworkUi.prerender = function(self)
    ISPanel.prerender(self)

    self:drawRect(0, 0, self.width, 30, 1, 0.15, 0.15, 0.25)
    self:drawTextCentre("Test Framework", self.width / 2 + 1, 3, 0, 0.1, 0.6, 1, UIFont.Large)
    self:drawTextCentre("Test Framework", self.width / 2, 2, 1, 1, 1, 1, UIFont.Large)
    self:drawRectBorder(0, 0, self.width, 30, 1, 1, 1, 1)
    self:drawRectBorder(2, 2, self.width-4, 30-4, 1, 1, 1, 1)

    self:drawRectBorder(0, 0, self.width, self.height, 1, 1, 1, 1)
end

return TestFrameworkUi
