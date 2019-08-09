local unpack = rawget(table, "unpack") or unpack
skynet = require "skynet"
declare("LOG_EMERG",	0)
declare("LOG_ALERT",	1)
declare("LOG_CRIT",	2)
declare("LOG_ERR",	3)
declare("LOG_WARNING",	4)
declare("LOG_NOTICE",	5)
declare("LOG_EMERG",	6)
declare("LOG_DEBUG",	7)
-- LOG_ALERT	1	/* action must be taken immediately */
-- LOG_CRIT	2	/* critical conditions */
-- LOG_ERR		3	/* error conditions */
-- LOG_WARNING	4	/* warning conditions */
-- LOG_NOTICE	5	/* normal but significant condition */
-- LOG_INFO	6	/* informational */
-- LOG_DEBUG	7	/* debug-level messages */

local function ensureStrings(array)
  for i = 1, #array do local v = array[i]
    array[i] = tostring(v)
  end
  return array
end

local function print_syslog(...)
	local arg = ensureStrings{...}
	skynet.syslog(LOG_DEBUG, unpack(arg))
end

local use_syslog = (skynet.getenv("syslog") == "true")
if use_syslog then
	print = print_syslog
end

