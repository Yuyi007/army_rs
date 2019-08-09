# redis_cluster_factory.rb

require 'redis'
require 'redis/connection/synchrony'
require 'em-hiredis'
require 'em-synchrony'

module Boot

  class RedisClusterFactory

    # max cluster connections, @see cluster.rb
    # this should be at least the size of the cluster,
    # because close and establish connections is very harmful to performance
    MAX_CLUSTER_CONNS = 16

    include Loggable

    def self.init options = nil
      # init options
      @@within_event_loop ||= options[:within_event_loop] || false
      @@timeout ||= options[:timeout] || 2.5
      @@pool_size ||= options[:pool_size] || 2

      if AppConfig.cluster
        @@config = AppConfig.cluster.map do |node|
          if node.is_a? String
            name = node
            host = name.split(':')[0]
            port = name.split(':')[1].to_i
          else
            host = node["host"]
            port = node["port"]
            name = "#{host}:#{port}"
          end
          { :name => name, :host => host, :port => port }
        end
        # info "AppConfig cluster2 #{@@config}"
        @@cluster ||= RedisCluster.new(@@config, MAX_CLUSTER_CONNS,
          :timeout => @@timeout, :pool_size => @@pool_size)
      else
        @@cluster = nil
      end
    end

    def self.init_failsafe
      @@within_event_loop = false
      @@pool_size = 1

      if AppConfig.cluster
        @@cluster = RedisCluster.new(@@config, MAX_CLUSTER_CONNS,
          :timeout => @@timeout, :pool_size => @@pool_size)
      end
    end

    def self.fini
      if defined? @@cluster
        @@cluster.connections.each do |_, r|
          r.close_connections if r.respond_to?(:close_connections)
          r.close_connection if r.respond_to?(:close_connection)
          r.pubsub.close_connection if r.respond_to?(:pubsub)
          r.quit if r.respond_to?(:quit)
        end

        @@cluster = nil
        @@within_event_loop = nil
        @@timeout = nil
        @@pool_size = nil
      end
    end

    # @return [Redis]
    def self.cluster
      @@cluster
    end

    def self.total_ops_count
      count = @@cluster.connections.values.inject(0) { |sum, r| sum + r.ops_count }
      count
    end

    def self.make_channel_redises
      if AppConfig.pubsub_redis
        res = {}
        AppConfig.pubsub_redis.each do |cfg|
          name = redis_name(cfg)
          res[name] = self.make_hiredis(
            :host => cfg['host'],
            :port => cfg['port'],
            :timeout => @@timeout)
        end
        res
      else
        # get a random config from startup_nodes, which will be refreshed when nodes down
        cfg = @@cluster.startup_nodes.sample
        { 'cluster' => self.make_hiredis(
          :host => cfg[:host],
          :port => cfg[:port],
          :timeout => @@timeout)  }
      end
    end

    def self.make_redis(options)
      if @@within_event_loop
        RedisConnPool.new(size: options[:pool_size]) do
          #info "[cluster] redis new options:#{options} "
          Redis.new(:host => options[:host], :port => options[:port],
            :timeout => options[:timeout], :tcp_keepalive => 0, :driver => :synchrony)
        end
      else
        Redis.new(:host => options[:host], :port => options[:port],
          :timeout => options[:timeout], :tcp_keepalive => 0, :driver => :hiredis,
          :inherit_socket => true)
      end
    end

    def self.make_hiredis(options)
      if @@within_event_loop
        redis = EM::Hiredis.connect("redis://#{options[:host]}:#{options[:port].to_i}")
        redis.on(:reconnect_failed) do |fail_count|
          info "reconnect_failed #{fail_count}"
        end
        redis.pubsub.on(:reconnect_failed) do |fail_count|
          info "pubsub reconnect_failed #{fail_count}"
        end
        redis
      else
        # NOTE: this instance doens't work with Channel.rb
        Redis.new(:host => options[:host], :port => options[:port], :driver => :hiredis)
      end
    end

  private

    def self.redis_name(cfg)
      "#{cfg['name']}#{cfg['host']}:#{cfg['port']}"
    end

  end

end

# patch redis cluster to provide redis instance with connection pool
class RedisCluster

  attr_reader :connections, :startup_nodes

  include Boot::Loggable
  def get_redis_link(host,port)
    #info "get_redis_link host:#{host} port:#{port} startup_nodes:#{@startup_nodes}"
    RedisClusterFactory.make_redis({
      :host => host,
      :port => port,
      :pool_size => @opt[:pool_size],
      :timeout => @opt[:timeout]
      })
  end

  # redis.call interface, e.g. redis.call(:get, :foo)
  def call *args
    operation = args.shift
    operation = operation.to_s.downcase
    __send__(operation.to_sym, *args)
  end

end
