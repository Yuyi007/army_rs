# Client.rb

require 'rubygems'
require 'eventmachine'
require 'socket'
require 'json'
require 'zlib'

module Boot

  class LoadUser

    attr_accessor :email, :pass, :zone

    def initialize(email, pass, zone)
      @email = email
      @pass = pass
      @zone = zone
    end

  end

  class LoadUserFactory

    def initialize(zone, startIndex)
      @zone = zone
      @index = startIndex
    end

    def make_user
      user = LoadUser.new("loadtest#{@index}@fv.com", '699b25911d3c3db7fb72b6501c26a6bf', @zone)
      @index += 1
      user
    end

  end

  class LoadClient < EventMachine::Connection

    include LoadClientRpc

    def self.init(queue, userFactory, testFactory, options)
      @@queue = queue
      @@userFactory = userFactory
      @@testFactory = testFactory

      @@options = options
      @@connection_only = options[:connection_only]
      @@idle = options[:idle]
      @@encoding = options[:encoding]
      @@server_encoding = options[:server_encoding]
    end

    def initialize
      @recv_buf = ''
      @requests = 0
      @totalDelay = 0
      @number = 1
    end

    def options
      @@options
    end

    def post_init
      @user = @@userFactory.make_user
      @test = @@testFactory.make_test self

      if @@idle > 0
        EventMachine.add_timer(@@idle) { on_start }
      else
        on_start
      end
    end

    def connection_completed
      @connected = true
    end

    def close_connection(*args)
      @intentionallyClosed = true
      super(*args)
    end

    def close_connection_after_writing(*args)
      @intentionallyClosed = true
      super(*args)
    end

    def unbind
      if not @connected
        on_error 'not connected'
      else
        on_error 'closed' unless @intentionallyClosed
      end
    end

    def receive_data data
      @recv_buf += data
      packets = []
      while true
        packet = $boot_config.game_packet_format.new
        packet.parse! @recv_buf, codec_state
        break if not (packet.complete?)
        packets << packet
      end

      packets.each do |packet|
        if packet.t < 1000 then
          @requests += 1
          @totalDelay += Time.now - @lastReqBeginTime
        end

        on_message_received packet.t, packet.msg
      end
    end

    def send_client_message(type, msg)
      packet = $boot_config.game_packet_format.new
      packet.n = @number
      packet.t = type
      packet.msg = msg

      send_data packet.to_wire packet.e, codec_state

      @number += 1
      @lastReqBeginTime = Time.now
    end

    def codec_state
      @@codec_state ||= CodecState.new
    end

    ##############

    def on_start
      if not @@connection_only
        if @test.respond_to?(:on_start)
          @test.on_start
        else
          rpc_update @@server_encoding
          #rpc_login(@user.email, @user.pass, @user.zone)
        end
      else
        on_finished
      end
    end

    def on_finished
      close_connection
      @@queue.push({
        :requests => @requests,
        :totalDelay => @totalDelay,
        :status => :finished
      })
    end

    def on_error message
      close_connection
      @@queue.push({
        :requests => @requests,
        :totalDelay => @totalDelay,
        :message => message,
        :status => :error
      })
    end

    def on_timeout
      close_connection
      @@queue.push({
        :requests => @requests,
        :totalDelay => @totalDelay,
        :status => :timeout
      })
    end

  end

end
