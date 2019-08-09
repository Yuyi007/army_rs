require 'db/events/game_event'
require 'db/events/eventable'
require 'db/events/configurable'

class GameEventsDb
  include Cacheable
  include Eventable
  include Configurable

  # gen_event :xuezhan, GameEvent::Xuezhan

  # gen_config :package,   GameEvent::Package
  gen_config :notice, GameEvent::Notice

  def self.ng(reason)
    { 'success' => false, 'reason' => reason }
  end

  def self.g(reason)
    { 'success' => true, 'reason' => reason }
  end

  def self.basic_valid?(data)
    return [false, :data_nil] if data.nil?
    return [false, :data_is_not_hash] unless data.is_a?(::Hash)
    true
  end

  def self.create_config(data, clazz)
    valid, reason = basic_valid?(data)
    return ng(reason) unless valid
    valid, res = clazz.create_with_data(data)
    return ng(res) unless valid
    [g(:created), (res.to_data rescue nil)]
  end

  def self.update_config(data, clazz)
    valid, reason = basic_valid?(data)
    return ng(reason) unless valid
    return ng(:id_not_specified) unless data.id
    valid, res = clazz.update_by_id(data.id, data)
    return ng(res) unless valid
    g(:updated)
  end

  def self.delete_config(id, clazz)
    clazz.delete(id)
    g(:deleted)
  end

  def self.delete_all_config(clazz)
    clazz.delete_all
    g(:deleted)
  end

  def self.get_config(id, clazz)
    clazz[id].to_data
  rescue
    nil
  end

  def self.get_configs(clazz)
    clazz.get_all.to_data
  end

  def self.get_config_by_tid(tid, clazz)
    clazz.find_by_tid(tid).to_data
  rescue
    nil
  end

  def self.delete_config_by_tid(tid, clazz)
    clazz.delete_by_tid(tid)
    g(:deleted)
  end

  def self.create_event(zone, data, user, clazz)
    valid, reason = basic_valid?(data)
    return ng(reason) unless valid
    valid, reason = clazz.validate(zone, data, user)
    return ng(reason) unless valid
    valid, res = clazz.new_one(zone, data)
    return ng(res) unless valid
    [g(:created), res.to_data]
  end

  def self.update_event(zone, data, user, clazz)
    valid, reason = basic_valid?(data)
    return ng(reason) unless valid
    valid, reason = clazz.validate(zone, data, user)
    return ng(reason) unless valid
    return ng(:id_not_specified) unless data.id
    valid, reason = clazz.update_by_id(data.id, data)
    return ng(reason) unless valid
    g(:updated)
  end

  def self.force_copy_events(from_zone, to_zone, user, clazz)
    valid, reason = clazz.validate_copy_all(from_zone, to_zone, user)
    return ng(reason) unless valid
    valid, reason = clazz.force_copy_all(from_zone, to_zone, user)
    return ng(reason) unless valid
    g(:all_copied)
  end

  def self.copy_valid_events(from_zone, to_zone, user, clazz)
    valid, reason = clazz.copy_only_valid(from_zone, to_zone, user)
    return ng(reason) unless valid
    g(:all_copied)
  end

  def self.copy_event(from_zone, to_zone, id, user, clazz)
    valid, reason = clazz.validate_copy(from_zone, to_zone, id, user)
    return ng(reason) unless valid
    valid, res = clazz.copy_create(from_zone, to_zone, id)
    return ng(reason) unless valid
    g(:copied)
  end

  def self.delete_event(id, user, clazz)
    valid, reason = clazz.validate_delete(id, user)
    return ng(reason) unless valid
    clazz.delete(id)
    g(:deleted)
  end

  def self.delete_all_events(zone, user, clazz)
    valid, reason = clazz.validate_delete_all(zone, user)
    return ng(reason) unless valid
    clazz.delete_all(zone)
    g(:deleted)
  end

  def self.get_events(zone, clazz)
    clazz.find_many(zone).to_a.map(&:to_data).reverse
  end

  def self.get_event(id, clazz)
    clazz[id].to_data
  rescue
    nil
  end

  def self.get_open_event(zone, clazz)
    clazz.get_open(zone).to_data
  rescue
    nil
  end

  def self.get_open_event_native(zone, clazz)
    clazz.get_open(zone)
  end

  def self.get_all_open_events(zone, clazz)
    clazz.get_all_open(zone).map(&:to_data)
  end
end
