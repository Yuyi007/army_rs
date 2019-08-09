
require 'redis'
require 'redis/distributed'
require 'redis/connection/synchrony'
require 'em-hiredis'
require 'em-synchrony'
require 'digest/sha1'
require 'boot/helpers/loggable'

class Redis

  #
  # Monkey patches the synchrony driver to add timeout
  #
  module Connection
    class RedisClient < EventMachine::Connection
      attr_writer :timeout

      def read
        @req = EventMachine::DefaultDeferrable.new
        @req.timeout @timeout if @timeout
        data = EventMachine::Synchrony.sync @req
        if data.nil?
          Boot::Stats_.stats_increment_local 'redis.timeout'
          [:error, 'Read timeout occurred']
        else
          # puts "data=#{data}"
          data
        end
      end
    end

    class Synchrony
      def timeout=(timeout)
        @connection.timeout = timeout
        @timeout = timeout
      end
    end
  end

  #
  # Redis command extensions
  #
  module CommandExt
    @@script_cache = {}

    def evalsmart(*args)
      script = args.shift

      begin
        digest = (@@script_cache[script] ||= Digest::SHA1.hexdigest script)
        res = evalsha(digest, *args)
      rescue Redis::CommandError => e
        if e.message =~ /NOSCRIPT/
          res = eval(script, *args)
        else
          raise e
        end
      end
      res
    end

    def lrange_batch(key, start, stop, batch = 5000)
      len = llen(key)
      start = len + start if start < 0
      stop = len + stop if stop < 0
      return nil if start < 0 || stop < 0

      i = start
      j = start + batch
      while j < stop
        lrange(key, i, j).each { |v| yield v if block_given? }
        i = j + 1
        j += batch
      end
      lrange(key, i, stop).each { |v| yield v if block_given? } if i <= stop

      nil
    end

    def zrange_batch(key, start, stop, batch = 5000, options = {})
      len = zcard(key)
      start = len + start if start < 0
      stop = len + stop if stop < 0
      return nil if start < 0 || stop < 0

      i = start
      j = start + batch
      while j < stop
        zrange(key, i, j, options).each { |v| yield v if block_given? }
        i = j + 1
        j += batch
      end
      zrange(key, i, stop, options).each { |v| yield v if block_given? } if i <= stop

      nil
    end

    def lpush_batch(key, *values)
      synchronize do |client|
        client.call([:lpush, key, *values])
      end
    end

    def sentinel_get_master_name(master_name)
      synchronize do |client|
        client.call([:sentinel, 'get-master-addr-by-name', master_name])
      end
    end

    # redis.call interface, e.g. redis.call(:get, :foo)
    def call(*args)
      operation = args.shift
      operation = operation.to_s.downcase
      __send__(operation.to_sym, *args)
    end
  end

  module DistCommandExt
    def lpush_batch(key, *values)
      node_for(key).lpush_batch(key, *values)
    end
  end

  include CommandExt

  class Client
    include Boot::Loggable

    def initialize(options = {})
      @options = _parse_options(options)
      @reconnect = true
      @logger = @options[:logger]
      @connection = nil
      @command_map = {}
    end


    def establish_connection
      # d { ">> establish_connection: client:#{self} #{@options.dup} #{caller}" }
      @connection = @options[:driver].connect(@options.dup)
      # d { ">>@client #{self} @connection:#{@connection} connection.connected?:#{connection.connected?}"}
    rescue TimeoutError
      SentinelFactory.query_redis_config_changes unless @options[:sentinel]
      raise CannotConnectError, "Timed out connecting to Redis on #{location}"
    rescue Errno::ECONNREFUSED
      SentinelFactory.query_redis_config_changes unless @options[:sentinel]
      raise CannotConnectError, "Error connecting to Redis on #{location} (ECONNREFUSED)"
    ensure
    end
  end

  class Distributed
    include CommandExt
    include DistCommandExt

    def add_redis(redis, options = {})
      options = @default_options.merge(options)
      @ring.add_node redis
    end

    def _eval(cmd, args)
      script = args.shift
      options = args.pop if args.last.is_a?(Hash)
      options ||= {}

      keys = args.shift || options[:keys] || []
      argv = args.shift || options[:argv] || []

      ensure_same_node(cmd, keys) do |node|
        #
        # Weird things happen if we use send here:
        # in evalsmart, after calling evalsha, subsequent eval calls in the rescue block
        # raises Error: no implicit conversion of Array into String
        #
        # Suspiciouly, this could be a bug when cascading Object.send calls and with variable
        # length arguments
        #
        # node.send(cmd, script, keys, argv)
        node._eval(cmd, [script, keys, argv])
      end
    end
  end
end
