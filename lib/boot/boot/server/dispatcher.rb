
require 'json'
require 'oj'

module Boot

  # Dispatch client requests to service handlers and process the requests
  class Dispatcher

    include Loggable
    include Statsable
    
    # Divide the packets to batches and process the batches
    #
    # @param server [$boot_config.server] The game server instance
    # @param session [Session] Current session
    # @param packets [Array] Array of requests packets
    # @return [Array] Array of result packets
    def self.dispatch(server, session, packets)
      delegate = $boot_config.dispatch_delegate
      
      cur_batch = []
      results = []

      packets.each_with_index do |packet, i|
        cur_batch << packet
        if not delegate.can_batch? session, packet.t, packet.msg or i == packets.length - 1
          results += dispatch_batch(server, session, delegate, cur_batch)
          cur_batch.clear
        end
      end
      results
    end

  private

    # Dispatch and process the batch of requests
    #
    # If requests all return success=true, DB will be updated
    # If there are requests that return success=false, or
    # If error happens when processing requests:
    #   1. DB won't be updated
    #   2. The batch of requests all return success=false
    #
    # @param server [$boot_config.server] The game server instance
    # @param session [Session] Current session
    # @param delegate [DispatchDelegate] The dispatch delegate
    # @param packets [Array] Array of requests packets
    # @return [Array] Array of result packets
    def self.dispatch_batch(server, session, delegate, packets)
      stats_gauge_local "requests.batch_size", packets.length

      with_time_redis_stats 'dispatcher', "#{packets.length}reqs" do
        needs_model = false
        has_error = false
        has_failure = false
        res_packets = []

        handlers = packets.map do |packet|
          handler = delegate.all_handlers[packet.t]
          needs_model = true if handler.method(:process).arity > 2
          handler
        end

        dispatch_with_model(session, delegate, packets, needs_model) do |model|
          packets.each_with_index do |packet, i|
            res = nil
            req_error = nil
            begin
              handler = handlers[i]
              stats_gauge_local "requests.input_size", packet.len
              stats_gauge_local "handlers.#{handler.name}.input_size", packet.len
              stats_increment_local "requests.count"
              stats_increment_local "handlers.#{handler.name}.count"
              res = Dispatcher.process(server, delegate, handler, session, packet.t, packet.msg, model)
              if res['success'] == false then
                has_failure = true
                stats_increment_local "requests.failure"
                stats_increment_local "handlers.#{handler.name}.failure"
              else
                stats_increment_local "requests.success"
                stats_increment_local "handlers.#{handler.name}.success"
              end
            rescue => er
              error("Dispatcher Error for #{server.peer_id} #{session.player_id} #{session.zone} t=#{packet.t}: ", er)
              stats_increment_local "requests.error"
              stats_increment_local "handlers.#{handler.name}.error"
              has_error = true
              req_error = er
            ensure
              res_packet = $boot_config.game_packet_format.new
              res_packet.n = packet.n
              res_packet.t = packet.t
              res_packet.msg = res || { 'success' => false }
              res_packet.wire_str = res_packet.to_wire session.encoding, session.codec_state
              res_packets << res_packet
              stats_gauge_local "requests.output_size", res_packet.len
              stats_gauge_local "handlers.#{handler.name}.output_size", res_packet.len
            end

            if has_failure
              reason = nil
              reason = res['reason'] if res
              ActionDb.log_action(session.player_id, session.zone,
                'fail_requests', handler.name, 'fail', reason)
            elsif req_error
              ActionDb.log_action(session.player_id, session.zone,
                'fail_requests', handler.name, 'error', req_error.message)
            end
          end
          ! (has_error || has_failure) # if has error or failure, the model won't be persisted
        end

        res_packets.each do |res_packet|
          res_packet.msg['success'] = false
          res_packet.wire_str = res_packet.to_wire session.encoding, session.codec_state
        end if (has_error or has_failure)

        res_packets
      end
    end

    # Dispatch requests with or with not model
    # Process db for the requests and write action logs
    def self.dispatch_with_model(session, delegate, packets, needs_model)
      (yield; return) unless needs_model

      CachedGameData.take(session.player_id, session.zone) do |id, zone, model|
        session.last_active = Time.now
        puts "[data active] session.last_active:#{session.last_active}"
        
        request_success = yield model

        # FIXME update callback timing
        params = delegate.on_before_update(session, model)
        delegate.on_update_success(session, params)
      end
    end

    # Process one request
    def self.process(server, delegate, handler, session, type, msg, model)
      res = { "success" => false }

      stats_increment_local "load.requests"
      stats_increment_local "handlers.#{handler.name}.count"

      should_process = delegate.on_before_process session, type, msg, model, res
      return res unless should_process

      with_time_redis_stats "handlers.#{handler.name}" do
        session.last_active = Time.now
        puts "[data active] session.last_active:#{session.last_active}"

        if handler.method(:process).arity == 2
          res = handler.process(session, msg)
        else
          res = handler.process(session, msg, model)
        end

        unless res['success'] == false
          delegate.on_process_success session, type, msg, model, res, handler
        else
          delegate.on_process_failed session, type, msg, model, res, handler
        end
      end

      log_dir = AppConfig.server['msg_log_dir']

      if log_dir and File.directory? log_dir
        fn = File.join(log_dir, "#{handler}.log.json")
        File.open(fn,"w") do |f|
          f.write(JSON.pretty_generate(res).to_s)
        end
      end

      return res
    end

  end

end