-- Copyright (c) 2021 PG1003
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to
-- deal in the Software without restriction, including without limitation the
-- rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
-- sell copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


local test = {}

local _total_checks  = 0
local _failed_checks = 0

local function _report_fail( ... )
    _failed_checks = _failed_checks + 1
    local msg         = string.format( ... )
    --local stack       = debug.traceback( msg, 3 )
    --local start, stop = string.find( stack, "[%s%c]+%C+run_test_modules" )
    print( msg )
end

function test.is_not_nil( value )
    _total_checks = _total_checks + 1
    if value == nil then
        _report_fail( "Is nil" )
        return false
    end
    return true
end

function test.is_nil( value )
    _total_checks = _total_checks + 1
    if value ~= nil then
        _report_fail( "Is not nil" )
        return false
    end
    return true
end

function test.is_true( value )
    _total_checks = _total_checks + 1
    if value ~= true then
        _report_fail( "Is not true" )
        return false
    end
    return true
end

function test.is_false( value )
    _total_checks = _total_checks + 1
    if value ~= false then
        _report_fail( "Is not false" )
        return false
    end
    return true
end

function test.is_same( value_1, value_2 )
    _total_checks = _total_checks + 1
    if value_1 ~= value_2 then
        _report_fail( "Not same; value 1: '%s', value 2: '%s'",
                      tostring( value_1 ), tostring( value_2 ) )
        return false
    end
    return true
end

function test.is_not_same( value_1, value_2 )
    _total_checks = _total_checks + 1
    if value_1 == value_2 then
        _report_fail( "Same; value 1: '%s', value 2: '%s'",
                      tostring( value_1 ), tostring( value_2 ) )
        return false
    end
    return true
end

function test.run_test_function(function_name, f)
    print( "Running test: " .. function_name )
    if f == nil then
        error("Test not found: " .. function_name)
    end
    _failed_checks = 0
    assert( type( f ) == "function" )
    f()
    if (_failed_checks ~= 0) then
        error("Test failed: " .. function_name)
    end
    print( "Test passed: " .. function_name )
end

function test.run_test_modules( test_modules )
    print( "Running tests..." )
    assert( type( test_modules ) == "table" )
    local total_tests  = 0
    local failed_tests = 0
    for module_, run in pairs( test_modules ) do
        if run then
            local tests = require( module_ )
            print( "-- " .. module_ .. " --" )
            for test, f in pairs( tests ) do
                local failed_checks_before_test = _failed_checks
                f()
                if _failed_checks > failed_checks_before_test then
                    failed_tests = failed_tests + 1
                end
                total_tests = total_tests + 1
            end
        end
    end
    print( "...tests completed" )

    local passed = _failed_checks == 0

    local summary = string.format( "-- Test summary --\n" ..
                                   "        Tests   Checks\n" ..
                                   "Total:  %5d   %6d\n" ..
                                   "Failed: %5d   %6d",
                                   total_tests, _total_checks,
                                   failed_tests, _failed_checks )
    print( summary )

    _total_checks  = 0
    _failed_checks = 0

    return passed
end

return test

