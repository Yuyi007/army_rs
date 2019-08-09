
require 'yaml'
require 'erb'
require 'pp'
require 'socket'
require 'securerandom'

module Boot

  class AppConfig

    include Loggable

    def self.preload(environment, path = nil)
      if not defined? @@path or @@path != path
        reload(environment, path)
      end
    end

    def self.reload(environment, path = nil)
      @@environment = environment
      @@path = path
      path ||= '.'

      info "app_config: loading app config from #{path}"

      # @@config = YamlAppConfigLoader.new(path, environment).load
      @@config = JsonAppConfigLoader.new(path, environment).load
      puts ">>>>@@config:#{@@config}"
      reload_server_list(path)

      $boot_config.server_delegate.on_app_config_loaded(path)
    end

    def self.reload_server_list(path = nil)
      path = path || '.'
      info "reload_server_list from #{path}"
      file = File.join(path, 'config', 'server_list.json')
      json = JSON.parse(File.read(file))
      @@config['checker_servers'] = json['checker_servers']
    end

    def self.override(options)
      # puts ">>>>>>options:#{options}"
      # server_id
      if options[:host]
        info "AppConfig: overriding host - #{options[:host]}"
        @@config['server']['host'] = options[:host]
      end
      if options[:port]
        info "AppConfig: overriding port - #{options[:port]}"
        @@config['server']['port'] = options[:port]
      end
      if options[:server_id]
        info "AppConfig: overriding server_id - #{options[:server_id]}"
        @@server_id = options[:server_id]
      end
 
      if options[:server_index]
        info "AppConfig: overriding server_index - #{options[:server_index]}"
        @@server_index = options[:server_index]
      end

    end

    # the server ids are unique for all servers
    #
    # named server:
    #   server_id is passed in by options (other servers know my name)
    #
    # anonymouse server:
    #   server_id is random (no one can rpc to me because not knowing my id)
    #
    def self.server_id
      if defined? @@server_id and @@server_id
        @@server_id
      else
        @@server_id = "#{server_host}:#{SecureRandom.uuid}"
        # @@server_id = "data#{server_port}@local"
        info "AppConfig: build server_id - #{@@server_id}"
        @@server_id
      end
    end
    
    def self.server_index
      @@server_index
    end

    def self.server_host
      Socket.gethostname
    end

    def self.server_port
      @@config['server']['port']
    end

    def self.server_env
      self.environment
    end

    def self.server
      @@config['server']
    end

    def self.dev_mode?
      @@config['server']['dev_mode'] == true
    end

    def self.suppress_logs?
      @@config['server']['suppress_logs'] == true
    end

    def self.method_missing(sym, *args, &block)
      @@config[sym.to_s]
    end

    def self.dump
      PP.pp(@@config)
    end

    def self.environment
      @@environment
    end

    def self.path
      @@path
    end

  end

  class JsonAppConfigLoader

    include Loggable

    def initialize path, environment
      @path = path
      @environment = environment
    end

    def load

      file = File.expand_path("#{@path}/config/config.#{@environment}.json")
      if not File.exist? file
        info "app_config.rb: #{file} doesn't exists, using config.json"
        file = File.expand_path("#{@path}/config/config.json")
      end

      # NOTE: bindings not supported
      Oj.load(IO.read(file))
    end

  end

  class YamlAppConfigLoader

    include Loggable

    def initialize path, environment
      @path = path
      @environment = environment
    end

    def load
      file = File.expand_path("#{@path}/config/config.#{@environment}.yml.erb")
      if not File.exist? file
        info "app_config.rb: #{file} doesn't exists, using config.yml.erb"
        file = File.expand_path("#{@path}/config/config.yml.erb")
      end

      binder = YamlAppConfigBinder.new(@path)
      result = YAML::load(ERB.new(IO.read(file)).result(binder.get_binding))
      if Hash === binder.result
        if Hash === result
          config = binder.result.deep_merge_hash result
        else
          config = binder.result
        end
      else
        config = result
      end

      config
    end

  end

  class YamlAppConfigBinder

    attr_accessor :result

    def initialize path
      @path = path
    end

    def base file
      @result = YAML::load(ERB.new(IO.read(File.expand_path(
        "#{@path}/config/#{file}"))).result)
    end

    def get_binding
      return binding
    end

  end

end