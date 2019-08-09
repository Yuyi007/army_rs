-- lboot.lua

--[[

  The Foundation library
  To be required by app init

--]]

require 'lboot/lib/functions/fun'()
require 'lboot/lib/functions/functions'
require 'lboot/lib/functions/functions_io'
require 'lboot/lib/functions/functions_log'
require 'lboot/lib/functions/functions_math'
require 'lboot/lib/functions/functions_table'
require 'lboot/lib/functions/functions_string'
require 'lboot/lib/functions/functions_debug'
require 'lboot/lib/functions/functions_engine'
require 'lboot/lib/ProfileSampler'
require 'lboot/lib/luaj'
require 'lboot/lib/luaoc'
require 'lboot/lib/luacs'
require 'lboot/lib/Stats'
require 'lboot/lib/LuaList'
require 'lboot/lib/LRUCache'
require 'lboot/lib/Signal'
require 'lboot/lib/Pool'
require 'lboot/lib/scheduler'
require 'lboot/lib/jsonable'
-- require 'lboot/ext/luabit'
-- require 'lboot/ext/arcfour'
-- require 'lboot/ext/msgpack'
-- require 'lboot/ext/json'
-- require 'lboot/ext/md5'
-- require 'lboot/ext/ilua'
-- require 'lboot/ext/re'
-- require 'lboot/ext/sor'
-- require 'lboot/ext/fix16'
-- require 'lboot/ext/vector'
-- require 'lboot/ext/vector16'
-- require 'lboot/ext/fractor'
require 'lboot/ext/fractor_table'

require 'lboot/ext/inspect'
require 'lboot/ext/ProFi'
require 'lboot/ext/pepperfish_profiler'
require 'lboot/ext/luaprofiler_summary'
require 'lboot/ext/luatraverse'

-- this uses luabit, should go after luabit
require 'lboot/lib/functions/functions_bit'

-- let's play nice with our lua packager
-- requir-'lboot/ext/lua-pb/pb/standard'
-- requir-'lboot/ext/lua-pb/pb/proto/parser'
-- requir-'lboot/ext/lua-pb/pb'

require 'lboot/net/dns/dns'
require 'lboot/net/socket/dispatch'
require 'lboot/net/socket/dns2'
require 'lboot/net/socket/ftp'
require 'lboot/net/socket/http'
require 'lboot/net/socket/ltn12'
require 'lboot/net/socket/mime'
require 'lboot/net/socket/smtp'
require 'lboot/net/socket/socket'
require 'lboot/net/socket/tp'
require 'lboot/net/socket/url'
require 'lboot/net/socket/headers'
require 'lboot/net/packet/GenLongPacketFormat'
require 'lboot/net/packet/Packet'
require 'lboot/net/ClientEncoding'
require 'lboot/net/MsgEndpoint'
require 'lboot/net/CombatMessenger'
require 'lboot/net/VerifyMsgEncoding'

require 'lboot/update/UpdateManager'
require 'lboot/update/ObbHelper'
require 'lboot/update/ObbLocalUpdater'

require 'lboot/utils/LBootHelpers'
require 'lboot/utils/OsCommon'
require 'lboot/utils/VideoPlayer'
require 'lboot/utils/SqliteConfigFile'

