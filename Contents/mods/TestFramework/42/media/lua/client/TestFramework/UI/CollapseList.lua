local VerticalLayout = require "TestFramework/UI/VerticalLayout"

local CollapseList = VerticalLayout:derive("CollapseList")

function CollapseList:new(x, y, width, height)
    local o = VerticalLayout:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.isCollapsed = true
    o.marginX = 24
    return o
end

function CollapseList:createChildren()
    self.toggleButton = ISButton:new(0, 0, 20, 20, ">", self, CollapseList.onToggle)
    self:addChild(self.toggleButton)
end

function CollapseList:addElement(element)
    VerticalLayout.addElement(self, element)
    self:applyMaxDrawHeight()
end

function CollapseList:removeElement(element)
    VerticalLayout.removeElement(self, element)
    self:applyMaxDrawHeight()
end

function CollapseList:clearElements()
    VerticalLayout.clearElements(self)
    self:applyMaxDrawHeight()
end

function CollapseList:onToggle()
    self:setCollapsed(not self.isCollapsed)
end

function CollapseList:setCollapsed(isCollapsed)
    self.isCollapsed = isCollapsed
    self:applyMaxDrawHeight()
end


function CollapseList:applyMaxDrawHeight()
    if self.isCollapsed then
        self.toggleButton:setTitle(">")
        self:setMaxDrawHeight(self.elements[1] and self.elements[1]:getHeight() or 20)
    else
        self.toggleButton:setTitle("v")
        self:clearMaxDrawHeight()
    end
    self:rebuildLayout()
end

return CollapseList
