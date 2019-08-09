-- ClientEncoding.lua

local ClientEncoding = class("ClientEncoding", function (self)
end)

local zlib = require 'zlib'
local lz4 = _G['lz4']
local cmsgpack = _G['cmsgpack']
local lxyssl = _G['lxyssl']
local msgpack = nil
local crypto = nacl
local arcfour = require 'lboot/ext/arcfour'

local commKey, commNonce = nil, nil
local luaKey, luaIv = nil, nil

if cmsgpack then
  ccwarning('using msgpack native impl.')
  msgpack = cmsgpack
else
  ccwarning('cmsgpack not found, fallback to pure lua msgpack.')
  msgpack = require 'lboot/ext/msgpack'
end

if lxyssl then
  ccwarning('using encrypt native impl.')
else
  ccwarning('lxyssl not found, fallback to pure lua encrypt.')
end

logd('=== init client encoding ===')

function ClientEncoding.ensureCommKey()
  if not commKey then commKey, commNonce = getCommEncryptionKey() end
  return commKey, commNonce
end

function ClientEncoding.ensureLuaKey()
  if not luaKey then luaKey, luaIv = getLuaEncryptionKey() end
  return luaKey, luaIv
end

function ClientEncoding.decrypt(data, nonce)
  ClientEncoding.ensureCommKey()
  nonce = nonce or commNonce
  logd(">>>>nonce:%s", tostring(nonce))
  return crypto.secretbox_open(data, nonce, commKey)
  -- return ClientEncoding.encryptRc4(data)
end

function ClientEncoding.encrypt(data, nonce)
  ClientEncoding.ensureCommKey()
  nonce = nonce or commNonce
  -- -- local s = { string.unpack(nonce, 'c' .. string.len(nonce)) }
  -- -- logd('encrypt with nonce %s', peek(s))
  return crypto.secretbox(data, nonce, commKey)
  -- return ClientEncoding.encryptRc4(data)
end

function ClientEncoding.decryptRc4(text)
  ClientEncoding.ensureLuaKey()
  -- return arcfour.new(luaIv):cipher(text)
  return lxyssl.rc4(luaIv):crypt(text)
end

function ClientEncoding.encryptRc4(text)
  ClientEncoding.ensureLuaKey()
  -- return arcfour.new(luaIv):cipher(text)
  return lxyssl.rc4(luaIv):crypt(text)
end

function ClientEncoding.decryptAes256Cbc(text)
  ClientEncoding.ensureLuaKey()
  return lxyssl.aes(luaKey, 256):cbc_decrypt(text, luaIv)
end

function ClientEncoding.encryptAes256Cbc(text)
  ClientEncoding.ensureLuaKey()
  return lxyssl.aes(luaKey, 256):cbc_encrypt(text, luaIv)
end

function ClientEncoding.compress(text, stream)
  local res, err
  if stream then
    res, err = lz4.compress_stream(stream, text)
  else
    res, err = lz4.compress(text)
  end
  if res then
    -- ClientEncoding.debugCompressRate(text, res, 'compress')
    return res
  else
    error('ClientEncoding.compress error: ' .. tostring(err))
  end
end

function ClientEncoding.uncompress(text, streamDecode)
  local res, err
  if streamDecode then
    res, err = lz4.decompress_stream(streamDecode, text)
  else
    res, err = lz4.decompress(text)
  end
  if res then
    -- ClientEncoding.debugCompressRate(res, text, 'uncompress')
    return res
  else
    error('ClientEncoding.uncompress error: ' .. tostring(err))
  end
end

-- WARNING: for debug use only
-- try to compress data with normal and stream approach and print result
function ClientEncoding.debugCompressRate(text, streamResult, type)
  local original = string.len(text)
  local streamSize = string.len(streamResult)
  local rate1 = (original + 0.0) / string.len(lz4.compress(text))
  local rate2 = (original + 0.0) / streamSize

  -- this should not crash
  pcall(function ()
    local _, err = lz4.decompress(streamResult)
    -- logd('decompress err=%s', inspect(err))
  end)

  logd('debugCompressRate: %s original=%d after=%d normal=%.3f stream=%.3f',
    type, string.len(text), streamSize, rate1, rate2)
end

function ClientEncoding.encode(msg, encoding, codecState)
  encoding = encoding or game.encoding
  if encoding == 'msgpack-auto' then
    local e = 7 -- encrypted compressed msgpack
    local message = msgpack.pack(msg)
    local compressed = ClientEncoding.compress(message, codecState.stream)
    local data = ClientEncoding.encrypt(compressed, codecState.nonce)
    -- if game.debug > 0 then logd('encode: e=%d %s', e, tostring(cjson.encode(msg))) end
    return data, e
  elseif encoding == 'json-auto' then
    local e = 2 -- encrypted json
    local message = cjson.encode(msg)
    local data = ClientEncoding.encrypt(message, codecState.nonce)
    -- if game.debug > 0 then logd('encode: e=%d %s', e, tostring(cjson.encode(msg))) end
    return data, e
  elseif encoding == 'none' then
    local e = 8
    return msg, e
  else
    loge('ClientEncoding.encode: invalid encoding! %s', tostring(encoding))
  end
end

function ClientEncoding.decode(raw, encoding, codecState)
  encoding = ClientEncoding.convertEncoding(encoding)
  local nonce, streamDecode = codecState.nonce, codecState.streamDecode
  -- logd(">>>codecState：%s nonce:%s stream decode:%s", inspect(codecState), inspect(nonce), inspect(codecState.streamDecode))
  if encoding == 0 then
    -- 0: json
    return cjson.decode(raw)
  elseif encoding == 1 then
    -- 1: deflated json
    local inflated = ClientEncoding.uncompress(raw, streamDecode)
    return cjson.decode(inflated)
  elseif encoding == 2 then
    -- 2: encrypted json
    local decrypted = ClientEncoding.decrypt(raw, nonce)
    return cjson.decode(decrypted)
  elseif encoding == 3 then
    -- 3: encrypted deflated json
    local decrypted = ClientEncoding.decrypt(raw, nonce)
    local inflated = ClientEncoding.uncompress(decrypted, streamDecode)
    return cjson.decode(inflated)
  elseif encoding == 4 then
    -- 4: plain msgpack
    return msgpack.unpack(raw)
  elseif encoding == 5 then
    -- 5: deflated msgpack
    local inflated = ClientEncoding.uncompress(raw, streamDecode)
    return msgpack.unpack(inflated)
  elseif encoding == 6 then
    -- 6: encrypted msgpack
    local decrypted = ClientEncoding.decrypt(raw, nonce)
    local msg = msgpack.unpack(decrypted)
    -- if game.debug > 0 then ccwarning('decode: msg=' .. tostring(cjson.encode(msg))) end
    return msg
  elseif encoding == 7 then
    -- 7: encrypted deflated msgpack
    local decrypted = ClientEncoding.decrypt(raw, nonce)
    local inflated = ClientEncoding.uncompress(decrypted, streamDecode)
    local msg = msgpack.unpack(inflated)
    --if game.debug > 0 then ccwarning('2decode: msg=' .. tostring(cjson.encode(msg))) end
    return msg
  elseif encoding == 8 then
    return raw
  else
    ccwarning('decode: unknown encoding: %s', tostring(encoding))
  end
end

function ClientEncoding.convertEncoding(encoding)
  if encoding == 'json' then
    return 0
  elseif encoding == 'json_lz4' then
    return 1
  elseif encoding == 'json_enc' then
    return 2
  elseif encoding == 'json_lz4_enc' then
    return 3
  elseif encoding == 'msgpack' then
    return 4
  elseif encoding == 'msgpack_lz4' then
    return 5
  elseif encoding == 'msgpack_enc' then
    return 6
  elseif encoding == 'msgpack_lz4_enc' then
    return 7
  elseif encoding == 'none' then
    return 8
  else
    return encoding
  end
end

function ClientEncoding.createCodecState(nonce, withLZ4Streaming)
  if withLZ4Streaming then
    return {
      stream = lz4.create_stream(),
      streamDecode = lz4.create_stream_decode(),
      nonce = nonce or commNonce,
    }
  else
    return {
      nonce = nonce or commNonce,
    }
  end
end

function ClientEncoding.destroyCodecState(codecState)
  if codecState.stream then
    lz4.free_stream(codecState.stream)
    codecState.stream = nil
  end

  if codecState.stream_decode then
    lz4.free_stream_decode(codecState.streamDecode)
    codecState.stream_decode = nil
  end
end
