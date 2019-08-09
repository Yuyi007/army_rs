# encoding: utf-8
# announcement.rb
# 进入游戏显示的公告
#

module Boot

  class Announcement

    attr_accessor :posts

    include Jsonable
    include Loggable
    include Cacheable
    include RedisHelper

    json_array :posts, :AnnouncementPost

    gen_from_hash
    gen_to_hash

    def initialize
      self.posts = []
    end

    def self.get_posts
      redis_hash.hget_or_new('default').posts
    end

    # -1 means last element
    def self.insert_post index, post
      redis_hash.hset_with_lock('default') do |anno|
        anno.posts.insert index, post
        anno
      end
    end

    def self.update_post index, post
      redis_hash.hset_with_lock('default') do |anno|
        anno.posts[index] = post
        anno
      end
    end

    def self.delete_post index
      redis_hash.hset_with_lock('default') do |anno|
        anno.posts.delete_at index
        anno
      end
    end

    def self.sort_posts indexes
      redis_hash.hset_with_lock('default') do |anno|
        posts = indexes.inject([]) { |sorted, i| sorted << anno.posts[i] }
        anno.posts = posts
        anno
      end
    end

    def self.publish
      Channel.publish_global('announcement', {'time' => Time.now.to_i})
    end
  private

    def self.redis_hash
      @@redis_hash ||= RedisHash.new(self.redis, self.key, Announcement)
    end

    def self.redis
      get_redis :user
    end

    def self.key
      'announcement'
    end

  end

  class AnnouncementPost

    attr_accessor :is_new, :title, :message, :time

    include Jsonable
    include Loggable

    def initialize is_new = false, title = '', message = '', time = 0
      self.is_new = is_new
      self.title = title
      self.message = message
      self.time = time
    end

  end

end