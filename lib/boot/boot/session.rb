# session.rb
# An example to show the session

module Boot
  class DefaultSession
    attr_accessor :id # the session id
    attr_accessor :server # the server instance
    attr_accessor :encoding # the encoding type that the client supports
    attr_accessor :player_id, :zone
    attr_accessor :custom_data # custom data that can be used by boot modules
    attr_accessor :codec_state
    attr_accessor :last_active # last active time

    include Jsonable
    include RedisHelper

    def initialize(id, server)
      @id = id
      @server = server
      @player_id = '$noauth$'
      @zone = 0
      @custom_data = {}
      @codec_state = CodecState.new
    end
  end
end
