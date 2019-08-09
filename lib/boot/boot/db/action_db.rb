
module Boot

  class ActionDb

    include Loggable
    include RedisHelper

    # MAX_ACTION_LOGS with experiment:
    # (1..1_000_000).each { |_| r.lpush('action_log', MessagePack.pack(['9999999999222', 100, 2000, 1395646993, 'abcdefg', '1231423', 'dvweffewHH', 'we23e233', '23e32423'])) }
    # Redis memory consumption increased: 122.12M
    # Redis rdb dump size increased: 68M

    MAX_ACTION_LOGS = 50_000_000

    @@action_names = {}
    @@action_types = {}

    LOG_ACTION = %Q{
      local key = KEYS[1]
      redis.call('lpush', key, ARGV[1])
      redis.call('ltrim', key, 0, #{MAX_ACTION_LOGS})
    }
    def self.log_actions(id, zone, actions)
      actions.each do |action|
        self.log_action(id, zone, *action)
      end
    end

    def self.log_action(id, zone, type, *params)
      # t = validate_action(type, params)

      # params.each_with_index do |param, i|
      #   if param.is_a?(Hash) or param.is_a?(Array)
      #     error("action_db: serialize your params to refined strings before calling log_action type=#{type} param #{i}")
      #     return
      #   end
      # end

      data = [ id.to_s, zone, type, Time.now.to_f ] + params
      self.redis.evalsmart(LOG_ACTION, :keys => [ self.key ], :argv => [ MessagePack.pack(data) ])
    end

    def self.validate_action(type, params = nil)
      raise 'action_db: maximum allow 5 params' if params and params.length > 5

      t = type.is_a?(Integer) ? type : @@action_names[type]
      raise "action_db: no such action type #{type}" if t == nil

      return t
    end

    def self.clear_actions
      last = 1
      while last do last = self.redis.rpop(self.key) end
    end

    def self.remain_log_count
      self.redis.llen(self.key)
    end

    def self.register_action_type(t, name)
      # raise "action_db: already has this name: #{name}" if @@action_names.has_key?(name)
      # raise "action_db: already has this type: #{t}" if @@action_names.has_value?(t)
      @@action_types[t] = name
      @@action_names[name] = t
    end

    def self.action_names
      @@action_names.dup
    end

    def self.action_types
      @@action_types.dup
    end

    #####   exposed keys start  #####

    def self.key
      "action_log"
    end

    #####   exposed keys end   #####

  private

    def self.redis
      return @@redis if defined? @@redis and @@redis
      return get_redis :user
    end

    def self.redis= redis
      @@redis = redis
    end

  end

end