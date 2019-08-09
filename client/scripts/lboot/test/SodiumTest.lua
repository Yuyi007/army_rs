-- NOTE: lua-nacl we only partly implemented for libsodium
-- Currently only secretbox is fully tested
-- Others are not used, thus not *real* tested, use with care

local crypto = nacl

local message = "Miemie Hello"
local nonce = "abcdefghijklmnopqrstuvwx" -- 24 bytes
local key = "abcdefghijklmnopqrstuvwxyzabcdef" -- 32 bytes

logd("randombytes")
logd("=====================================================")
logd("randombytes %s", crypto.randombytes(crypto.box_NONCEBYTES):toHexString())
logd("-----------------------------------------------------")

logd("hash")
logd("=====================================================")
logd("hash_BYTES %d", crypto.hash_BYTES)
logd("hash_primitive %s", crypto.hash_primitive())
logd("hash %s", crypto.hash(message):toHexString())
logd("-----------------------------------------------------")

logd("box")
logd("=====================================================")
logd("box_PUBLICKEYBYTES %d", crypto.box_PUBLICKEYBYTES)
logd("box_SECRETKEYBYTES %d", crypto.box_SECRETKEYBYTES)
logd("box_NONCEBYTES %s", crypto.box_NONCEBYTES)
logd("box_BEFORENMBYTES %d", crypto.box_BEFORENMBYTES)
logd("box_PREFIXBYTES %d", crypto.box_PREFIXBYTES)
logd("box_primitive %s", crypto.box_primitive())

local pk, sk = crypto.box_keypair()
local shared = crypto.box_beforenm(pk, sk)
logd("box_keypair: public key %s", pk:toHexString())
logd("box_keypair: secret key %s", sk:toHexString())
logd("box_keypair: shared key %s", shared:toHexString())

local box = crypto.box(message, nonce, pk, sk)
local message2 = crypto.box_open(box, nonce, pk, sk)
logd("box %s -> %s(%d) -> %s", tostring(message), box:toIntegerString(),
  string.len(box), tostring(message2))
assert(message == message2)

local box = crypto.box_afternm(message, nonce, shared)
local message2 = crypto.box_open_afternm(box, nonce, shared)
logd("box using shared key %s -> %s(%d) -> %s", tostring(message), box:toIntegerString(),
  string.len(box), tostring(message2))
assert(message == message2)

logd("-----------------------------------------------------")

logd("scalar")
logd("=====================================================")
logd("scalarmult_BYTES %d", crypto.scalarmult_BYTES)
logd("scalarmult_SCALARBYTES %d", crypto.scalarmult_SCALARBYTES)
logd("-----------------------------------------------------")

logd("sign")
logd("=====================================================")
logd("sign_PUBLICKEYBYTES %d", crypto.sign_PUBLICKEYBYTES)
logd("sign_SECRETKEYBYTES %d", crypto.sign_SECRETKEYBYTES)
logd("sign_BYTES %d", crypto.sign_BYTES)
logd("sign_primitive %s", crypto.sign_primitive())
logd("-----------------------------------------------------")

logd("secretbox")
logd("=====================================================")
logd("secretbox_KEYBYTES %d", crypto.secretbox_KEYBYTES)
logd("secretbox_NONCEBYTES %d", crypto.secretbox_NONCEBYTES)
logd("secretbox_PREFIXBYTES %d", crypto.secretbox_PREFIXBYTES)
logd("secretbox_primitive %s", crypto.secretbox_primitive())

local box = crypto.secretbox(message, nonce, key)
local message2 = crypto.secretbox_open(box, nonce, key)
logd("secretbox %s -> %s(%d) -> %s", tostring(message), box:toIntegerString(),
  string.len(box), tostring(message2))
assert(message == message2)

logd("-----------------------------------------------------")

logd("stream")
logd("=====================================================")
logd("stream_KEYBYTES %d", crypto.stream_KEYBYTES)
logd("stream_NONCEBYTES %d", crypto.stream_NONCEBYTES)
logd("stream_primitive %s", crypto.stream_primitive())
logd("-----------------------------------------------------")

logd("onetimeauth")
logd("=====================================================")
logd("onetimeauth_KEYBYTES %d", crypto.onetimeauth_KEYBYTES)
logd("onetimeauth_BYTES %d", crypto.onetimeauth_BYTES)
logd("onetimeauth_primitive %s", crypto.onetimeauth_primitive())
logd("-----------------------------------------------------")

logd("auth")
logd("=====================================================")
logd("auth_KEYBYTES %d", crypto.auth_KEYBYTES)
logd("auth_BYTES %d", crypto.auth_BYTES)
logd("auth_primitive %s", crypto.auth_primitive())
logd("-----------------------------------------------------")
