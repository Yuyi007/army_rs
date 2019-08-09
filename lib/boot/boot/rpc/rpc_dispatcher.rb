
module Boot

  # Dispatch rpc requests to service handlers and process the requests
  class RpcDispatcher

    include Loggable
    include Statsable

    @@rpc_busy_result = [{'success' => false, 'reason' => 'server_busy'}, nil]
    @@server_error_result = [{'success' => false, 'reason' => 'server_error'}, nil]

    @@packet_processing ||= 0

    # Process the packet
    #
    # @param server [$boot_config.server] The game server instance
    # @param packets [$boot_config.game_packet_format] The incoming packet
    # @return [$boot_config.game_packet_format] The result packet
    def self.dispatch(server, packet, codec_state)
      msg = packet.msg
      mod = msg["module"].to_s
      func = msg["func"]
      args = msg["args"]

      raise "invalid args!" unless args

      # d{"handle rpc call: mod=#{mod} func=#{func} args=#{args}"}

      sid = args[0]
      if sid then
        session = self.get_session(sid, server)
        args[0] = session
      end

      if session
        session.rpc_queue.submit do
          yield handle_rpc(server, packet, codec_state, session, mod, func, args)
        end
      else
        yield handle_rpc(server, packet, codec_state, session, mod, func, args)
      end
    end

    def self.handle_rpc(server, packet, codec_state, session, mod, func, args)
      @@packet_processing += 1
      result = nil

      begin
        case func
        when 'handle_client_msg'
          sub_func = args[2]
        when 'handle_gate_event'
          sub_func = args[1]
        else
          sub_func = nil
        end

        # unbind should always be processed
        if is_busy? and sub_func != 'UnbindSession'
          result = @@rpc_busy_result
          if sub_func
            args_s = "#{session} #{sub_func}"
          else
            args_s = args
          end
          error("server busy: mod=#{mod} func=#{func} args=#{args_s} processing=#{@@packet_processing}")
          stats_increment_local "server.busy"
        elsif mod == '' or mod == 'Elixir.Egg.Rpc.Functions'
          result = Boot::RpcFunctions.send(func, *args, packet, server)
        else
          mod = mod.constantize
          result = mod.send(func, *args)
        end
      rescue => err
        error("Server Error for #{session}: ", err)
        stats_increment_local "server.error"
        result = @@server_error_result
      ensure
        res_packet = $boot_config.rpc_packet_format.new
        res_packet.n = packet.n
        res_packet.t = packet.t
        res_packet.msg = result

        res_packet.wire_str = res_packet.to_wire packet.e, codec_state

        stats_gauge_local "requests.output_size", res_packet.len
        if result
          res_data = result[0]
          if res_data && res_data['_handler_name']
            stats_gauge_local "handlers.#{res_data['_handler_name']}.output_size", res_packet.len
            res_data.delete('_handler_name')
          end
        end
      end

      @@packet_processing -= 1
      res_packet
    end

    def self.packet_processing
      @@packet_processing
    end

  private

    def self.is_busy?
      @@packet_processing > 80
    end

    def self.get_session(sid, server)
      session = SessionManager.get_by_sid(sid)
      if not session then
        delegate = $boot_config.connection_delegate
        session = delegate.create_session(sid, server)
        SessionManager.add_session(sid, session)
      else
        session.server = server
      end

      session.last_active = Time.now
      puts "[rpc active] session.last_active:#{session.last_active}"
      session
    end

  end

end