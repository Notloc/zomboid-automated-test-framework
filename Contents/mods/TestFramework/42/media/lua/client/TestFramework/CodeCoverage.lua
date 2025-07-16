if not ___GLOBAL_CODE_COVERAGE___ then
    local CodeCoverage = {}
    ___GLOBAL_CODE_COVERAGE___ = CodeCoverage

    CodeCoverage.overrideFunctions = {}
    CodeCoverage.originalFunctions = {}
    CodeCoverage.coverageTable = {}
    CodeCoverage.namesByTable = {}

    function CodeCoverage.hook(targetName, targetTable, ignoreInherited)
        if not CodeCoverage.overrideFunctions[targetTable] then
            CodeCoverage.overrideFunctions[targetTable] = {}
        end
        if not CodeCoverage.originalFunctions[targetTable] then
            CodeCoverage.originalFunctions[targetTable] = {}
        end
        if not CodeCoverage.coverageTable[targetTable] then
            CodeCoverage.coverageTable[targetTable] = {}
        end

        CodeCoverage.namesByTable[targetTable] = targetName
        local metatable = getmetatable(targetTable)
        ignoreInherited = ignoreInherited and metatable ~= nil

        for name, func in pairs(targetTable) do
            if type(func) == "function" then
                local skip = ignoreInherited and metatable[name] == func
                if not skip and not CodeCoverage.originalFunctions[targetTable][name] then
                    CodeCoverage.originalFunctions[targetTable][name] = func
                    targetTable[name] = CodeCoverage.wrap(targetTable, func, name)
                    CodeCoverage.overrideFunctions[targetTable][name] = targetTable[name]
                end
            end
        end
    end

    function CodeCoverage.wrap(targetTable, originalFunc, name)
        CodeCoverage.coverageTable[targetTable][name] = false
        local wrapped = function (...)
            CodeCoverage.coverageTable[targetTable][name] = true
            return originalFunc(...)
        end
        return wrapped
    end

    function CodeCoverage.unhook(targetTable)
        if not CodeCoverage.overrideFunctions[targetTable] then
            return
        end

        for name, func in pairs(targetTable) do
            if type(func) == "function" then
                if CodeCoverage.overrideFunctions[targetTable][name] then
                    targetTable[name] = CodeCoverage.originalFunctions[targetTable][name]
                    CodeCoverage.overrideFunctions[targetTable][name] = nil
                    CodeCoverage.originalFunctions[targetTable][name] = nil
                end
            end
        end
    end

    CodeCoverage.clearCoverage = function ()
        for targetTable, name  in pairs(CodeCoverage.coverageTable) do
            CodeCoverage.coverageTable[targetTable] = {}
        end
    end
end

return ___GLOBAL_CODE_COVERAGE___
