# redis_index.rb
# Redis Index helpers

module Boot
  #
  # Use redis to build and access indices
  #
  class RedisIndex
    include RedisHelper

    attr_accessor :redis, :name, :options

    def initialize(redis, name, options = nil)
      @redis = redis
      @name = name
      @options = options || {}
    end

    # delete an index key
    def delete(key)
      @redis.del(index_key(key))
      @redis.del(prefix_key(key))
      self
    end

    LUA_UPDATE_PREFIX = %{
      local index_key, prefix_key, id_prefix_key = KEYS[1], KEYS[2], KEYS[3]
      local id, prefix = ARGV[1], ARGV[2]

      local old_prefix = redis.call('hget', prefix_key, id)
      if old_prefix then
        redis.call('zrem', index_key, old_prefix .. ':' .. id)
      end

      redis.call('zadd', index_key, 0, prefix .. ':' .. id)
      redis.call('hset', prefix_key, id, prefix)
      redis.call('hset', id_prefix_key, prefix, id)
      return 0
    }
    # udpate an index key by prefix
    def update_prefix(key, id, prefix)
      return self if prefix.length == 0
      fail "invalid prefix: #{prefix}" if prefix =~ /:/

      @redis.evalsmart(LUA_UPDATE_PREFIX,
                       keys: [index_key(key), prefix_key(key), id_prefix_key(key)],
                       argv: [id, prefix]
                      )
      self
    end

    LUA_DELETE_PREFIX = %{
      local index_key, prefix_key, id_prefix_key = KEYS[1], KEYS[2], KEYS[3]
      local id = ARGV[1]

      local old_prefix = redis.call('hget', prefix_key, id)
      if old_prefix then
        redis.call('zrem', index_key, old_prefix .. ':' .. id)
        redis.call('hdel', id_prefix_key, old_prefix)
      end

      redis.call('hdel', prefix_key, id)
      return 0
    }

    def remove_prefix(key, id)
      @redis.evalsmart(LUA_DELETE_PREFIX,
                       keys: [index_key(key), prefix_key(key), id_prefix_key(key)],
                       argv: [id]
                      )
    end

    LUA_SEARCH_PREFIX = %{
      local index_key = KEYS[1]
      local prefix, count = ARGV[1], ARGV[2]

      local rank = redis.call('zrank', index_key, prefix)
      local range = nil

      if rank then
        range = redis.call('zrange', index_key, rank, rank + count - 1)
      else
        redis.call('zadd', index_key, 0, prefix)
        rank = redis.call('zrank', index_key, prefix)
        range = redis.call('zrange', index_key, rank + 1, rank + count)
        redis.call('zrem', index_key, prefix)
      end

      return range
    }
    # search by prefix
    def search_by_prefix(key, prefix, count = 10)
      return [] if count <= 0
      return [] if prefix.empty?
      fail "invalid prefix: #{prefix}" if prefix =~ /:/

      range = @redis.evalsmart(LUA_SEARCH_PREFIX,
                               keys: [index_key(key)],
                               argv: [prefix, count]
                              )
      range.reject! { |v| !v.start_with?(prefix) }
      # puts "search_by_prefix prefix=#{prefix} range=#{range}"
      range.map { |v| v.split(':')[1] }
    end

    # read only one id by its prefix
    def read_by_prefix(key, prefix)
      return nil if prefix.empty?
      fail "invalid prefix: #{prefix}" if prefix =~ /:/

      prefix_with_sep = "#{prefix}:"
      range = @redis.evalsmart(LUA_SEARCH_PREFIX,
                               keys: [index_key(key)],
                               argv: [prefix_with_sep, 1]
                              )
      range.reject! { |v| !v.start_with?(prefix_with_sep) }

      range[0].split(':')[1] if range.length > 0
    end

    def get_by_prefix(key, prefix)
      @redis.hget(id_prefix_key(key), prefix)
    end

    def get_multi_prefixes(key, ids)
      @redis.hmget(prefix_key(key), ids)
    end

    # udpate an index key by score
    def update_score(key, id, score)
      @redis.zadd(index_key(key), score, id)
      self
    end

    LUA_UPDATE_SCORES = %{
      local keys = KEYS
      local id = table.remove(ARGV, 1)
      local scores = ARGV

      for i = 1, #keys do
        local key = keys[i]
        local score = scores[i]

        if score then
          redis.call('zadd', key, score, id)
        end

      end
    }

    def update_scores(id, keys, scores)
      @redis.evalsmart(LUA_UPDATE_SCORES,
                       keys: keys.map { |x| index_key(x) },
                       argv: [id] + scores
                      )
      self
    end

    def incr_score(key, id, score_incr)
      @redis.zincrby(index_key(key), score_incr, id)
      self
    end

    # search by idue scores
    def search_by_score(key, min, max, count = 0, offset = 0)
      if count > 0
        @redis.zrangebyscore(index_key(key), min, max, limit: [offset, count])
      else
        @redis.zrangebyscore(index_key(key), min, max)
      end
    end

    def rever_search_by_score(key, max, min, count = 0)
      if count > 0
        @redis.zrevrangebyscore(index_key(key), max, min, limit: [0, count])
      else
        @redis.zrevrangebyscore(index_key(key), max, min)
      end
    end

    def length(key)
      @redis.zcard(index_key(key))
    end

    def remove_index(key, id)
      @redis.zrem(index_key(key), id)
    end

    LUA_DELETE_INDEXES = %{
      local keys = KEYS
      local id = ARGV[1]

      for i = 1, #keys do
        local key = keys[i]
        redis.call('zrem', key, id)
      end

      return 0
    }

    def remove_indexes(keys, id)
      keys = keys.map { |x| index_key(x) }
      @redis.evalsmart(LUA_DELETE_INDEXES, keys: keys, argv: [id])
    end

    def revrange(key, page, num_per_page)
      start_index = page * num_per_page
      end_index = (page + 1) * num_per_page - 1
      @redis.zrevrange(index_key(key), start_index, end_index)
    end

    def count(key, min, max)
      @redis.zcount(index_key(key), min.to_s, max.to_s)
    end

    def range(key, start_index, end_index)
      @redis.zrange(index_key(key), start_index, end_index)
    end

    def get_top(key)
      @redis.zrange(index_key(key), -1, -1).first
    end

    LUA_GET_TOP_IDS = %{
      local keys = KEYS

      local res = {}
      for i = 1, #keys do
        local key = keys[i]
        local arr = redis.call('zrange', key, -1, -1)
        res[i] = arr[1] or 'nil'
      end

      return res
    }

    def get_top_ids_by_keys(keys)
      @redis.evalsmart(LUA_GET_TOP_IDS,
                       keys: keys.map { |x| index_key(x) },
                       argv: []
                      )
    end

    def revrank(key, id)
      @redis.zrevrank(index_key(key), id)
    end

    # search by multiple keys
    def search_multi(inter_keys, union_keys)
      fail 'not implemented yet!'
    end

    # rebuild all indices by iterating all possible values
    def rebuild_all(key, pattern)
      fail 'not implemented yet!'
    end

    def check_index_validness(key)
      id_num = @redis.zcount(index_key(key), '-inf', '+inf')
      prefix_num = @redis.hlen(prefix_key(key))
      (prefix_num == 0 || prefix_num == id_num)
    end

    private

    def index_key(key)
      redis_key_by_tag("idx:#{@name}", key)
    end

    def prefix_key(key)
      redis_key_by_tag("idx:#{@name}", "#{key}:pre")
    end

    def id_prefix_key(key)
      redis_key_by_tag("idx:#{@name}", "#{key}:pre:id")
    end
  end
end
