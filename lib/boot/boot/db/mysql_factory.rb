# MysqlFactory.rb
require "em-synchrony/mysql2"

module Boot

  class MysqlFactory

    def self.init options
      @@within_event_loop = options[:within_event_loop] || false
      @@pool_size = options[:pool_size] || 1
      @@mysqls = {}

      if AppConfig.mysql
        AppConfig.mysql.each do |_, cfgs|
          cfgs.each do |cfg|
            @@mysqls[db_name cfg] ||= self.make_db(
              :host => cfg['host'],
              :port => cfg['port'],
              :username => cfg['username'],
              :password => cfg['password'],
              :database => cfg['database'],
              :reconnect => true,
              :connect_timeout => 6,
              :read_timeout => 12,
              :write_timeout => 12,
              :pool_size => @@pool_size)
          end
        end
      end
    end

    def self.fini
    end

    def self.mysql_cfg(name, zone)
      puts "[archive] mysql cfg:#{AppConfig.mysql}"
      if AppConfig.mysql
        cfgs = AppConfig.mysql[name.to_s]
        if cfgs
          return cfgs.find do |cfg|
            zone >= cfg['zones'][0] and zone <= cfg['zones'][1]
          end
        end
      end
      return nil
    end

    def self.mysql(name, zone)
      @@mysqls[db_name(mysql_cfg(name, zone))]
    end

  private

    def self.db_name(cfg)
      "#{cfg['username']}@#{cfg['host']}:#{cfg['port']}/#{cfg['database']}"
    end

    def self.make_db(options)
      if @@within_event_loop
        EventMachine::Synchrony::ConnectionPool.new(size: options[:pool_size]) do
          Mysql2::EM::Client.new options
        end
      else
        Mysql2::Client.new options
      end
    end

  end

end