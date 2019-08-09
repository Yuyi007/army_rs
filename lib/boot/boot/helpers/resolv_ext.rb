# resolv_ext.rb

require 'em-resolv-replace'
require 'em-udns'

# Monkey patches em-udns to receive a block
module EventMachine::Udns

  def self.clear_nameservers
    ENV.delete("NAMESERVERS")
  end

  def self.run(resolver, &blk)
    raise Error, "EventMachine is not running" unless EM.reactor_running?

    raise Error, "`resolver' argument must be a EM::Udns::Resolver instance" unless
      resolver.is_a? EM::Udns::Resolver

    @watch = EM.watch resolver.fd, Watcher, resolver do |dns_client|
      dns_client.notify_readable = true
      yield dns_client if block_given?
    end

    self
  end

  def self.detach
    @watch.detach if defined? @watch and @watch
  end

end

# Monkey patches Resolv to use em-udns
class Resolv

  def self.detach_udns
    EM::Udns.detach
    @@_udns_resolver = nil
  end

  def self.init_udns opts = {}
    resolver = EM::Udns::Resolver.new
    EM::Udns.run resolver do |conn|
      # EM can't close 'watch only' connections so we can't use timeout on fd
      # conn.pending_connect_timeout = opts[:pending_connect_timeout] || 2
      # conn.comm_inactivity_timeout = opts[:comm_inactivity_timeout] || 3
    end
    @@_udns_resolver = resolver
    @@_udns_cache ||= {}
  end

  # def self.set_udns_timeout timeout
  #   @@_udns_timeout = timeout
  # end

  def self.init_udns_cache host, timeout = 600
    @@_udns_cache ||= {}
    @@_udns_cache[host] = {'val' => nil, 'ct' => nil, 'timeout' => timeout}
  end

  private

  def em_getaddresses(host)
    return [ host ] if host =~ /\d+\.\d+\.\d+\.\d+/

    unless (defined? @@_udns_resolver and @@_udns_resolver)
      Resolv.init_udns
    end

    cache_item = @@_udns_cache[host]
    if cache_item
      now = Time.now.to_i
      addr = cache_item['val']
      ct = cache_item['ct']
      if addr == nil or ct == nil or now - ct >= cache_item['timeout']
        # race conditions apply
        # puts "udns get cache item #{host}"
        addr = udns_getaddresses(host)
        cache_item['val'] = addr
        cache_item['ct'] = now
      end
      return addr
    else
      return udns_getaddresses(host)
    end
  end

  def udns_getaddresses(host)
    fiber = Fiber.current
    df = @@_udns_resolver.submit_A host
    df.callback do |a|
      fiber.resume(a)
    end
    df.errback do |*a|
      fiber.resume(ResolvError.new(a.inspect))
    end
    result = Fiber.yield
    if result.is_a?(StandardError)
      raise result
    end
    result
  end
end
