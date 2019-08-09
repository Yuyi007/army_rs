# server.rb
# Main Server class, for running standalone as game server

require 'socket'

module Boot

  # The general game server class
  class GameServer < EventMachine::Connection

    MAX_BATCH_NUM = 30

    include Loggable
    include Statsable

    attr_reader :session, :remote_ip, :peer_id, :local_id, :delegate

    @@servers ||= {}
    @@init_counter ||= 0
    @@packet_processing ||= 0

    def self.reload
      # nothing to do here
    end

    def self.server_count
      @@servers.length
    end

    def self.close_all_servers
      @@servers.dup.each { |peer_id, server| server.close_connection }
    end

    def self.session_count
      server_count
    end

    def self.disconnect_session(id, zone)
      session = SessionManager.get(id, zone)
      session.server.close_connection if session
    end

    def self.disconnect_all_sessions
      close_all_servers
    end

    def self.packet_processing
      @@packet_processing
    end

    def initialize
      @remote_ip = ''
      @peer_id = '<unknown>'
      @local_id = '<unknown>'
      @recv_buf = ''
      @session = nil
      @delegate = $boot_config.connection_delegate
      @queue = ServerQueue.new
    end

    def post_init
      d{ ">>>>>>>post_init on_connect" }
      queue_event { on_connect }
    end

    def unbind
      d{ ">>>>>>>unbind on_unbind" }
      queue_event { on_unbind }
    end

    def receive_data data
      queue_event do
        @@packet_processing += 1
        begin
          on_receive_data(data)
        ensure
          @@packet_processing -= 1
        end
      end
    end

    def push_message(session, msg, type)
     if session.is_a? DefaultSession
        raise "invalid session!" unless session == @session
        codec_state = session.codec_state
        raw, encoding = ServerEncoding.encode(msg, session.encoding, codec_state)
        # puts ">>>>>session.encoding:#{session.encoding} encoding:#{encoding} raw:#{raw}"
        # e = codec_state.encoding
        self.send_data [ raw.bytesize + 7, 0, type, encoding, raw ].pack('NNnCa*')
      else
        raise "invalid session arg!"
      end

      d{ ">> push to #{@peer_id} #{session.player_id} t=#{type} e=#{session.encoding} len=#{raw.bytesize} #{msg}" }
    end

  private

    def queue_event &blk
      @queue.submit &blk
    end

    def on_connect
      @@init_counter += 1
      begin
        remote_addr = Socket.unpack_sockaddr_in(get_peername)
        @remote_ip = remote_addr[1] if remote_addr and remote_addr.length > 1
        @peer_id = "<#{remote_addr.join(':')}>"
      rescue
        @peer_id = "<unknown-#{@@init_counter}>"
      end
      @local_id = "<#{Socket.unpack_sockaddr_in(get_sockname).join(':')}>" rescue get_sockname

      info "-- #{@peer_id} connected with #{@local_id}"
      @@servers[@peer_id] = self
      @session = @delegate.create_session(@peer_id, self)

      stats_gauge_local "server.connections", @@servers.length
    end

    def on_unbind
      stats_time_redis_local 'server.unbind' do
        process_unbind
      end
    end

    def on_receive_data data
      stats_time_redis_local 'server' do
        process_data data
      end
    end

    def process_unbind
      info "-- #{@peer_id} disconnected with #{@local_id}"
      @@servers.delete @peer_id

      begin
        @delegate.unbind(self, session)
      rescue => e
        error("Unbind Error for #{peer_id} #{session.player_id} #{session.zone}", e)
      ensure
        stats_gauge_local "server.connections", @@servers.length
      end
    end

    def process_data data
      begin
        # after sending the response of this handler, we set nonce to the new nonce
        session.codec_state = session.codec_state_next if !session.codec_state_next.nil?

        @recv_buf += data
        packets = [ ]
        while packets.length < MAX_BATCH_NUM
          packet = $boot_config.game_packet_format.new
          packet.parse! @recv_buf, session.codec_state
          break if not (packet.complete? and packet.valid?)
          packets << packet
          info "<< message from #{@peer_id} #{@session.player_id} #{packet.to_s} #{packet.msg}"
        end

        Dispatcher.dispatch(self, @session, packets).each do |res_packet|
          send_data res_packet.wire_str

          info ">> sending to #{@peer_id} #{@session.player_id} #{res_packet.to_s}"
          @delegate.on_send_success(self, @session, res_packet)
        end if packets.length > 0
      rescue => err
        error("Server Error for #{@peer_id} #{@session.player_id} #{@session.zone}: ", err)
        stats_increment_local "server.error"
      end
    end

  end

end