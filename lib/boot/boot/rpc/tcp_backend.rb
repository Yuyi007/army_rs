# Rpc implementation: TcpBackend
# This implementation of Rpc can call gate server with the
# tcp connection established from the gate server
#
# Currently only cast is supported
#

module Boot::Rpc

  class TcpBackend

    def self.call(server, session, mod, func, args)
      raise "TcpBackend: call() not implemented yet!"
    end

    def self.cast(server, session, mod, func, args)
      packet = $boot_config.rpc_packet_format.new
      packet.t = 1
      packet.msg = {"mod" => mod, "func" => func, "args" => args}
      server.send_rpc_packet packet
      true
    end

    def self.handle_rpc_response(packet)
      # TODO
    end

  end

end
