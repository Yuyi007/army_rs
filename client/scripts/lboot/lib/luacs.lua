--[[

Copyright (c) 2011-2014 firevale.com

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

--[[

luacs usage example:

  local luacs = require 'lboot/lib/luacs'
  local ok, result = luacs.callStaticMethod('MainPage', 'testLuaCSharpBridge', {
    string = 'string param',
    boolean = true,
    double = 3.1415926,
    callback1 = function (...)
      logd('enter callback 1')
      for i = 1, #arg do local v = arg[i]
        logd('callback 1 param ' .. tostring(i) .. ': ' .. tostring(v))
      end
    end,
    callback2 = function (...)
      logd('enter callback 2')
      for i = 1, #arg do local v = arg[i]
        logd('callback 2 param ' .. tostring(i) .. ': ' .. tostring(v))
      end
    end,
    callback3 = function (...)
      logd('enter callback 3')
      for i = 1, #arg do local v = arg[i]
        logd('callback 3 param ' .. tostring(i) .. ': ' .. tostring(v))
      end
    end
    })

  logd('call result ' .. tostring(result))

]]--

if not rawget(_G, 'CCLuaCSharpBridge') then
  return nil
end

local luacs = {}

local callStaticMethod = CCLuaCSharpBridge.callStaticMethod

--[[--

Call C# Class Method

### Parameters:

-   string **className** C# class name
-   string **methodName** Method name
-   [_optional table **args**_] Arguments pass to C#

### Returns:

-   boolean call success or failure
-   C# method returned value (a table)

]]
function luacs.callStaticMethod(className, methodName, args)
    if string.find(className, '.', 1, true) == nil then
        className = 'PhoneDirect3DXamlAppInterop.' .. className -- add the default namespace
    end
    local ok, ret = callStaticMethod(className, methodName, args)
    if not ok then
        local msg = string.format("luacs.callStaticMethod(\"%s\", \"%s\", \"%s\") - error: [%s] ",
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

return luacs