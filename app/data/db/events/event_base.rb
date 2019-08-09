
module GameEvent
  class EventBase < Ohm::Model
    include EventCommon

    def self.inherited(base)
      base.attribute :zone, Type::Integer
      base.attribute :start_time, Type::Integer
      base.attribute :end_time, Type::Integer
      base.attribute :granted, Type::Bool
      base.index :zone
    end

    # Only one event through out
    def self.one(zone)
      d = find_one(zone)
      d ||= create(zone: zone)
    end

    def from_hash!(hash)
      self.class.attributes.each do |key|
        next if key.to_s == 'zone'
        _hash_assign(hash, key)
      end
    end

    # Create a new event at zone with new id
    def self.new_one(zone, data = nil)
      return [false, :max_size_reached] if find(zone: zone).size >= max_size
      d = create(zone: zone)
      d.from_hash!(data) if data
      d.save
      [true, d]
    end

    def grant
      self.granted = true
    end

    def in_time?
      now = Time.now.to_i
      start_time <= now && end_time >= now
    end

    def opened?
      self.in_time?
    end

    def overlap?(other)
      return false if other.end_time.to_i < start_time.to_i
      return false if other.start_time.to_i > end_time.to_i
      true
    end

    def self.find_many(zone)
      find(zone: zone)
    end

    def self.find_one(zone)
      collections = find(zone: zone)
      collections.first if collections.size > 0
    end

    def self.valid_time?(data)
      return [false, :invalid_start_end_time] if data.start_time.to_i > data.end_time.to_i
      true
    end

    # validate critical data
    def self.valid_data?(_data)
      true
    end

    def self.validate(zone, data, _user)
      valid, reason = self.valid_time?(data)
      return [false, reason] unless valid

      valid, reason = self.valid_data?(data)
      return [false, reason] unless valid

      collections = find_many(zone)
      now = Time.now.to_i

      collections.ids.each do |id|
        e = self[id]
        if data.id && data.id.to_i != id.to_i
          return [false, "time_overlap #{data} - #{e}"] if e.overlap?(data)
        end

        # time change detection for in progress event might not be neccessary
        # if data.id and data.id.to_i == id
        #   if o.start_time <= now && o.end_time >= now && o.enabled
        #     return [false, :event_in_progress]
        #   end
        # end
      end

      true
    end

    def self.validate_copy_all(from_zone, to_zone, user)
      return [false, :from_zone_to_zone_are_same] if from_zone == to_zone
      return true if user.auth == 1
      mine = find_many(from_zone)
      mine.ids.each do |id|
        data = self[id]
        valid, reason = validate(to_zone, data, user)
        return [valid, reason] unless valid
      end

      true
    end

    def self.validate_delete(id, user)
      return true if user.auth == 1
      data = self[id]
      return [false, :no_data] if data.nil?
      return [false, :event_in_progress] if data.opened?
      true
    end

    def self.validate_delete_all(zone, user)
      return true if user.auth == 1
      ids = find_many(zone).ids
      ids.each do |id|
        valid, reason = validate_delete(id, user)
        return [valid, reason] unless valid
      end
      true
    end

    def self.delete_all(zone)
      all = find_many(zone).to_a
      all.each(&:delete)
    end

    def self.get_open(zone)
      all = find_many(zone)
      all.ids.each do |id|
        data = self[id]
        return data if data.opened?
      end
      nil
    end

    def self.get_all_open(zone)
      all = find_many(zone)
      opened_list = []
      all.to_a.each do |data|
        opened_list << data if data.opened?
      end
      opened_list
    end

    def self.copy_create(_from_zone, to_zone, id)
      data = self[id]
      new_one(to_zone, data.to_data)
    end

    def self.validate_copy(from_zone, to_zone, id, user)
      data = self[id]
      return [false, :from_zone_to_zone_are_same] if from_zone == to_zone
      return [false, :no_event_to_copy] if data.nil?
      return [false, :zone_not_right] if data.zone != from_zone.to_i
      validate(to_zone, data.to_data, user)
    end

    def self.force_copy_all(from_zone, to_zone, user)
      return [false, :from_zone_to_zone_are_same] if from_zone == to_zone
      return [false, :invalid_auth] if user.auth != 1
      mine = find_many(from_zone)
      theirs = find_many(to_zone)

      theirs.to_a.each(&:delete)
      mine.to_a.each do |d|
        new_one(to_zone, d.to_data)
      end
      true
    end

    def self.copy_only_valid(from_zone, to_zone, user)
      mine = find_many(from_zone)

      mine.to_a.each do |m|
        valid, reason = validate(to_zone, m.to_data, user)
        new_one(to_zone, m.to_data) if valid
      end

      true
    end

    def self.update(zone, data)
      target = one(zone)
      target.from_hash!(data)
      target.save
    end

    def self.update_by_id(id, data)
      d = self[id]
      return [false, :event_not_found] if d.nil?
      d.from_hash!(data)
      d.save
      true
    end

    def self.copy(from_zone, to_zone)
      d1 = find_one(from_zone)
      return [false, "#{from_zone} has no data"] if d1.nil?
      d2 = one(to_zone)
      d2.from_hash!(d1.to_hash)
      d2.zone = to_zone
      d2.save
      true
    end

    def self.max_size
      10
    end
  end
end
