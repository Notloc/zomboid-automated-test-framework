local LayoutElement = require "TestFramework/UI/LayoutElement"

ScrollPanel = LayoutElement:derive("ScrollPanel");

function ScrollPanel:new(x, y, w, h)
	local o = {};
	o = LayoutElement:new(x, y, w, h);
	setmetatable(o, self);
    self.__index = self;

    o:setAnchorLeft(true);
    o:setAnchorRight(true);
    o:setAnchorTop(true);
    o:setAnchorBottom(true);

    o.lastY = 0;
    o.scrollSensitivity = 12;

    return o;
end

function ScrollPanel:createChildren()
    LayoutElement.createChildren(self);
    self:addScrollBars();
end

function ScrollPanel:addElement(element)
    element.keepOnScreen = false
    LayoutElement.addElement(self, element);
    element:setY(element:getY() + self:getYScroll());
end

function ScrollPanel:isElementVisible(element)
    local elementY = element:getY()
    local elementH = element:getHeight()
    local selfH = self:getHeight()
    return elementY + elementH > 0 and elementY < selfH
end

function ScrollPanel:prerender()
    self:setStencilRect(0, 0, self.width, self.height);
    self:updateScrollbars();

    local deltaY = self:getYScroll() - self.lastY
    for _, child in pairs(self.elements) do
        child:setY(child:getY() + deltaY)
    end
    self.lastY = self:getYScroll()

	ISUIElement.prerender(self)
end

function ScrollPanel:render()
    ISUIElement.render(self);
    self:clearStencilRect();
end

function ScrollPanel:onMouseWheel(del)
	self:setYScroll(self:getYScroll() - (del * self.scrollSensitivity));
    return true;
end

function ScrollPanel:clearElements()
    LayoutElement.clearElements(self);
    self.lastY = 0;
end

function ScrollPanel:reflow()
    LayoutElement.reflow(self);

    local height = 0;
    for _, element in ipairs(self.elements) do
        height = height + element:getHeight() + self.paddingY;
    end

    self:setScrollHeight(height);
    self:updateScrollbars();
end

return ScrollPanel
