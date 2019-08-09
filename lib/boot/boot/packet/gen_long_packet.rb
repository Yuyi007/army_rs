module Boot

  # Representing a network packet used for client-server communication
  # Used with Egg
  #
  class GenLongPacket

=begin
  Wire format:
  -----------------------------------------------------------------------------
  |length | message_number | message_type | encoding_type |message_serialized |
  -----------------------------------------------------------------------------
  |   4   |      4         |       2      |       1       |    length - 7    |
  -----------------------------------------------------------------------------
=end

    include Loggable

    attr_accessor :len, :n, :t, :e, :msg, :data
    attr_accessor :wire_str

    def initialize
      @e = 'msgpack_enc'
    end

    def parse! buf, codec_state
      if buf.length == 0 then return end
      @len, @n, @t, @e, @data = buf.unpack('NNnCa*')

      if (len != nil and n != nil and t != nil and e != nil and data != nil and data.bytesize >= len - 7)
        @msg = ServerEncoding.decode(data[0, len - 7], e, codec_state)
        buf.slice!(0, len + 4)
      end
    end

    def to_wire encoding, codec_state
      encoding = encoding || @e
      # puts ">>>>>encoding:#{encoding}"
      @data, @e = ServerEncoding.encode(msg, encoding, codec_state)
      @len = @data.bytesize + 7
      [ @len, n, t, e, @data ].pack('NNnCa*')
    end

    def to_s
      "[len=#{len} n=#{n} t=#{t} e=#{e}]"
    end

    def complete?
      msg != nil
    end

    def valid?
      (e >= 2) # a valid packet must be encrypted
    end

  end

end