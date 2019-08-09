require 'db/events/credit'

module GameEvent
  class Soul < EventBase
    attribute :type
    attribute :data, Type.array
  end

  class Xuezhan < EventBase
    attribute :rewardTids, Type.array
    attribute :event_type
  end

  class Campaign < EventBase
    attribute :normalEnabled, Type::Bool
    attribute :hardEnabled, Type::Bool
    attribute :expertEnabled, Type::Bool
    attribute :dropRound, Type.hash
    attribute :bonus, Type.hash
  end

  class CampaignExp < EventBase
    attribute :campaign_zones, Type.array
  end

  class Zhaoxian < EventBase
    attribute :hero1
    attribute :hero2
    attribute :hero3
    attribute :hero4
  end

  class ZoneMarket < EventBase
    BUY_ZONE_MARKET_ITEM = <<-EOF
    local key = KEYS[1]
    local user_id, max_num = unpack(ARGV)
    local cur_size = redis.call('scard', key)
    if cur_size >= tonumber(max_num) then
      return false
    end

    redis.call('sadd', key, user_id)
    return true
    EOF

    def bought_key
      key[:bought]
    end

    def buy(user_id, index, max_num)
      redis.evalsmart(BUY_ZONE_MARKET_ITEM,
                      keys: [bought_key[index]],
                      argv: [user_id, max_num])
    end

    def buyers(index)
      redis.smembers(bought_key[index])
    end

    def bought_num(index)
      redis.scard(bought_key[index])
    end

    def bought_before?(user_id, index)
      redis.sismember(bought_key[index], user_id)
    end
  end
end
