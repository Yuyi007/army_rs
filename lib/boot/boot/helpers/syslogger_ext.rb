
require 'syslogger'

# An improvment to ruby syslogger gem implementation
# Cache log messages, reduce sys calls
#
# NOTE this is NOT thread safe, but is fiber safe
class Syslogger

  # Set the max octets of the messages written to the log
  def max_octets=(max_octets)
    @max_octets = max_octets
    @chunks_regexp = /.{#{max_octets}}/m
  end

  # Add log with a log cache
  # This is NOT thread safe
  def add_with_cache(severity, message = nil, progname = nil, &block)
    # severity is ignored because we rely on loggable to do severity filtering
    if message.nil? && block.nil? && !progname.nil?
      message, progname = progname, nil
    end
    progname ||= @ident
    @cache ||= []

    communication = clean(message || block && block.call)

    if self.max_octets && communication.length > self.max_octets
      # FIXME
      # communication is currently truncated if it exceeds max_octets
      # because split or scan a long string can be very slow.
      #
      # chunks = communication.scan(@chunks_regexp)
      # chunks.each { |chunk| @cache << chunk }
      @cache << communication.slice!(0, self.max_octets)
    else
      @cache << communication
    end

    #disabled cache because it interrupts log timeline
    flush_cache if @cache.size > 0
  end

  # Flush the log cache to syslogger
  # This is NOT thread safe
  def flush_cache(progname = nil)
    # NOTE the severity is different with vanilla Syslogger implementation
    return unless @cache
    progname ||= @ident
    severity = MAPPING[@level]
    Syslog.open(progname, @options, @facility) do |s|
      s.mask = Syslog::LOG_UPTO(severity)
      @cache.each do |chunk|
        s.log(severity, chunk)
      end
      @cache.clear
    end
  end

  protected

  # Faster clean
  # And because we have a cache, we print out current time on the message
  def clean(message)
    message = message.to_s
    # message = message.to_s.dup
    # message.strip! # remove whitespace
    message.gsub!(/\n/, '\\n') # escape newlines
    message.gsub!(/%/, '%%') # syslog(3) freaks on % (printf)
    # message.gsub!(/\e\[[^m]*m/, '') # remove useless ansi color codes
    message
  end

end