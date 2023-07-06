local TestUtils = {}

TestUtils.newTestModule = function(filePath)
    local tests = {}

    if filePath then
        local extension = string.match(filePath, "%.(%w+)$")
        if not extension then
            filePath = filePath..".lua"
        end
    end

    tests._moduleData = {
        filePath = filePath
    }

    return tests
end

TestUtils.fail = function(message)
    if message then
        return error("Test Failed: "..message)
    else
        return error("Test Failed.")
    end
end

TestUtils.assert = function(val)
    if not val then
        return error("Assertion failed")
    end
end

TestUtils.assertString = function(val)
    if type(val) ~= "string" then
        return error("Assertion failed: Expected string, got "..type(val))
    end
end

TestUtils.assertTable = function(val)
    if type(val) ~= "table" then
        return error("Assertion failed: Expected table, got "..type(val))
    end
end

TestUtils.assertNumber = function(val)
    if type(val) ~= "number" then
        return error("Assertion failed: Expected number, got "..type(val))
    end
end

TestUtils.assertBoolean = function(val)
    if type(val) ~= "boolean" then
        return error("Assertion failed: Expected boolean, got "..type(val))
    end
end

TestUtils.assertFunction = function(val)
    if type(val) ~= "function" then
        return error("Assertion failed: Expected function, got "..type(val))
    end
end

TestUtils.assertNil = function(val)
    if val ~= nil then
        return error("Assertion failed: Expected nil, got "..type(val))
    end
end

return TestUtils