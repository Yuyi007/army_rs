module Ohm
  class Set < Ohm::BasicSet
    attr_reader :key
    attr_reader :namespace
    attr_reader :model

    def initialize(key, namespace, model)
      @key = key
      @namespace = namespace
      @model = model
    end

    # Chain new fiters on an existing set.
    #
    # Example:
    #
    #   set = User.find(:name => "John")
    #   set.find(:age => 30)
    #
    def find(dict)
      MultiSet.new(
        namespace, model, Command[:sinterstore, key, *model.filters(dict)]
      )
    end

    # Reduce the set using any number of filters.
    #
    # Example:
    #
    #   set = User.find(:name => "John")
    #   set.except(:country => "US")
    #
    #   # You can also do it in one line.
    #   User.find(:name => "John").except(:country => "US")
    #
    def except(dict)
      MultiSet.new(namespace, model, key).except(dict)
    end

    # Do a union to the existing set using any number of filters.
    #
    # Example:
    #
    #   set = User.find(:name => "John")
    #   set.union(:name => "Jane")
    #
    #   # You can also do it in one line.
    #   User.find(:name => "John").union(:name => "Jane")
    #
    def union(dict)
      MultiSet.new(namespace, model, key).union(dict)
    end

    private

    def execute
      yield key
    end

    def redis
      model.redis
    end
  end
end