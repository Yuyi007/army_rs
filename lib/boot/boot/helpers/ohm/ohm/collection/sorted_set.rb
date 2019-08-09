module Ohm
  class SortedSet
    include Collection
    attr_accessor :key
    attr_accessor :namespace
    attr_accessor :model
    attr_accessor :sort_with

    def initialize(key, namespace, model, sort_with)
      @key = key
      @namespace = namespace
      @model = model
      @sort_with = sort_with
    end

    def size
      redis.zcard(key)
    end

    def find(options)
      arr = model.find(options)
      ids = arr.ids & self.ids
      Ohm::SimpleSet.new(ids, redis, namespace, model)
    end

    # Returns an array of elements from the sorted set using ZRANGE.
    # #range receives 2 integers, start and stop
    #
    # Example:
    #
    #   class CreditRecord < Ohm::Model
    #     include Ohm::DataTypes
    #     attribute :credits, Type::Integer
    #   end
    #
    #   class CreditEvent < Ohm::Model
    #     sorted_set :records, :CreditRecord, :credits
    #   end
    #
    #   c1 = CreditRecord.create(:credits => 1)
    #   c2 = CreditRecord.create(:credits => 2)
    #   c3 = CreditRecord.create(:credits => 3)
    #
    #   event = CreditEvent.create
    #
    #   event.records.add(c1)
    #   event.records.add(c2)
    #   event.records.add(c3)
    #
    #   [c1, c2] == event.records.range(0, 1)
    #   [c3, c2] == event.records.revrange(0, 1)
    #   # => true

    def range(start, stop)
      fetch(redis.zrange(key, start, stop))
    end

    def ids_with_score(start, stop)
      redis.zrange(key, start, stop, with_scores: true)
    end

    def rev_ids_with_score(start, stop)
      redis.zrevrange(key, start, stop, with_scores: true)
    end

    # Keep the sorted set to the speicified length
    # @param [int] length to keep
    def keep_head(length)
      drop_below(length)
    end

    # Reversely keep the sorted set to the specified length
    # @param [int] length to keep
    def keep_tail(length)
      rank = size - length
      drop_above(rank)
    end

    def drop_above(rank)
      redis.zremrangebyrank(key, 0, rank - 1) if rank > 0
    end

    def drop_below(rank)
      redis.zremrangebyrank(key, rank, -1) if rank >= 0
    end

    def revrange(start, stop)
      fetch(redis.zrevrange(key, start, stop))
    end

    def add(model)
      if model.respond_to?(sort_with)
        redis.zadd(key, model.send(sort_with), model.id)
      else
        redis.zadd(key, 0, model.id)
      end
    end

    def add_multi(models)
      return unless models.length > 0
      datas = models.map { |model| [model.send(sort_with), model.id] }.flatten
      redis.zadd(key, datas) if datas.size > 0
    end

    def delete(model)
      redis.zrem(key, model.id)
    end

    def delete_multi(models)
      ids = models.map(&:id)
      redis.zrem(key, ids)
    end

    def delete_by_id(id)
      redis.zrem(key, id)
    end

    def delete_by_ids(ids)
      redis.zrem(key, ids)
    end

    def ids
      redis.zrange(key, 0, -1)
    end

    def redis
      model.redis
    end

    def first
      id = redis.zrange(key, 0, 0).first
      model[id]
    end
  end
end
