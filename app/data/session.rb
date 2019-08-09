# Session
#
# session can be optionaly stored in redis
# currently it's not
#

class RsSession < Boot::DefaultSession

  attr_accessor :server # the server instance
  attr_accessor :rpc_queue # the rpc queue
  attr_accessor :codec_state # the packet encoding codec state
  attr_accessor :codec_state_next #the next codec stat obj, replace last when next msg reach
  attr_accessor :remote_ip # the remote ip, as the client tells us
  attr_accessor :id, :player_id, :zone, :device_id
  attr_accessor :user_id # the login system raw user id
  attr_accessor :user_name # the login system raw user name
  attr_accessor :encoding # the encoding type that the client supports
  attr_accessor :data # custom data, hash of (composition of) basic types
  attr_accessor :access_token # the access token if OAuth is used
  attr_accessor :refresh_token # the refresh token if OAuth is used
  attr_accessor :platform, :sdk, :location
  attr_accessor :login_time # for session time stat
  attr_accessor :chat_channel_id # chat channel id
  attr_accessor :timezone
  attr_accessor :device_model, :device_mem, :gpu_model
  attr_accessor :facebook_id
  attr_accessor :queue_rank # queue rank of QueuingDb
  attr_accessor :gate # current gate server name
  attr_accessor :last_active # last active time

  # for broadcast control
  attr_accessor :broadcast_city

  attr_accessor :cur_inst_id
  attr_accessor :pid # instance.player_id

  # # for performance calculation
  # attr_accessor :last_recv_time, :last_sent_time,
  #   :last_dispatch_begin_time, :last_dispatch_end_time,
  #   :last_handle_begin_time, :last_handle_end_time,
  #   :last_dispatch_begin_redis_ops, :last_dispatch_end_redis_ops,
  #   :last_handle_begin_redis_ops, :last_handle_end_redis_ops

  def initialize(id, server)
    @id = id
    @server = server
    @rpc_queue = ServerQueue.new
    @player_id = '$noauth$'
    @zone = 0
    @custom_data = {}
    @data = {}
    @ipv4 = '127.0.0.1'
    @login_time = 0
    @chat_channel_id = 0
    @codec_state = CodecState.new
    @codec_state_next = nil
    @queue_rank = nil
    @last_active = Time.now
  end

  def logged_in?
    return @login_time > 0 && @queue_rank == nil
  end

  def to_s
    "<#{@id} #{@player_id}:#{@zone}>"
  end

  def device_model= model
    if model
      @device_model = model.gsub(',', '_')
    else
      @device_model = nil
    end
  end

  def gpu_model= model
    if model
      @gpu_model = model.gsub(',', '_')
    else
      @gpu_model = nil
    end
  end

  private

end
