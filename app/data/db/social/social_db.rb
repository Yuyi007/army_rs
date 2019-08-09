class SocialDb
  include RedisHelper

  def self.add_friend(id, friend_id, zone)
    puts "[id] #{id},[friend_id]:#{friend_id}"
    if id and friend_id and id != friend_id
      r = get_redis zone
      a = r.sadd(follows_key(id, zone), friend_id)
      b = r.sadd(follower_key(friend_id, zone), id)
    end
  end

  def self.remove_friend(id, friend_id, zone, type)
    if id and friend_id
      r = get_redis zone
      r.srem(follows_key(id, zone), friend_id)
      r.srem(follower_key(id, zone), friend_id)
      r.srem(follows_key(friend_id, zone), id)
      r.srem(follower_key(friend_id, zone), id)
      #MailBox.resetPairCount(id, friend_id, zone)

      #both add abandon
      # now = Time.now.to_i
      # if type != 1
      #   r.zadd(abandon_key(id, zone), now, friend_id)
      #   r.zadd(abandon_key(friend_id, zone), now, id)
      # end
    end
  end

  #clear abandons before 3 days
  def self.clear_abandons(id, zone)
    now = Time.now.to_i
    before = now - 60 * 60 * 24 *3
    r = get_redis zone
    r.zremrangebyscore(abandon_key(id, zone), 0, before)
  end

  def self.is_abandon(id, zone, player_id)
    now = Time.now.to_i
    r = get_redis zone
    lst = r.zrevrange(abandon_key(id, zone), 0, -1)

    lst.each do |x|
      return true if x == player_id
    end

    return false
  end

  def self.clear_friends(id, zone)
    # clear myself from my friends
    followers(id, zone).each do |friend_id|
      remove_friend(id, friend_id, zone, 1)
    end

    follows(id, zone).each do |friend_id|
      remove_friend(id, friend_id, zone, 1)
    end

    # clear my friends list
    redis(zone).del(follower_key(id, zone))
    redis(zone).del(follows_key(id, zone))
  end

  def self.followers(id, zone)
    redis(zone).smembers(follower_key(id, zone))
  end

  def self.follows(id, zone)
    redis(zone).smembers(follows_key(id, zone))
  end

  # the ones who follow me and i follow them
  def self.friends(id, zone)
    redis(zone).sinter(follows_key(id, zone), follower_key(id, zone))
  end

  # the ones who follow me but i dont follow them
  def self.friend_requests(id, zone)
    redis(zone).sdiff(follower_key(id, zone), follows_key(id, zone), following_key(id, zone))
  end

  def self.is_known?(id, friend_id, zone)
    is_friend?(id, friend_id, zone)
  end

  def self.is_friend?(id, friend_id, zone)
    is_following?(id, friend_id, zone) and is_followed?(id, friend_id, zone)
  end

  def self.is_following?(id, friend_id, zone)
    redis(zone).sismember(follows_key(id, zone), friend_id)
  end

  def self.is_followed?(id, friend_id, zone)
    redis(zone).sismember(follower_key(id, zone), friend_id)
  end

private

  def self.redis(zone)
    get_redis zone
  end

  def self.gen_with_tag(key)
    redis_key_by_tag key, 'social'
  end
  
   def self.key_with_tag(zone)
    @booth ||= Nest.new(redis_key_by_tag('social'), redis(zone))
  end
  #sorted set
  # def self.abandon_key(id, zone)
  #   gen_with_tag "ab:#{id}:z:#{zone}"
  # end

  # def self.follower_key(id, zone)
  #   gen_with_tag "fl:#{id}:z:#{zone}"
  # end

  # def self.follows_key(id, zone)
  #   gen_with_tag "fs:#{id}:z:#{zone}"
  # end

  def self.abandon_key(id, zone)
    key_with_tag(zone)["abandon"][id][zone] 
  end

  def self.follower_key(id, zone)
    key_with_tag(zone)["follower"][id][zone] 
  end

  def self.follows_key(id, zone)
    key_with_tag(zone)["follows"][id][zone] 
  end

  def self.following_key(id, zone)
    key_with_tag(zone)["following"][id][zone] 
  end
end