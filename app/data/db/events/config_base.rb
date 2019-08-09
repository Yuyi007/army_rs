
module GameEvent
  class ConfigBase < Ohm::Model
    include EventCommon

    def self.on_post_from_hash(_data)
    end

    def self.update_by_id(id, data)
      d = self[id]
      return [false, :config_not_found] if d.nil?
      d.from_hash!(data)
      on_post_from_hash(d)
      d.save
      true
    end

    def self.create_with_data(data)
      d = create
      d.from_hash!(data)
      on_post_from_hash(d)
      d.save
      [true, d]
    end

    def self.find_by_tid(tid)
      collection = find(tid: tid)
      collection.first
    end

    def self.delete_by_tid(tid)
      collection = find(tid: tid)
      collection.to_a.each(&:delete)
    end

    def self.get_all
      all.to_a
    end
  end
end
