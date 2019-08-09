
require 'digest'
require 'json'
require 'uri'
require 'cgi'
require 'net/http'
require 'em-http'

module Boot::Tools

  class GmApi

    include Boot::Loggable

    def call_uri uri, options = {}
      uri = URI.parse(uri) unless uri.is_a? URI
      max_retry = options[:max_retry]|| 2
      secret = options[:secret] || AppConfig.server.http_api_secret
      data = options[:data] || ''

      if EM.reactor_running?
        em_http_post(uri, data, secret, max_retry)
      else
        http_post(uri, data, secret, max_retry)
      end
    end

  private

    def em_http_post(uri, data, secret, max_retry)
      url = "#{uri.scheme}://#{uri.host}:#{uri.port}"
      sign = sign_query(uri.query, secret)
      query = "#{uri.path}?#{uri.query}&sign=#{sign}"
      retries = 0
      while retries <= max_retry do
        http = EventMachine::HttpRequest.new(url).post :query => query, :body => data
        if http.response_header.status == 200
          result = JSON.parse(http.response) rescue {}
          if result['success'] then
            return result
          else
            error "gm_api: failed code=200 res=#{http.response}"
          end
        else
          error "gm_api: failed code=#{http.response_header.status} res=#{http.response}"
        end
        retries += 1
      end
      warn "gm_api: max retry reached"
      return nil

      nil
    end

    def http_post(uri, data, secret, max_retry)
      Net::HTTP.start(uri.host, uri.port) do |http|
        sign = sign_query(uri.query, secret)
        query = "#{uri.path}?#{uri.query}&sign=#{sign}"
        retries = 0
        while retries <= max_retry do
          res = http.request_post query, data
          if res.code.to_i == 200
            result = JSON.parse(res.body)
            if result['success'] then
              return result
            else
              error "gm_api: failed code=200 body=#{res.body}"
            end
          else
            error "gm_api: failed code=#{res.code} body=#{res.body}"
          end
          retries += 1
        end
        warn "gm_api: max retry reached"
        return nil
      end

      nil
    end

    def sign_query query, secret
      str = ''
      params = CGI::parse(query || "")
      params.sort.each do |k, arr|
        k = k.to_s
        v = if arr and arr.length then arr[0] else '' end
        if k != 'sign' and v and v.length > 0
          str << URI.decode(v) << '#'
        end
      end
      str << secret
      # d{ "str=#{str}" }
      Digest::MD5.hexdigest(str.encode('UTF-8'))
    end

  end

end