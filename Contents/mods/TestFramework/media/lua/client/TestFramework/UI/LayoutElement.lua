require "ISUI/ISUIElement"

local LayoutElement = ISUIElement:derive("LayoutElement")

function LayoutElement:new(x, y, width, height)
    local o = ISUIElement:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.elements = {}

    o.paddingX = 2
    o.paddingY = 2

    o.marginX = 0
    o.marginY = 0

    return o
end

function LayoutElement:addElement(element)
    table.insert(self.elements, element)
    self:addChild(element)
    self:rebuildLayout()
end

function LayoutElement:removeElement(element)
    for i, e in ipairs(self.elements) do
        if e == element then
            table.remove(self.elements, i)
            self:removeChild(element)
            self:rebuildLayout()
            return
        end
    end
end

function LayoutElement:rebuildLayout()
    if self.parent and self.parent.reflow then
        self.parent:rebuildLayout()
    else
        self:reflow()
    end
end

function LayoutElement:clearElements()
    for _, element in ipairs(self.elements) do
        self:removeChild(element)
    end
    self.elements = {}
end

function LayoutElement:reflow()
    for _, element in ipairs(self.elements) do
        if element.reflow then
            element:reflow()
        end
    end
end

function LayoutElement:prerender()
    local leftOffset = self.marginLeft or self.marginX or 0
    if self.backgroundColor then
        self:drawRect(leftOffset, 0, self:getWidth() - leftOffset, self:getHeight(), self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    end
    if self.borderColor then
        self:drawRectBorder(leftOffset, 0, self:getWidth() - leftOffset, self:getHeight(), self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    end
end

function LayoutElement:addRightAnchoredChild(element, x, y)
    self:addChild(element)
    element:setX(self:getWidth() - x - element:getWidth() - self.marginX)
    element:setY(y)
    element:setAnchorRight(true)
    element:setAnchorLeft(false)
end

return LayoutElement
