# delegates.rb

module Boot

  # the default server delegate for subclassing with
  class DefaultServerDelegate

    # callback when server at prefork stage, may be called multiple times
    def on_server_prefork options = {}
    end

    # callback when server start, will only be called once
    def on_server_start options = {}
    end

    # callback when app config loaded
    def on_app_config_loaded path
    end

    # callback when pubsub init
    def on_pubsub_init
    end

  end

  # the default connection delegate for subclassing with
  class DefaultConnectionDelegate

    # create a game session
    # @param id [String] the id of the connection
    # @param server [$boot_config.server] the server instance
    def create_session(id, server)
      Boot::DefaultSession.new id, server
    end

    # unbind callback
    # @param server [$boot_config.server] the server instance
    # @param session [Session] the session instance
    def unbind(server, session)
    end

    # callback when send response success
    # @param server [$boot_config.server] the server instance
    # @param session [Session] the session instance
    # @param res_packet [$boot_config.game_packet_format] the response packet
    def on_send_success(server, session, res_packet)
    end

  end

  # the default dispatch delegate for subclassing with
  class DefaultDispatchDelegate

    # create the model with default data for a player
    # @return [Model] the default model
    def create_default_model session
      nil
    end

    # create the empty model for a player
    # @return [Model] the empty model object
    def create_model
      nil
    end

    # returns all registered handlers
    # @return [Hash] a hash of handlers [type -> Handler]
    def all_handlers
      Handlers::HANDLERS
    end

    # decides whether a request can be batched
    # @return [Bool] true if the request can be batched, false if not
    def can_batch? session, type, msg
      false
    end

    # on_before_process
    # @param session [Session] the game session
    # @param type [Integer] the type of the request
    # @param msg [Hash] the message of the request
    # @param model [Model] the game data model
    # @param res [Hash] the process result
    # @return [Bool] whether should further process this request
    def on_before_process session, type, msg, model, res
      true
    end

    # on_prcoess_success
    def on_process_success session, type, msg, model, res, handler
    end

    # on_process_failed
    def on_process_failed session, type, msg, model, res, handler
    end

    def on_before_update session, model
      []
    end

    def on_update_success session, options
    end

  end

  # the default rpc dispatch delegate for subclassing with
  class DefaultRpcDispatchDelegate

    # returns all registered rpc modules
    # @param mod the rpc function module
    # @return [Hash] a hash of functions [type -> Handler]
    def all_functions(mod)
      {}
    end

    # callback when rpc process success
    # @param session [Session] the session instance
    # @param res_packet [$boot_config.game_packet_format] the response packet
    # @param bi [BcastInfo] the broadcast info
    # @param result [Hash] the response hash
    def on_rpc_success(session, res_packet, result, bi)
    end

  end

end