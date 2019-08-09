local lz4 = _G['lz4']

local str_3B = '123'
local str_8B = '12345678'
local str_64B = string.rep(str_8B, 8)
local str_64KB = string.rep(str_64B, 1024)
local str_128KB = string.rep(str_64KB, 2)
local str_149KB = string.rep(str_3B, 7 * 1024).. str_128KB
local str_256KB = string.rep(str_128KB, 2)
local str_1280KB = string.rep(str_256KB, 5)
local str_5120KB = string.rep(str_1280KB, 4)

local datum = {
   'a list string',
   "0",
   "11",
   "222",
   "1234",
   "12345",
   "123456",
   "1234567",
   "12345678",
   "123456789",
   "1234567890",
   "University of Science and Technology of China; Peking University",
   "University of Science and Technology of China; Peking University; Peking University",
   "Zhejiang University; National University of Singapore; ",
   "Nanyang Technological University; Tokyo University; 123456",
   "Zhejiang University; National University of Singapore; 123456",
   "Nanyang Technological University; Tokyo University; 123456",
   "asdlfkwekwerewrkewrawe,rmwaer,ewarwrewr,ewrcspd230e23932",
   "asdlfkwekwerewrkewrawe,rmwaer,ewarwrewr,ewrcspd230e23932",
   "asdlfkwekwerewrkewrawe,rmwaer,ewarwrewr,ewrcspd230e23932",
   str_64KB,
   str_128KB,
   str_149KB,
   str_256KB,
   str_1280KB,
   str_5120KB,
}

-- test compressing and decompressing

local stream = lz4.create_stream()
local stream_decode = lz4.create_stream_decode()

assert('userdata' == type(stream))
assert('userdata' == type(stream_decode))

for i = 1, #datum do local data = datum[i]
   local compressed1 = lz4.compress(data)
   local data1 = lz4.decompress(compressed1)
   assert(data == data1)

   local compressed2 = lz4.compress_stream(stream, data)
   local data2, err = lz4.decompress_stream(stream_decode, compressed2)
   assert(data == data2)

   logd("[%d] LZ4 original=%d normal=%d stream=%d", i, string.len(data),
      string.len(compressed1), string.len(compressed2))
end

-- test handle invalid input

local function assert_fail(func, msg)
   local ok, err = pcall(func)
   logd("assert_fail: ok=%s err=%s", inspect(ok), inspect(err))
   assert(not ok)
   if msg then assert(err == msg) end
end

local function assert_error(func, msg)
   local ok, err = func()
   logd("assert_error: ok=%s, err=%s", inspect(ok), inspect(err))
   assert(ok == nil)
   if msg then assert(err == msg) end
end

for _, invalid_stream in pairs({a='nil', b=0, c='a'}) do
   logd("test handle invalid stream...")
   if invalid_stream == 'nil' then invalid_stream = nil end
   assert_fail(function () return lz4.compress_stream(invalid_stream, "") end)
   assert_fail(function () return lz4.decompress_stream(invalid_stream, "asdf") end)
   assert_fail(function () return lz4.free_stream(invalid_stream) end)
   assert_fail(function () return lz4.free_stream_decode(invalid_stream) end)
end

for _, invalid_data in pairs({a='nil', c=cjson.null}) do
   logd("test handle invalid data...")
   if invalid_data == 'nil' then invalid_data = nil end
   assert_fail(function () return lz4.compress(invalid_data) end)
   assert_fail(function () return lz4.decompress(invalid_data) end)
   assert_fail(function () return lz4.compress_stream(stream, invalid_data) end)
   assert_fail(function () return lz4.decompress_stream(stream_decode, invalid_data) end)
end

for _, invalid_data in pairs({a=0, b='12', c='123', d='1234'}) do
   logd("test handle decompress string that's too short")
   assert_error(function () return lz4.decompress(invalid_data) end)
   assert_error(function () return lz4.decompress_stream(stream_decode, invalid_data) end)
end

-- free streams

assert(true == lz4.free_stream(stream))
assert(true == lz4.free_stream_decode(stream_decode))

print "LZ4Test OK"
