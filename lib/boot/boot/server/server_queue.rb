module Boot

  # ServerQueue is for queueing execution of server events
  # For now, post_init, unbind and receive_data will be queued
  #
  class ServerQueue

    include Loggable

    def initialize
      @queue = []
      @executing = false
    end

    def submit &blk
      @queue << blk

      unless @executing
        @executing = true

        EM.synchrony do
          while not @queue.empty? do
            begin
              @queue.shift.call
            rescue => e
              error("Server queue Error: ", e)
            end
          end
          @executing = false
        end
      end
    end

  end

end