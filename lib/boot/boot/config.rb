# config.rb

module Boot

  class BootConfig

    attr_accessor :app_name, :root_path, :server
    attr_accessor :game_packet_format, :rpc_packet_format
    attr_accessor :auto_load_paths, :auto_load_on_file_changed
    attr_accessor :server_delegate, :connection_delegate,
      :dispatch_delegate, :rpc_dispatch_delegate

    DEFAULT_GAME_PACKET_FORMAT = GenLongPacket
    DEFAULT_RPC_PACKET_FORMAT = GenLongPacket

    def initialize
      self.app_name = 'boot_app'
      self.root_path = File.expand_path(File.join(BOOT_PATH, '..'))
      self.game_packet_format = DEFAULT_GAME_PACKET_FORMAT
      self.rpc_packet_format = DEFAULT_RPC_PACKET_FORMAT
      self.auto_load_paths = lambda { [] }
      self.auto_load_on_file_changed = lambda { false }

      self.server = RpcServer
      self.server_delegate = DefaultServerDelegate.new
      self.connection_delegate = DefaultConnectionDelegate.new
      self.dispatch_delegate = DefaultDispatchDelegate.new
      self.rpc_dispatch_delegate = DefaultRpcDispatchDelegate.new

      yield self if block_given?
    end

  end

  def self.set_config config
    $boot_config = config
  end

end