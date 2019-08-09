# LoadLogger.rb
# Deprecated: use Statsable instead

module Boot

  class LoadLogger

    include Singleton
    include RedisHelper

    attr_reader :enable_metrics
    attr_reader :csv_data

    @@log = Syslogger.new("load", Syslog::LOG_PID | Syslog::LOG_CONS, Syslog::LOG_LOCAL3)
    @@log.max_octets = 480
    @@log.level = Logger::DEBUG

    def initialize
      @enable_metrics = AppConfig.dev_mode?
      @csv_data = ''
      @reqStats = {}

      @conns = 0
      @requests = 0
      @pubsubs = 0
      @systems = 0
      @restores = 0
      @timeouts = 0
      @timerCount = 0
      @timerLatency = 0

      @beginTime = Time.now
    end

    def packet_begin session
      session.last_recv_time = Time.now
    end

    def packet_end session, name = nil, reqSize = 0, resSize = 0
      session.last_sent_time = Time.now

      if name
        time = session.last_sent_time - session.last_recv_time

        @reqStats[name] ||= RequestStat.new name
        @reqStats[name].count += 1
        @reqStats[name].totalTime += time
        @reqStats[name].longestTime = time if time > @reqStats[name].longestTime
        @reqStats[name].totalRequestSize += reqSize
        @reqStats[name].totalResponseSize += resSize
      end
    end

    def dispatch_begin session, name
      if enable_metrics
        session.last_dispatch_begin_time = Time.now
        session.last_dispatch_begin_redis_ops = redis_total_ops_count

        @reqStats[name] ||= RequestStat.new name
      end
    end

    def dispatch_end session, name
      if enable_metrics
        session.last_dispatch_end_time = Time.now
        session.last_dispatch_end_redis_ops = redis_total_ops_count
        time = session.last_dispatch_end_time - session.last_dispatch_begin_time

        @reqStats[name] ||= RequestStat.new name
        @reqStats[name].totalDispatchTime += time
        @reqStats[name].longestDispatchTime = time if time > @reqStats[name].longestDispatchTime
      end
    end

    def request_begin session, name
      if enable_metrics
        session.last_handle_begin_time = Time.now
        session.last_handle_begin_redis_ops = redis_total_ops_count
      end
    end

    def request_end session, name
      if enable_metrics
        session.last_handle_end_time = Time.now
        time = session.last_handle_end_time - session.last_handle_begin_time
        session.last_handle_end_redis_ops = redis_total_ops_count

        @reqStats[name] ||= RequestStat.new name
        @reqStats[name].totalProcessTime += time
        @reqStats[name].longestProcessTime = time if time > @reqStats[name].longestProcessTime
      end
    end

    def add_connection
      @conns += 1
    end

    def remove_connection
      @conns -= 1
    end

    def add_request
      @requests += 1
    end

    def add_pubsub
      @pubsubs += 1
    end

    def add_system
      @systems += 1
    end

    def add_restore
      @restores += 1
    end

    def add_timeout
      @timeouts += 1
    end

    def add_timer_latency latency
      @timerCount += 1
      @timerLatency += latency
    end

    def uptime
      (Time.now - @beginTime).to_i
    end

    def num_sessions
      SessionManager.num_all_player_sessions
    end

    def log
      conn = EM.connection_count
      pool = EM::Synchrony.fiber_pool
      redis_ops = redis_total_ops_count

      # compute timer latency
      if @timerCount > 0
        timerLatency = @timerLatency / @timerCount
        @timerCount = 0
        @timerLatency = 0
      end

      # compute requests
      totalCount = 0
      totalTime = 0
      totalRequestSize = 0
      totalResponseSize = 0
      reqs = ''
      @reqStats.each do |name, stat|
        totalCount += stat.count
        totalTime += stat.total_time_in_ms
        totalRequestSize += stat.totalRequestSize
        totalResponseSize += stat.totalResponseSize
        if enable_metrics and AppConfig.server['port'] == 8082
          reqs += "#{name}-#{stat.count}-#{stat.total_time_in_ms}-#{stat.totalRequestSize}-#{stat.totalResponseSize}-"
        end
      end
      reqs += "All-#{totalCount}-#{totalTime}-#{totalRequestSize}-#{totalResponseSize}"
      @csv_data = "#{uptime},#{conn},#{@conns},#{num_sessions},#{pool.queue_size},#{pool.busy_size},#{@requests},#{@restores},#{redis_ops},#{@timeouts},#{reqs},#{timerLatency},#{@pubsubs},#{@systems}"
    end

    def dump_gc
      output "GC stat #{GC.stat}"
    end

    def dump_request_stats
      output "dump_request_stats"
      count = 0
      totalDispatchTime = 0
      totalProcessTime = 0
      @reqStats.each do |name, stat|
        count += stat.count
        totalDispatchTime += stat.totalDispatchTime
        totalProcessTime += stat.totalProcessTime
      end
      @reqStats.values.sort.each do |stat|
        countPercentage = stat.count * 100.0 / count
        timePercentage = stat.totalDispatchTime * 100.0 / totalDispatchTime
        processTimePercentage = stat.totalProcessTime * 100.0 / totalProcessTime
        output "%-32s %10d  (%5.2f%%) %8.1f  (%5.2f%%) %6.2f %8.1f  (%5.2f%%) %6.2f %4d %5d %6.2f %6.2f" %
          [ stat.name, stat.count, countPercentage,
            stat.totalDispatchTime.to_f, timePercentage, stat.average_time,
            stat.totalProcessTime.to_f, processTimePercentage, stat.average_process_time,
            stat.average_request_size, stat.average_response_size,
            stat.longestDispatchTime, stat.longestProcessTime ]
      end
    end

    def print_request_performance session, handlerName
      if enable_metrics
        total = (session.last_sent_time.to_f - session.last_recv_time.to_f) * 1000.0
        handle = (session.last_handle_end_time.to_f - session.last_handle_begin_time.to_f) * 1000.0
        dispatch = (session.last_dispatch_end_time.to_f - session.last_dispatch_begin_time.to_f) * 1000.0 - handle
        # Note that redis ops is not accurate when there is multiple request going on simultaneously
        handleRedisOps = session.last_handle_end_redis_ops.to_i - session.last_handle_begin_redis_ops.to_i
        dispatchRedisOps = session.last_dispatch_end_redis_ops.to_i - session.last_dispatch_begin_redis_ops.to_i - handleRedisOps
        puts "[#{handlerName}] Total #{total.to_i}ms Dispatcher #{dispatch.to_i}ms #{dispatchRedisOps}ops Handler #{handle.to_i}ms #{handleRedisOps}ops"
      end
    end

  private

    def output s
      @@log.info s
    end

  end

  class RequestStat
    attr_accessor :name, :count,
      :totalTime, :longestTime,
      :totalDispatchTime, :longestDispatchTime,
      :totalProcessTime, :longestProcessTime,
      :totalRequestSize, :totalResponseSize

    def initialize name
      @name = name
      @count = 0
      @totalTime = 0
      @longestTime = 0
      @totalDispatchTime = 0
      @longestDispatchTime = 0
      @totalProcessTime = 0
      @longestProcessTime = 0
      @totalRequestSize = 0
      @totalResponseSize = 0
    end

    def total_time_in_ms
      (@totalTime.to_f * 1000).to_i
    end

    def average_time
      if @count > 0
        @totalTime.to_f / @count * 1000
      else
        0
      end
    end

    def average_dispatch_time
      if @count > 0
        @totalDispatchTime.to_f / @count * 1000
      else
        0
      end
    end

    def average_process_time
      if @count > 0
        @totalProcessTime.to_f / @count * 1000
      else
        0
      end
    end

    def average_request_size
      if @count > 0
        @totalRequestSize.to_f / @count
      else
        0
      end
    end

    def average_response_size
      if @count > 0
        @totalResponseSize.to_f / @count
      else
        0
      end
    end

    def <=> that
      that.average_time <=> average_time
    end
  end

end