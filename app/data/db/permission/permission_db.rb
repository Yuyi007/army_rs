
class PermissionDb
  include RedisHelper
  include Loggable
  include Cacheable

  def self.get_player_permission(player_id)
    self.permissions[:all].hget(player_id)
  end

  def self.deny_login?(player_id)
    self.permissions[:all].hget(player_id) == "dlogin"
  end

  def self.deny_talk?(player_id)
    self.permissions[:all].hget(player_id) == "dtalk"
  end

  def self.set_permission(player_id, permission_type)
    if permission_type == "normal"
      self.permissions[:all].hdel(player_id)       
    else 
      self.permissions[:all].hset(player_id, permission_type) 
    end
  end


  def self.permission_list
    self.permissions[:all].hgetall
  end



  def self.permissions
    @permissions ||= Nest.new('permissions', redis)
  end



  def self.redis
    get_redis(:action)
  end
end
