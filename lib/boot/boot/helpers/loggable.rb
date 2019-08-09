# Loggable.rb

module Boot

  module Loggable

    def self.included(base)
      base.extend ClassMethods
    end

    def self.set_level level
      level = Logger.const_get(level.to_s.upcase) if level.is_a?(Symbol)

      unless level.is_a?(Fixnum)
        raise ArgumentError.new("Invalid logger level `#{level.inspect}`")
      end

      @@level = level
    end

    def self.set_suppress_logs suppress = nil
      if suppress == nil
        suppress = AppConfig.suppress_logs? or (! AppConfig.dev_mode?)
      end

      if suppress
        @@level = Logger::INFO
        @@suppress = true
      else
        @@level = Logger::DEBUG
        @@suppress = false
      end
    end

    module ClassMethods
      @@level = Logger::DEBUG unless defined? @@level
      @@suppress = false unless defined? @@suppress

      @@log = Syslogger.new("rs", Syslog::LOG_PID | Syslog::LOG_CONS, Syslog::LOG_LOCAL3)
      @@log.max_octets = 8192
      @@log.level = Logger::INFO

      @@stat = Syslogger.new("stat", Syslog::LOG_PID | Syslog::LOG_CONS, Syslog::LOG_LOCAL4)
      @@stat.max_octets = 4096
      @@stat.level = Logger::INFO

      @@sdk = Syslogger.new("sdk", Syslog::LOG_PID | Syslog::LOG_CONS, Syslog::LOG_LOCAL4)
      @@sdk.max_octets = 1080
      @@sdk.level = Logger::INFO

      def fatal(msg, e = nil)
        return if @@level > Logger::FATAL
        if e then
          msg = _loggable_format_error(msg, e)
          _loggable_notify(e)
        end
        _loggable_add(@@log, Logger::FATAL, msg)
      end

      def error(msg, e = nil)
        return if @@level > Logger::ERROR
        if e then
          msg = _loggable_format_error(msg, e)
          _loggable_notify(e)
        end
        _loggable_add(@@log, Logger::ERROR, msg)
      end

      def warn(msg, e = nil)
        return if @@level > Logger::WARN
        if e then msg = _loggable_format_error(msg, e) end
        _loggable_add(@@log, Logger::WARN, msg)
      end

      def info(msg, e = nil)
        return if @@level > Logger::INFO
        if e then msg = _loggable_format_error(msg, e) end
        _loggable_add(@@log, Logger::INFO, msg)
      end

      def debug(e = nil, &blk)
        return if @@level > Logger::DEBUG
        msg = blk.call
        if e then msg = _loggable_format_error(msg, e) end
        _loggable_add(@@log, Logger::DEBUG, msg)
      end

      alias :d :debug

      def stat(msg)
        _loggable_add(@@stat, Logger::INFO, msg)
      end

      def sdklog(msg)
        _loggable_add(@@sdk, Logger::INFO, msg)
      end

      def flush
        _loggable_flush(@@log)
        _loggable_flush(@@stat)
        _loggable_flush(@@sdk)
      end

    private

      def _loggable_add(syslog, level, msg)
        begin
          now_s = Time.now.strftime "%H:%M:%S.%L"
          case level
          when Logger::DEBUG
            level_s = 'debug'
          when Logger::INFO
            level_s = 'info'
          when Logger::WARN
            level_s = 'warn'
          else
            level_s = 'error'
          end
          msg = "#{now_s} [#{level_s}] #{msg}"
          puts msg unless @@suppress
          syslog.add_with_cache(level, msg)
        rescue => er
          begin
            puts _loggable_format_error('1 error when output messages', er)
            syslog.add_with_cache(level, _loggable_clean(msg))
          rescue => err
            puts _loggable_format_error('2 error when output messages', err)
          end
        end
      end

      def _loggable_flush(syslog)
        syslog.flush_cache
      end

      def _loggable_clean(msg)
        if msg
          msg.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '?')
        else
          nil
        end
      end

      def _loggable_format_error(msg, e)
        "#{msg} #{e.message}\n\t" + e.backtrace.join("\n\t")
      end

      def _loggable_notify(e)
       # return nil if AppConfig.dev_mode?
       # Bugsnag.notify(e) rescue nil
      end

    end

    include ClassMethods
  end

end