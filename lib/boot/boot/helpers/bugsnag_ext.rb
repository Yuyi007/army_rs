
require 'bugsnag'
require "net/https"
require "uri"
require "thread"

module Bugsnag
  module Delivery


    class Synchronous
      class << self
        def deliver(url, body, configuration, options={})
          begin
            do_request(url, body, configuration, options)
          rescue StandardError => e
            # KLUDGE: Since we don't re-raise http exceptions, this breaks rspec
            raise if e.class.to_s == "RSpec::Expectations::ExpectationNotMetError"

            configuration.warn("Notification to #{url} failed, #{e.inspect}")
            configuration.warn(e.backtrace)
          end
        end

        private

        def do_request(url, body, configuration, options)
          # puts "do_request url=#{url}"
          # puts "do_request body=#{body}"
          # puts "do_request configuration=#{configuration}"
          # puts "do_request options=#{options}"
          if EM.reactor_running?
            EM.synchrony do
              http = request_with_em_http(url, body, configuration, options)
              code = http.response_header.status.to_s
              response = http.response
              configuration.debug("Request to #{url} completed, status: #{response}")
              if code[0] != "2"
                configuration.warn("Notifications to #{url} was reported unsuccessful with code #{code}")
              end
            end
          else
            response = request_with_http(url, body, configuration, options)
            configuration.debug("Request to #{url} completed, status: #{response.code}")
            if response.code[0] != "2"
              configuration.warn("Notifications to #{url} was reported unsuccessful with code #{response.code}")
            end
          end
        end

        def request_with_em_http(url, body, configuration, options)
          uri = URI.parse(url)
          uri.host = Resolv.getaddress uri.host unless uri.host.match(/\d+\.\d+\.\d+\.\d+/)

          headers = options.key?(:headers) ? options[:headers] : {}
          headers.merge!(default_headers)

          opts = {}
          if configuration.proxy_host
            opts[:proxy] = {
              :host => configuration.proxy_host,
              :port => configuration.proxy_port,
              :authorization => [configuration.proxy_user, configuration.proxy_password],
            }
          end

          http = EventMachine::HttpRequest.new(uri, opts).post :body => body, :headers => headers
          http
        end

        def request_with_http(url, body, configuration, options)
          uri = URI.parse(url)

          if configuration.proxy_host
            http = Net::HTTP.new(uri.host, uri.port, configuration.proxy_host, configuration.proxy_port, configuration.proxy_user, configuration.proxy_password)
          else
            http = Net::HTTP.new(uri.host, uri.port)
          end

          http.read_timeout = configuration.timeout
          http.open_timeout = configuration.timeout

          if uri.scheme == "https"
            http.use_ssl = true
            http.ca_file = configuration.ca_file if configuration.ca_file
          end

          headers = options.key?(:headers) ? options[:headers] : {}
          headers.merge!(default_headers)

          request = Net::HTTP::Post.new(path(uri), headers)
          request.body = body

          http.request(request)
        end

        def path(uri)
          uri.path == "" ? "/" : uri.path
        end

        def default_headers
          {
            "Content-Type" => "application/json",
            "Bugsnag-Sent-At" =>  Time.now().utc().strftime('%Y-%m-%dT%H:%M:%S')
          }
        end
      end
    end


    class ThreadQueue < Synchronous
      class << self
        def deliver(url, body, configuration, options)
          super(url, body, configuration, options)
        end
      end
    end


  end
end

Bugsnag::Delivery.register(:synchronous, Bugsnag::Delivery::Synchronous)
Bugsnag::Delivery.register(:thread_queue, Bugsnag::Delivery::ThreadQueue)
