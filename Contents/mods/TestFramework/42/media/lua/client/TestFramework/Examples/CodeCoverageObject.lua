-- Just an example of a class that we will test coverage for
local CodeCoverageObject = {}

function CodeCoverageObject.method1()
end

function CodeCoverageObject.method2()
end

function CodeCoverageObject.method3()
end

function CodeCoverageObject.method4()
    CodeCoverageObject.method5()
end

function CodeCoverageObject.method5()
end

return CodeCoverageObject
