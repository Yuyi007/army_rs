# http_connection_ext.rb

require 'em-http'

module EventMachine

  class HttpRequest

    def self.new(uri, options={})
      uri = uri.clone
      u = uri.kind_of?(Addressable::URI) ? uri : Addressable::URI::parse(uri.to_s)
      options[:host] = Resolv.getaddress u.host unless u.host.match(/\d+\.\d+\.\d+\.\d+/)
      connopt = HttpConnectionOptions.new(uri, options)

      c = HttpConnection.new
      c.connopts = connopt
      c.uri = uri
      c
    end

  end

end

class HttpConnectionOptions

  def initialize(uri, options)
    @connect_timeout     = options[:connect_timeout] || 5        # default connection setup timeout
    @inactivity_timeout  = options[:inactivity_timeout] ||= 10   # default connection inactivity (post-setup) timeout

    @tls   = options[:tls] || options[:ssl] || {}
    @proxy = options[:proxy]

    if bind = options[:bind]
      @bind = bind[:host] || '0.0.0.0'

      # Eventmachine will open a UNIX socket if bind :port
      # is explicitly set to nil
      @bind_port = bind[:port]
    end

    uri = uri.kind_of?(Addressable::URI) ? uri : Addressable::URI::parse(uri.to_s)
    @https = uri.scheme == "https"
    uri.port ||= (@https ? 443 : 80)

    if proxy = options[:proxy]
      @host = proxy[:host]
      @port = proxy[:port]
    else
      @host = options[:host] || uri.host
      @port = uri.port
    end
  end

end
