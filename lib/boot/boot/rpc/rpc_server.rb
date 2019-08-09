# rpc_server.rb
# RPC Server class, for used together with egg gate server

require 'socket'

module Boot

  # The general rpc server class
  class RpcServer < EventMachine::Connection

    include Loggable
    include Statsable

    attr_reader :remote_ip, :peer_id, :local_id, :delegate

    @@servers ||= {}
    @@init_counter ||= 0

    @@outgoing_number = 1
    @@max_outgoing_number = 65535

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
      SessionManager.num_connected_sessions
    end

    def self.disconnect_session(id, zone)
      session = SessionManager.get(id, zone)
      Rpc.cast(session.server, session, nil, 'disconnect_sessions', [session.id]) if session
    end

    def self.disconnect_all_sessions
      SessionManager.get_all_zones.each do |_, session|
        Rpc.cast(session.server, nil, nil, 'disconnect_sessions', [session.id])
      end
    end

    def self.packet_processing
      RpcDispatcher.packet_processing
    end

    def initialize
      @remote_ip = ''
      @peer_id = '<unknown>'
      @local_id = '<unknown>'
      @recv_buf = ''
      @delegate = $boot_config.connection_delegate
      @codec_state = CodecState.new
    end

    def post_init
      EM.synchrony { on_connect }
    end

    def unbind
      EM.synchrony { on_unbind }
    end

    def receive_data data
      EM.synchrony do
        begin
          on_receive_data(data)
        rescue => er
          error("Server Error: ", er)
        end
      end
    end

    def codec_state
      @codec_state
    end

    def send_rpc_packet(packet)
      packet.e = 'msgpack'
      packet.n = @@outgoing_number

      @@outgoing_number = @@outgoing_number + 1
      if @@outgoing_number > @@max_outgoing_number
        @@outgoing_number = @@outgoing_number % (@@max_outgoing_number - 1) + 1
      end

      self.send_data(packet.to_wire(packet.e, @codec_state))
    end

    def push_message(session, msg, type)
      if session.is_a? DefaultSession
      else
        raise "invalid session arg!"
      end

      bi_hash = BcastInfo.to_hash([session.id], msg, type)
      Rpc.cast(self, session, nil, 'broadcast',
        :session => session.id, :args => [ bi_hash ])

      d{ ">> push to #{session} t=#{type} #{msg}" }
    end

  private

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

      stats_gauge_local "server.connections", @@servers.length
    end

    def on_unbind
      stats_time_redis_local 'server.unbind' do
        process_unbind
      end
    end

    def on_receive_data data
      stats_time_redis_local 'server' do
        # Boot::Helper.flamegraph_rotate do
        #   process_data data
        # end
        process_data data
      end
    end

    def process_unbind
      info "-- #{@peer_id} disconnected with #{@local_id}"
      @@servers.delete @peer_id

      begin
      rescue => e
        error("Unbind Error for #{peer_id}", e)
      ensure
        stats_gauge_local "server.connections", @@servers.length
      end
    end

    def process_data data
      begin
        @recv_buf += data
        packets = [ ]

        while true do
          packet = $boot_config.rpc_packet_format.new
          packet.parse! @recv_buf, @codec_state
          break if not (packet.complete? and packet.valid?)
          packets << packet
          # info "<< message from #{@peer_id} #{packet.to_s} #{packet.msg}"
        end

        packets.each do |packet|
          if packet.t == 0
            RpcDispatcher.dispatch(self, packet, @codec_state) do |res_packet|
              if res_packet
                # info ">> sending to #{@peer_id} #{res_packet.to_s}"
                send_data res_packet.wire_str
                @delegate.on_send_success(self, nil, res_packet)
              end
            end
          elsif packet.t == 1
            Rpc::TcpBackend.handle_rpc_response(packet)
          else
            raise "invalid packet type: #{packet.t}"
          end
        end
      rescue => err
        error("Server Error for #{@peer_id}: ", err)
        stats_increment_local "server.error"
      end
    end

  end

end