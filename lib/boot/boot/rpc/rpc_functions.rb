module Boot
  module RpcFunctions
    include Loggable

    unless const_defined? :LOG_MESSAGE_MAX_LENGTH
      LOG_MESSAGE_MAX_LENGTH = 800
    end

    def self.handle_client_packet(session, packet, _rpc_packet, server)
      handle_client_packet_with(session, packet, nil, server)
    end

    def self.handle_client_packet_with(session, packet, handler, _rpc_packet, server)
      delegate = $boot_config.rpc_dispatch_delegate
      codec_state = session.codec_state

      p = $boot_config.game_packet_format.new
      p.len = packet['len']
      p.n = packet['number']
      p.t = packet['type']
      p.e = packet['encoding']
      p.msg = ServerEncoding.decode(packet['data'], p.e, codec_state)

      if p.len > LOG_MESSAGE_MAX_LENGTH
        info "<< incoming #{session} #{p} long_content"
      else
        info "<< incoming #{session} #{p} #{p.msg}"
      end

      session = decorate_session(session)
      handler = handler.constantize if handler
      result, bi = ClientReqProcessor.dispatch(server, session, p, handler)

      # encoding is none here, so data is a Hash
      data, encoding = ServerEncoding.encode(result, p.e, codec_state)
      res_p = {
        'number' => p.n,
        'type' => p.t,
        'encoding' => encoding,
        'data' => data
      }

      success = result['success']
      if success == false then
        info ">> outgoing #{session} #{res_p} success=false reason=#{result['reason']}"
      else
        info ">> outgoing #{session} #{res_p} success=#{success}"
      end

      delegate.on_rpc_success session, res_p, result, bi

      [res_p, convert_broadcast_info(bi)]
    end

    def self.handle_client_msg(session, msg, handler, rpc_packet, server)
      delegate = $boot_config.rpc_dispatch_delegate
      # codec_state = session.codec_state

      p = $boot_config.game_packet_format.new
      p.len = rpc_packet.len
      p.n = rpc_packet.n
      p.t = rpc_packet.t
      p.e = rpc_packet.e
      p.msg = msg

      if p.len > LOG_MESSAGE_MAX_LENGTH
        info "<< incoming msg #{session} #{p} handler=#{handler} long_content"
      else
        info "<< incoming msg #{session} #{p} handler=#{handler} msg=#{p.msg}"
      end

      session = decorate_session(session)
      handler = handler.constantize if handler
      result, bi = ClientReqProcessor.dispatch(server, session, p, handler)

      success = result['success']
      if success == false then
        info ">> outgoing msg #{session} #{p} handler=#{handler} success=false reason=#{result['reason']}"
      else
        info ">> outgoing msg #{session} #{p} handler=#{handler} success=#{success}"
      end

      delegate.on_rpc_success session, nil, result, bi

      [result, convert_broadcast_info(bi)]
    end

    def self.handle_gate_event(session, event, _rpc_packet, _server)
      # delegate = $boot_config.connection_delegate
      # bi = nil

      info "<< incoming event #{session} #{event}"

      case event
      when 'close'
        # Do this in app layer instead, to ensure proper order with other requests
        # bi = delegate.unbind(server, session)
      end

      info ">> outgoing event response #{session}"

      # [convert_broadcast_info(bi)]
      [nil, nil]
    end

    def self.collect_web_stats(_rpc_packet, server)
      online_ids = {}
      (1..DynamicAppConfig.num_open_zones).each do |zone|
        online_ids[zone] = SessionManager.all_online_ids(zone)
      end
      {
        'server_count' => RpcServer.server_count,
        'packet_processing' => RpcServer.packet_processing,
        'num_connected_sessions' => SessionManager.num_connected_sessions,
        'online_ids' => online_ids,
      }
    end

    private

    def self.convert_broadcast_info(bi)
      if bi
        fail 'invalid broadcast info!' unless bi.is_a? BcastInfo
        bi = bi.to_hash
      end
      bi
    end

    def self.decorate_session(session)
      session.define_singleton_method(:method_missing) do |name, *args, &_block|
        key = name.to_s
        if self.key?(key)
          self[key]
        elsif key =~ /=$/
          self[key.chop] = args[0]
        end
      end
      session
    end
  end

  class ClientReqProcessor
    include Loggable
    include Statsable

    # Divide the packets to batches and process the batches
    #
    # @param server [$boot_config.server] The game server instance
    # @param session [Session] Current session
    # @param packets [$boot_config.game_packet_format] request packet
    # @param handler [Handler] request handler, select from delegate handler table if empty
    # @return [$boot_config.game_packet_format] result packet
    def self.dispatch(server, session, packet, handler)
      with_time_redis_stats "dispatcher" do
        self.do_dispatch(server, session, packet, handler)
      end
    end

    def self.do_dispatch(server, session, packet, handler)
      delegate = $boot_config.dispatch_delegate

      handler_type = delegate.get_type(handler) || 0
      needs_model = true if handler.method(:process).arity > 2
      req_failure = false
      req_error = nil
      result = {}
      bi = nil

      fail_reason = dispatch_with_model(session, delegate, needs_model) do |model|
        begin
          stats_gauge_local 'requests.input_size', packet.len
          stats_gauge_local "handlers.#{handler.name}.input_size", packet.len
          stats_increment_local 'requests.count'
          stats_increment_local "handlers.#{handler.name}.count"
          res, bi = process(server, delegate, handler, session, handler_type, packet.msg, model)
          if res['success'] == false
            req_failure = true
            stats_increment_local 'requests.failure'
            stats_increment_local "handlers.#{handler.name}.failure"
          else
            stats_increment_local 'requests.success'
            stats_increment_local "handlers.#{handler.name}.success"
          end
          res['_handler_name'] = handler.name
        rescue => er
          error("Dispatcher Error for #{session} #{packet}: ", er)
          stats_increment_local 'requests.error'
          stats_increment_local "handlers.#{handler.name}.error"
          req_error = er
        ensure
          result = res || { 'success' => false }
        end

        if req_failure
          ActionDb.log_action(session.player_id, session.zone,
            'fail_requests', handler.name, 'fail', result['reason'])
        elsif req_error
          ActionDb.log_action(session.player_id, session.zone,
            'fail_requests', handler.name, 'error', req_error.message)
        end

        # if has failure, the model will still be persisted.
        # if has error, the model won't be persisted and the client will return to login.
        [req_failure, req_error]
      end

      if fail_reason
        result['success'] = false
        result['reason'] = fail_reason
      elsif req_failure
        result['success'] = false
      elsif req_error
        result['success'] = false
        result['reason'] = 'handler_exception'
      end

      [result, bi]
    end

    private

    # Dispatch requests with or with not model
    # Process db for the requests and write action logs
    def self.dispatch_with_model(session, delegate, needs_model)
      (yield; return nil) unless needs_model

      # Check session already logged in
      return 'not_logged_in' unless session.logged_in?

      # If an old connection unbind was processed after new connection login,
      # there will be an invalid session
      return 'invalid_session' unless
        GameData.validate_id_zone(session.player_id, session.zone)

      CachedGameData.take(session.player_id, session.zone) do |id, zone, model|
        # KOF-1870: should only save model when request succeeded
        #
        # Rollback model is not prefered because:
        # 1. There is a price to store a previous model and rollback if error.
        # 2. If rollback model to last db sync, the game client experiences 'operation lost'.
        # 3. The server framework only enables weak consistency by nature.
        # 4. Most handlers will not modify model before all validations pass.
        #
        # Instead of rollback:
        # 1. Check all handlers to not modify model before all validations pass.
        # 2. Write future handlers to not modify model before all validations pass.
        # 3. If it's inevitable to modify model before all validations pass, make sure
        #    all inconsistent model state due to request errors is not beneficial to player.
        #
        # Now even if your handler returns a request failure,
        # the model will still be persisted.
        # If your handler throws an exception, the model will NOT be persisted.
        # Client will return to login.
        #
        req_failure, req_error = *(yield model)
        model.version = model.version + 1

        if !req_error.nil?
          # forfeit all previous request modifications to the model
          CachedGameData.delete_cache(id, zone, true)
          # err_msg = req_error.message
          # if err_msg !~ /Read timeout occurred/ &&
          #   err_msg !~ /call .+ timeout/ &&
          #   err_msg !~ /call_error: /
          #   CachedGameData.delete_cache(id, zone, true)
          # end
        end

        req_success = ! (req_failure || req_error)

        if req_success
          # FIXME: update callback timing should be after put_back?
          params = delegate.on_before_update(session, model)
          delegate.on_update_success(session, params)
        end
      end

      nil
    end

    # Process one request
    def self.process(_server, delegate, handler, session, type, msg, model)
      result = { 'success' => false }
      bi = nil

      stats_increment_local 'load.requests'
      stats_increment_local "handlers.#{handler.name}.count"

      should_process = delegate.on_before_process session, type, msg, model, result
      return result, bi unless should_process

      with_time_redis_stats "handlers.#{handler.name}" do
        # puts "handler process now:#{handler.name}"
        if handler.method(:process).arity == 2
          result = handler.process(session, msg)
        else
          # puts "check msg: #{msg.class.name}"
          if msg.class.name == "Hash" && msg["batchNum"]
            result = handler.multi_process(msg["batchNum"], session, msg, model)
          else
            result = handler.process(session, msg, model)
          end
        end

        if result.is_a? Array
          result, bi = *result # extract broadcast info if any
        end
        unless result['success'] == false
          delegate.on_process_success(session, type, msg, model, result, handler)
        else
          delegate.on_process_failed(session, type, msg, model, result, handler)
        end
      end

      log_dir = AppConfig.server['msg_log_dir']

      if log_dir && File.directory?(log_dir)
        fn = File.join(log_dir, "#{handler}.log.json")
        File.open(fn, 'w') do |f|
          f.write(JSON.pretty_generate(result).to_s)
        end
      end

      [result, bi]
    end

  end
end
