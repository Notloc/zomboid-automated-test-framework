local TestUtils = require("TestFramework/TestUtils")

local AsyncTest = {}

local NEXT = "next"
local WAIT = "wait"
local REPEAT_UNTIL = "repeatUntil"

local function getMostRecentError()
    local errors = getLuaDebuggerErrors()
    if errors:size() == 0 then
        return "[Unknown Error]"
    end

    if errors:size() == 1 then
        return errors:get(0)
    end

    -- The pcall creates an error as well, hence why we grab both
    return errors:get(errors:size() - 1) .. "\n\n" .. errors:get(errors:size() - 2)
end

function AsyncTest:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.___IS_ASYNC_TEST___ = true
    o.steps = {}
    o._finallyCallbacks = {}

    return o
end

function AsyncTest.renderTest(uiElement)
    return AsyncTest.assertFunctionWasCalled(uiElement, "render")
end

function AsyncTest.prerenderTest(uiElement)
    return AsyncTest.assertFunctionWasCalled(uiElement, "prerender")
end

function AsyncTest.assertFunctionWasCalled(obj, functionName)
    local success = false
    local og_func = obj[functionName]

    if not og_func then
        error("Object does not have function " .. functionName)
    end

    obj[functionName] = function(...)
        og_func(...)
        success = true
    end

    local asyncTest = AsyncTest:new()
        :next(function() end)
        :next(function()
            if not success then
                error("Function " .. functionName .. " was not called")
            end
        end)
        :finally(function()
            obj[functionName] = og_func
        end)

    return asyncTest
end

function AsyncTest:pass()
    self.completed = true
    self.results = {
        passed = true
    }
end

function AsyncTest:fail()
    self.completed = true
    self.results = {
        passed = false,
        error = getMostRecentError()
    }
end

function AsyncTest:tick()
    local timestamp = getTimestampMs()
    if self.lastTime == nil then
        self.lastTime = timestamp
    end
 
    local dt = timestamp - self.lastTime
    self.lastTime = timestamp

    if not self.currentStep then
        self.currentStep = 1
    end
    if self.currentStep > #self.steps then
        self:pass()
        return
    end

    local step = self.steps[self.currentStep]
    if step.type == NEXT then
        local success, err = pcall(step.callback)
        if not success then
            self:fail()
            return
        end
        self.currentStep = self.currentStep + 1
        return
    end

    if step.type == WAIT then
        step.time = step.time - dt
        if step.time <= 0 then
            self.currentStep = self.currentStep + 1
        end
        return
    end

    if step.type == REPEAT_UNTIL then
        local success, ret = pcall(step.callback)
        if success and ret then
            self.currentStep = self.currentStep + 1
        elseif not success then
            self:fail()
        else
            step.autoFailTime = step.autoFailTime - dt
            if step.autoFailTime <= 0 then
                self:fail()
            end
        end
        return
    end
end

function AsyncTest:next(callback)
    local step = {
        type = NEXT,
        callback = callback
    }
    table.insert(self.steps, step)
    return self
end

function AsyncTest:wait(time)
    local step = {
        type = WAIT,
        time = time
    }
    table.insert(self.steps, step)
    return self
end

function AsyncTest:repeatUntil(callback, autoFailTime)
    if not autoFailTime then
        autoFailTime = 10000
    end

    local step = {
        type = REPEAT_UNTIL,
        callback = callback,
        autoFailTime = autoFailTime
    }
    table.insert(self.steps, step)
    return self
end

function AsyncTest:finally(callback)
    table.insert(self._finallyCallbacks, callback)
    return self
end

function AsyncTest:runFinally()
    for _, callback in ipairs(self._finallyCallbacks) do
        pcall(callback)
    end
end

return AsyncTest
