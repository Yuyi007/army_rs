# Permission.rb
#
#

module Boot

  class Permission

    # anything that is not forbidden is permissible
    attr_accessor :denies

    include Jsonable
    include Loggable
    include Cacheable
    include RedisHelper

    json_array :denies, :DenyInfo

    gen_from_hash
    gen_to_hash

    def initialize
      self.denies = {}
    end

    def self.add_deny player_id, name, zones = nil
      redis_hash.hset_with_lock(player_id) do |permission|
        permission.denies.delete_if { |deny| deny.name == name.to_s }
        permission.denies << DenyInfo.new(name, zones)
        permission
      end
    end

    def self.update_deny_by_index player_id, index, name, zones = nil
      redis_hash.hset_with_lock(player_id) do |permission|
        permission.denies[index] = DenyInfo.new(name, zones)
        permission
      end
    end

    def self.remove_deny_by_index player_id, index
      redis_hash.hset_with_lock(player_id) do |permission|
        permission.denies.delete_at index
        permission
      end
    end

    def self.sort_by_indexes player_id, indexes
      redis_hash.hset_with_lock(player_id) do |permission|
        denies = indexes.inject([]) { |sorted, i| sorted << permission.denies[i] }
        permission.denies = denies
        permission
      end
    end

    def self.denied? player_id, zone, name
      denies = self.get_denies(player_id)
      denies.select { |deny| deny.name == name.to_s }.each do |deny|
        return true if deny.include_zone? zone
      end
      false
    end

    def self.get_denies player_id
      get(player_id).denies
    end

    def self.get player_id
      redis_hash.hget_or_new(player_id)
    end

  private

    def self.redis_hash
      @@redis_hash ||= RedisHash.new(self.redis, self.key, Permission, nil)
    end

    def self.redis
      get_redis :user
    end

    def self.key
      'permission'
    end

  end

  class DenyInfo

    attr_accessor :name
    attr_accessor :zones # array, nil or empty means all zones

    include Jsonable
    include Loggable

    def initialize name = '', zones = nil
      self.name = name
      self.zones = zones
    end

    def include_zone? zone
      zones == nil or zones.length == 0 or zones.include? zone.to_i
    end

  end

end