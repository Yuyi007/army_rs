module Ohm
  class SimpleSet
    include Collection

    attr_accessor :ids
    attr_accessor :redis
    attr_accessor :namespace
    attr_accessor :model

    def initialize(ids, redis, namespace, model)
      @ids = ids
      @redis = redis
      @namespace = namespace
      @model = model
    end

    def size
      if ids then ids.size else 0 end
    end

    def first
      return nil if ids.nil? || ids.empty?
      model[ids.first]
    end
  end
end
