-----------------------------------------------------------------------------
-- Socket dns utils
-- Author: Lei Ting
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module
-----------------------------------------------------------------------------
local base = _G
local string = require("string")
local table = require("table")
local math = require("math")
local dns = require 'lboot/net/dns/dns'

package.loaded['socket.dns2'] = nil
module("socket.dns2", package.seeall)

-----------------------------------------------------------------------------
-- Module version
-----------------------------------------------------------------------------
_VERSION = "DNS2 0.0.1"

server_list = { '8.8.8.8', '8.8.4.4' }
name_cache = {}

local function log(msg)
  base.logd(msg)
end

-- resolve with cache
function toip(domain)
  if name_cache[domain] then
    return name_cache[domain]
  else
    local ip = resolve(domain)
    name_cache[domain] = ip
    return ip
  end
end

-- clear the name cache
function clear_cache()
  name_cache = {}
end

-- resolve domain name to ip
function resolve(domain)
  local resolver = dns.resolver()
  for _, server in base.ipairs(server_list) do
    resolver:addnameserver(server)
  end

  log('resolving ' .. base.tostring(domain) .. '...')
  for _, t in base.ipairs({ 'A', 'CNAME' }) do
    -- local ok, rrs = true, resolver:lookup(domain, t)
    local ok, rrs = base.pcall(function () return resolver:lookup(domain, t) end)
    if ok then
      if rrs then
        local num = #rrs
        log('resolving ' .. base.tostring(t) .. ' record success, records=' .. num)
        if num > 0 then
          local record = rrs[math.random(1, num)]
          if record.a then
            return record.a
          elseif record.cname then
            return resolve(record.cname)
          else
            log('no valid result found in record')
          end
        end
      end
    else
      log('an error happened when resolving, message is ' .. base.tostring(rrs))
    end
  end

  return nil
end