
class GameDataFactory
  def self.preload(path = nil)
    reload(path) unless defined? @@data
  end

  def self.reload(path = nil)
    path ||= '.'
    @@data = {}

    @@data['default'] = init_default_model(Model.new.from_json!(
      IO.read("#{path}/game-data/default.json")))

    %w(test1 load1).each do |id|
      @@data[id] = fix_npc_model(Model.new.from_json!(
        IO.read("#{path}/game-data/#{id}.json")))
    end
  end

  def self.keys
    @@data.keys
  end

  def self.get_default
    get('default')
  end

  def self.get(id)
    @@data[id]
  end

  # return a new instance of default model
  def self.new_default
    default = get_default
    Helper.deep_copy(default)   
  end

  private

  def self.init_default_model(model)
    model
  end

  def self.fix_npc_model(model)
    model
  end
end
