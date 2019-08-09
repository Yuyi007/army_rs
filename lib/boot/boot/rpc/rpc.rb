# Rpc allows remote procedure calls to other servers
# For supported usages, see Rpc implementations
module Boot

  module Rpc

    def self.impl
      @@impl ||= TcpBackend
    end

    # Call an rpc function, wait and return the result
    #
    # @return [object] the remote call result
    def self.call(server, session, mod, func, args)
      # mod = mod || 'Elixir.Egg.Rpc.Functions'
      impl.call(server, session, mod, func, args)
    end

    # Cast an rpc function, return immeidately, do not wait for result
    #
    # @return [bool] true if success
    def self.cast(server, session, mod, func, args)
      # mod = mod || 'Elixir.Egg.Rpc.Functions'
      impl.cast(server, session, mod, func, args)
    end

  end

end
