# redis_helper.rb
# Redis db helpers

module Boot

  #
  # Redis key helper
  #
  module RedisHelper

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def make_channel_redises
        AppConfig.cluster ? RedisClusterFactory.make_channel_redises : RedisFactory.make_channel_redises
      end

      # Total redis ops count
      # @return [Integer] the ops count
      def redis_total_ops_count
        AppConfig.cluster ? RedisClusterFactory.total_ops_count : RedisFactory.total_ops_count
      end

      # Get a redis instance for game logic
      # @param name [String] name is ignored now
      # @return [Redis] always return the distributed redis
      def get_redis(name = nil)
        # name = name.to_s
        # raise "invalid redis name #{name}" if name !~ /^(\d+|user|stat|action|chat)$/
        AppConfig.cluster ? RedisClusterFactory.cluster : RedisFactory.distributed
      end

      # Get a random redis instance for game logic
      # @return [Redis] alway return the distributed redis
      def get_random_redis
        AppConfig.cluster ? RedisClusterFactory.cluster : RedisFactory.distributed
      end

      # keys with the same tag will be stored on the same redis instance
      # @param tag [String] the tag
      # @param key [String] the key
      # @return [String] new key with the tag
      def redis_key_by_tag(tag, key = nil)
        if key then "{#{tag}}#{key}" else "{#{tag}}" end
      end

    end

    include ClassMethods

  end

end