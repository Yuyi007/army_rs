# ServerEncoding.rb

require 'msgpack'
require 'json'
require 'oj'
require 'zlib'
require 'lz4-ruby'
require 'openssl'
require 'digest'
require 'rbnacl'

module Boot

  class CodecState

    attr_accessor :nonce

    def initialize nonce = nil
      @nonce = nonce || ServerEncoding.comm_nonce
    end

  end

  # Encodings
  ######################
  # Wire definitions
  # 0 - plain json
  # 1 - deflated json
  # 2 - encrypted json
  # 3 - encrypted deflated json
  # 4 - plain msgpack
  # 5 - deflated msgpack
  # 6 - encrypted msgpack
  # 7 - encrypted deflated msgpack
  #
  class ServerEncoding

    GZIP_THRESHOLD = 128 unless defined? GZIP_THRESHOLD

    include Loggable

    def self.rc4_key
      if defined? @@rc4_key then return @@rc4_key end
      @@rc4_key = AppConfig.server.rc4_key.pack('c*')
    end

    def self.comm_key
      if defined? @@comm_key then return @@comm_key end
      @@comm_key = AppConfig.server.comm_key.pack('c*')
    end

    def self.comm_nonce
      if defined? @@comm_nonce then return @@comm_nonce end
      @@comm_nonce = AppConfig.server.comm_nonce.pack('c*')
    end

    def self.bi_nonce
      if defined? @@bi_nonce then return @@bi_nonce end
      @@bi_nonce = AppConfig.server.broadcast_nonce.pack('c*')
    end

    def self.secret_box
      if defined? @@secret_box then return @@secret_box end
      @@secret_box = RbNaCl::SecretBox.new(comm_key)
    end

    def self.decrypt text, nonce = nil
      secret_box.decrypt(nonce || comm_nonce, text)
    end

    def self.encrypt text, nonce = nil
      secret_box.encrypt(nonce || comm_nonce, text)
    end

    def self.decrypt_rc4 text, key = nil
      c = OpenSSL::Cipher.new('rc4')
      c.decrypt
      c.key = key || rc4_key
      c.update(text) << c.final
    end

    def self.encrypt_rc4 text, key = nil
      c = OpenSSL::Cipher.new('rc4')
      c.encrypt
      c.key = key || rc4_key
      c.update(text) << c.final
    end

    def self.compress text
      LZ4::Fixed.compress text
    end

    def self.uncompress text
      LZ4::Fixed.uncompress text
    end

    def self.decode(data, encoding, codec_state)
      encoding = self.convert_encoding(encoding)
      nonce = codec_state.nonce

      case encoding
      when 8
        # return as is
        msg = data
      when 7
        # deflated msgpack
        decrypted = self.decrypt data, nonce
        deflated = self.uncompress decrypted
        #d{ "-- before inflate #{encoding}: #{data.bytesize} after: #{deflated.bytesize}" }
        msg = MessagePack.unpack(deflated)
      when 6
        # encrypted msgpack
        decrypted = self.decrypt data, nonce
        msg = MessagePack.unpack(decrypted)
      when 5
        # deflated msgpack
        deflated = self.uncompress data
        d{ "-- before inflate #{encoding}: #{data.bytesize} after: #{deflated.bytesize}" }
        msg = MessagePack.unpack(deflated)
      when 4
        # plain msgpack
        msg = MessagePack.unpack data
      when 3
        # encrypted deflated json
        decrypted = self.decrypt data, nonce
        deflated = self.uncompress decrypted
        d{ "-- before enc inflate #{encoding}: #{data.bytesize} after: #{deflated.bytesize}" }
        msg = Oj.strict_load(deflated)
      when 2
        # encrypted json
        decrypted = self.decrypt data, nonce
        msg = Oj.strict_load(decrypted)
      when 1
        # deflated json
        deflated = self.uncompress data
        d{ "-- before inflate #{encoding}: #{data.bytesize} after: #{deflated.bytesize}" }
        msg = Oj.strict_load(deflated)
      else
        # plain json
        msg = Oj.strict_load(data)
      end

      msg
    end

    def self.encode(msg, encoding, codec_state)
      encoding = self.convert_encoding(encoding)
      nonce = codec_state.nonce

      case encoding
      when 8
        # return as is
        data = msg
      when 7
        # encrypted deflated msgpack
        pack = MessagePack.pack(msg)
        deflated = self.compress pack
        data = self.encrypt deflated, nonce
        d{ "-- before deflate #{encoding}: #{pack.bytesize} after: #{data.bytesize}" }
      when 6
        # encrypted msgpack
        pack = MessagePack.pack(msg)
        data = self.encrypt pack, nonce
        d{ "-- before deflate #{encoding}: #{pack.bytesize} after: #{data.bytesize}" }
      when 5
        # deflated msgpack
        pack = MessagePack.pack(msg)
        data = self.compress pack
        d{ "-- before deflate #{encoding}: #{pack.bytesize} after: #{data.bytesize}" }
      when 4
        # plain msgpack
        data = MessagePack.pack(msg)
      when 3
        # encrypted deflated json
        json = JSON.generate(msg)
        deflated = self.compress json
        data = self.encrypt deflated, nonce
        d{ "-- before enc deflate #{encoding}: #{json.bytesize} after: #{data.bytesize}" }
      when 2
        # encrypted json
        json = JSON.generate(msg)
        data = self.encrypt json, nonce
        d{ "-- before enc #{encoding}: #{json.bytesize} after: #{data.bytesize}" }
      when 1
        # deflated json
        json = JSON.generate(msg)
        data = self.compress json
        d{ "-- before deflate #{encoding}: #{json.bytesize} after: #{data.bytesize}" }
      when 0
        # plain json
        data = JSON.generate(msg)
      when 'msgpack-auto'
        # encrypted (deflated) msgpack
        pack = MessagePack.pack(msg)
        if pack.length > GZIP_THRESHOLD
          encoding = 7
          # data = self.encrypt pack, nonce
          deflated = self.compress pack
          data = self.encrypt deflated, nonce
          d{ "-- before deflate #{encoding}: #{pack.bytesize} after: #{data.bytesize}" }
        else
          encoding = 6
          data = self.encrypt pack, nonce
        end
      when 'json-auto'
        # encrypted (deflated) json
        json = JSON.generate(msg)
        if json.length > GZIP_THRESHOLD
          encoding = 3
          deflated = self.compress json
          data = self.encrypt deflated, nonce
          d{ "-- before deflate #{encoding}: #{json.bytesize} after: #{data.bytesize}" }
        else
          encoding = 2
          data = self.encrypt json, nonce
        end
      else
        # choose wisely
        json = JSON.generate(msg)
        if json.length > GZIP_THRESHOLD
          encoding = 1
          data = self.compress json
          d{ "-- before deflate #{encoding}: #{json.bytesize} after: #{data.bytesize}" }
        else
          encoding = 0
          data = json
        end
      end

      return data, encoding
    end

    def self.convert_encoding(encoding)
      case encoding
      when 'json'
        0
      when 'json_lz4'
        1
      when 'json_enc'
        2
      when 'json_lz4_enc'
        3
      when 'msgpack'
        4
      when 'msgpack_lz4'
        5
      when 'msgpack_enc'
        6
      when 'msgpack_lz4_enc'
        7
      when 'none'
        8
      else
        encoding
      end
    end

  end

end
