require 'rubygems'  # poor people still on 1.8
# gem 'minitest'
# require 'minitest/autorun'
# require 'minitest/spec'
require 'rspec'

puts '========= spec init =========='

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../../lib/boot')


require 'boot'

include Boot


###############################

class Database
  include Jsonable
  attr_accessor :name
  attr_accessor :backup_time
  def init name; @name = name; self; end
  def backup; @backup_time = Time.now.to_i; end
end

class Application
  include Jsonable
  attr_accessor :name
  def init name; @name = name; self; end
end

class Cpu
  include Jsonable
  attr_accessor :name
  def init name; @name = name; self; end
end

class Computer
  include Jsonable
  attr_accessor :name
  attr_accessor :applications
  attr_accessor :databases
  attr_accessor :cpu
  json_hash :applications, :Application
  json_array :databases, :Database
  json_object :cpu, :Cpu
  gen_from_hash
  gen_to_hash
  def init name; @name = name; self; end
end

class ComputerHashStorable < Computer
  include HashStorable
  gen_from_hash
  gen_to_hash
  def validate_model id, zone; true end
end

###############################

# 1
class Login < Handler

  def self.process session, msg
    session.player_id = msg['id']
    session.zone = msg['zone']
    { 'success' => true }
  end

end

# 2
class InstallApplication < Handler

  def self.process session, msg, model
    # puts "model=#{model} msg=#{msg}"
    if model.applications.has_key? msg['id']
      puts "id '#{msg['id']}' already exists! request fail!"
      { 'success' => false }
    else
      model.applications[msg['id']] = Application.new.init(msg['name'])
      { 'success' => true }
    end
  end

end

# 3
class UninstallApplication < Handler

  def self.process session, msg, model
    if model.applications.has_key? msg['id']
      model.applications.delete msg['id']
      { 'success' => true }
    else
      { 'success' => false }
    end
  end

end

# 4
class UpgradeCpu < Handler

  def self.process session, msg, model
    if model.cpu then
      model.cpu.name += '+'
      { 'success' => true }
    else
      raise 'no cpu found in model'
    end
  end

end

# 5
class CreateDatabase < Handler

  def self.process session, msg, model
    model.databases.each do |database|
      if msg['name'] == database.name
        return { 'success' => false }
      end
    end
    model.databases << Database.new.init(msg['name'])
    { 'success' => true }
  end

end

# 6
class BackupDatabase < Handler

  def self.process session, msg, model
    model.databases.each do |database|
      if msg['name'] == database.name
        database.backup
        return { 'success' => true }
      end
    end
    { 'success' => false }
  end

end

###############################

class DispatchDelegate < Boot::DefaultDispatchDelegate

  def create_default_model session
    ComputerHashStorable.new.init 'Mac Pro 2014'
  end

  def create_model
    ComputerHashStorable.new
  end

  def all_handlers
    {
      1 => Login,
      2 => InstallApplication,
      3 => UninstallApplication,
      4 => UpgradeCpu,
      5 => CreateDatabase,
      6 => BackupDatabase,
    }
  end

  def can_batch? session, type, msg
    (type > 1)
  end

end

###############################

def spec_new_boot_config
  config = BootConfig.new do |cfg|
    cfg.root_path = File.expand_path(File.join(File.dirname(__FILE__), '../..'))
    cfg.dispatch_delegate = DispatchDelegate.new
  end
end

Boot.set_config(spec_new_boot_config)

Dir.chdir($boot_config.root_path)
AppConfig.preload('test')
AppConfig.override(:port => 'nil')

Redis.new(:driver => :hiredis)

puts '========= spec init done =========='
