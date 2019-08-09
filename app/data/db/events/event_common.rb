module GameEvent
  module EventCommon
    def self.included(base)
      # apparently *include* is private in ruby 2.0 but public in ruby 2.1
      # use class_eval instead
      base.class_eval do
        include(Ohm::Callbacks)
        include(Ohm::DataTypes)
        include(RedisHelper)
        include(Loggable)
        include(Cacheable)
      end

      base.extend(ClassMethods)
    end

    def from_hash!(hash)
      self.class.attributes.each do |key|
        _hash_assign(hash, key)
      end

      self
    end

    def _hash_assign(hash, key)
      if hash.key? key
        send("#{key}=", hash[key])
      elsif hash.key? key.to_s
        send("#{key}=", hash[key.to_s])
      end
    end

    def to_s
      to_json
    end

    def to_json
      Helper.to_json(to_hash)
    end

    def to_data
      to_hash
      # Helper.to_hash(to_json)
    end

    # wrap the RedisRpc.call
    def redis_rpc_call(job_klazz, *args)
      RedisRpc.call(job_klazz, checker_id, *args)
    end

    # wrap the RedisRpc.call
    def redis_rpc_cast(job_klazz, *args)
      RedisRpc.cast(job_klazz, checker_id, *args)
    end

    # Get the checker id. Requires zone attribute to be defined in the ohm object
    def checker_id
      Helper.get_zone_checker(zone)
    end

    def to_msgpack(io = nil)
      to_hash.to_msgpack(io)
    end

    def to_hash
      hash = {}

      self.class.attributes.each do |key|
        val = send(key)
        val = val.to_data if val.respond_to?(:to_data)
        hash.merge!(key.to_s => val)
      end

      self.class.counters.each do |key|
        val = send(key).to_i
        hash.merge!(key.to_s => val)
      end

      hash = super.merge(hash)
      hash['id'] = hash.delete(:id).to_s
      hash
    end

    module ClassMethods
      def redis
        get_redis :action
      end

      # The key should work with the tag for redis-distributed
      def key
        @key ||= Nido.new(redis_key_by_tag('game_evt', name))
      end

      def delete(id)
        o = self[id]
        o.delete if o
      end

      def delete_all
        delete_multi(all)
        # all.to_a.each(&:delete)
      end
    end
  end
end
