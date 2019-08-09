# SynchronyExt.rb

require 'em-synchrony'

module EventMachine

  def self.synchrony(blk=nil, tail=nil)
    # EM already running.
    if reactor_running?
      if block_given?
        Synchrony.fiber_pool.spawn { yield }
      else
        Synchrony.fiber_pool.spawn { blk.call }
      end
      tail && add_shutdown_hook(tail)

    # EM not running.
    else
      if block_given?
        run(nil, tail) { Synchrony.fiber_pool.spawn { yield } }
      else
        run(Proc.new { Synchrony.fiber_pool.spawn { blk.call } }, tail)
      end

    end
  end

  module Synchrony

    def self.init_fiber_pool(count = 100)
      @@fiber_pool = Boot::FiberPool.new(count)
    end

    def self.fiber_pool
      @@fiber_pool
    end

    def self.add_timer(interval, &blk)
      EM::Timer.new(interval) do
        fiber_pool.spawn { blk.call }
      end
    end

    def self.add_periodic_timer(interval, &blk)
      EM.add_periodic_timer(interval) do
        fiber_pool.spawn { blk.call }
      end
    end

    def self.next_tick(&blk)
      EM.next_tick { fiber_pool.spawn { blk.call } }
    end
  end
end
