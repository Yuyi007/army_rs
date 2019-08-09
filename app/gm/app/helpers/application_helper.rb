module ApplicationHelper
  def form_for_hash(hash, name, url, html_options={}, &proc)
    object = HashObject.new(hash)
    form_for object, :as=>name, :url=>url, :html=>html_options, &proc
  end

  def hash_object(hash)
    HashObject.new(hash)
  end

  class HashObject
    def initialize(hash={})
      @hash = hash
    end

    def [](key)
      @hash[key]
    end

    def hash
      @hash
    end

    def to_hash
      @hash
    end

    def method_missing(sym, *args, &block)
      @hash[sym.to_s]
    end
  end

  def get_config_name(tid)
    GameConfig.string["str_#{tid}_name"]
  end

  # used to notify client about "Hey, gm tools just edited your data, please reload"
  def notify_gm_edit id, zone, success
    Channel.publish("u:#{id}", zone, { 'gm_edit' => true}) if success
  end

end
