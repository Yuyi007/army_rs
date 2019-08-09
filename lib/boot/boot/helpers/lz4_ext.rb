require 'lz4-ruby'

# Extend lz4-ruby
class LZ4

  # Use a fixed header (uint32_t)
  class Fixed

    def self.compress(input, in_size = nil)
      return _compress(input, in_size, false)
    end

    def self.compressHC(input, in_size = nil)
      return _compress(input, in_size, true)
    end

    def self.decompress(input, in_size = nil, encoding = nil)
      in_size = input.bytesize if in_size == nil
      out_size = input.unpack('N')[0]

      if out_size < 0
        raise "Compressed data is maybe corrupted: out_size=#{out_size}"
      end

      result = LZ4Internal::uncompress(input, in_size, 4, out_size)
      result.force_encoding(encoding) if encoding != nil

      return result
    end

    # @deprecated Use {#decompress} and will be removed.
    def self.uncompress(input, in_size = nil)
      return decompress(input, in_size)
    end

    private
    def self._compress(input, in_size, high_compression)
      in_size = input.bytesize if in_size == nil
      header = [ in_size ].pack('N')

      if high_compression
        return LZ4Internal.compressHC(header, input, in_size)
      else
        return LZ4Internal.compress(header, input, in_size)
      end
    end

  end

end