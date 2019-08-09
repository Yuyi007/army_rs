--[[

Copyright (c) 2011-2012 qeeplay.com

http://dualface.github.com/quick-cocos2d-x/

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

if not rawget(_G, 'CCLuaObjcBridge') then
    return nil
end

local luaoc = {}

local callStaticMethod = CCLuaObjcBridge.callStaticMethod

--[[--

Call Objective-C Class Method

### Parameters:

-   string **className** Objective-C class name
-   string **methodName** Method name
-   [_optional table **args**_] Arguments pass to Objective-C

### Returns:

-   boolean call success or failure
-   mixed Objective-C method returned value

]]
function luaoc.callStaticMethod(className, methodName, args)
    local ok, ret = callStaticMethod(className, methodName, args)
    if not ok then
        local msg = string.format("luaoc.callStaticMethod(\"%s\", \"%s\", \"%s\") - error: [%s] ",
                className, methodName, tostring(args), tostring(ret))
        if ret == -1 then
            loge(msg .. "INVALID PARAMETERS")
        elseif ret == -2 then
            loge(msg .. "CLASS NOT FOUND")
        elseif ret == -3 then
            loge(msg .. "METHOD NOT FOUND")
        elseif ret == -4 then
            loge(msg .. "EXCEPTION OCCURRED")
        elseif ret == -5 then
            loge(msg .. "INVALID METHOD SIGNATURE")
        else
            loge(msg .. "UNKNOWN")
        end
    end
    return ok, ret
end

return luaoc
