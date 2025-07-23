local LayoutElement = require "TestFramework/UI/LayoutElement"

local HorizontalLayout = LayoutElement:derive("HorizontalLayout")

function HorizontalLayout:new(x, y, width, height)
    local o = LayoutElement:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

function HorizontalLayout:addElement(element)
    if element.fillX then
        element.fillX = false
    end
    LayoutElement.addElement(self, element)
end

function HorizontalLayout:addSpacer(width)
    local spacer = ISUIElement:new(0, 0, width, 0)
    self:addElement(spacer)
    return spacer
end

function HorizontalLayout:reflow()
    LayoutElement.reflow(self)

    local x = self.marginLeft or self.marginX
    local y = self.marginY
    for _, element in ipairs(self.elements) do
        element:setX(x)
        element:setY(y)
        x = x + element:getWidth() + self.paddingX
    end
    --self:setWidth(x)
end

return HorizontalLayout
