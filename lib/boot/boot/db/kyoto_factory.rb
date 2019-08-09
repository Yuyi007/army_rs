# KyotoFactory.rb
require "em-synchrony/em-memcache"
require "memcache"

module Boot

  class KyotoFactory

    def self.init options
      @@within_event_loop = options[:within_event_loop] || false
      @@pool_size = options[:pool_size] || 1
      @@kyotos = {}

      if AppConfig.kyoto
        AppConfig.kyoto.each do |_, cfg|
          @@kyotos[kyoto_name cfg] ||= self.make_kyoto(
            :host => cfg['host'],
            :port => cfg['port'],
            :pool_size => @@pool_size)
        end
      end
    end

    def self.fini
    end

    def self.kyoto(name)
      @@kyotos[redis_name AppConfig.kyoto[name.to_s]]
    end

  private

    def self.kyoto_name(cfg)
      "#{cfg['host']}:#{cfg['port']}"
    end

    def self.make_kyoto(options)
      if @@within_event_loop
        EventMachine::Synchrony::ConnectionPool.new(size: options[:pool_size]) do
          EM::P::Memcache.connect options[:host], options[:port]
        end
      else
        MemCacheKyoto.new("#{options[:host]}:#{options[:port]}")
      end
    end

  end

  class MemCacheKyoto < MemCache

    # NOTE: method fix not complete

    alias_method :get_orig, :get
    alias_method :set_orig, :set

    def get(key, raw = true)
      get_orig(key, raw)
    end

    def set(key, value, expiry = 0, raw = true)
      set_orig(key, value, expiry, raw)
    end

  end

end