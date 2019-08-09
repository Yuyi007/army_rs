# Statsable.rb

require 'statsd-ruby'

module Boot

  module Statsable

    def self.included(base)
      base.extend ClassMethods
    end

    def self.init options, with_batch = true
      options ||= {}
      opts = options.clone
      opts['with_batch'] = with_batch
      ClassMethods.init opts
    end

    module ClassMethods

      def self.init options
        host = options['host'] || '127.0.0.1'
        port = options['port'] || 9125
        namespace = options['namespace'] || 'boot'
        with_batch = options['with_batch']

        @@sample_rate = options['sample_rate'] || 1

        @@statsd = Statsd.new(host, port.to_i).tap { |sd| sd.namespace = namespace }
        @@statsd = Statsd::Batch.new(@@statsd) if with_batch
      end

      def statsd
        @@statsd
      end

      def sample_rate=(rate)
        @@sample_rate = rate
      end

      def sample_rate()
        @@sample_rate
      end

      def stats_increment name
        @@statsd.increment name, @@sample_rate
      end

      def stats_timing name, value
        @@statsd.timing name, value, @@sample_rate
      end

      def stats_gauge name, value, sample_rate = nil
        puts "[stats] do gauge"
        sample_rate ||= @@sample_rate
        @@statsd.gauge name, value, sample_rate
      end

      def stats_time name, &block
        @@statsd.time(name, @@sample_rate, &block)
      end

      # Stats time and redis ops count for the given block
      # @return result, time and redis_count
      def stats_time_redis name, &block
        start = Time.now
        start_redis_count = Fiber.current[:redis_ops_count].to_i
        result = yield
        redis_count = Fiber.current[:redis_ops_count].to_i - start_redis_count
        time = ((Time.now - start) * 1000).round
        @@statsd.timing("#{name}.time", time, @@sample_rate)
        @@statsd.gauge("#{name}.redis", redis_count, @@sample_rate)
        return result, time, redis_count
      end

      instance_methods.each do |method|
        if method.to_s.start_with? 'stats_' and method !~ /(_local|_global)$/
          define_method("#{method}_local") do |name, *args, &block|
            local_name = "#{AppConfig.server_id}.#{name}"
            # puts "[dispatch] stats local_name:#{local_name}"
            res = send(method, local_name, *args, &block)
            # puts "[dispatch] stats success"
            res
          end
          define_method("#{method}_global") do |name, *args, &block|
            send(method, name, *args, &block)
          end
        end
      end

      # helper to easy debug time and redis usage
      def with_time_redis_stats(title, msg = nil, &block)
        block_result, time, redis_count = stats_time_redis_local("#{title}", &block)

        if AppConfig.dev_mode?
          d{ "[#{title}] #{time.to_i}ms #{redis_count}ops #{msg}" }
        end

        block_result
      end

    private

    end

    include ClassMethods

  end
end