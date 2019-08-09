module Ohm
  class MutableSet < Ohm::Set
    # Add a model directly to the set.
    #
    # Example:
    #
    #   user = User.create
    #   post = Post.create
    #
    #   user.posts.add(post)
    #
    def add(model)
      redis.sadd(key, model.id)
    end

    # 2017-3-21 lt
    # optimize: no need to find model before call methods
    def add_id(id)
      redis.sadd(key, id)
    end

    alias_method :<<, :add

    # Remove a model directly from the set.
    #
    # Example:
    #
    #   user = User.create
    #   post = Post.create
    #
    #   user.posts.delete(post)
    #
    def delete(model)
      redis.srem(key, model.id)
    end

    # 2017-3-21 lt
    # optimize: no need to find model before call methods
    def delete_id(id)
      redis.srem(key, id)
    end

    # Replace all the existing elements of a set with a different
    # collection of models. This happens atomically in a MULTI-EXEC
    # block.
    #
    # Example:
    #
    #   user = User.create
    #   p1 = Post.create
    #   user.posts.add(p1)
    #
    #   p2, p3 = Post.create, Post.create
    #   user.posts.replace([p2, p3])
    #
    #   user.posts.include?(p1)
    #   # => false
    #
    def replace(models)
      ids = models.map(&:id)
      redis.del(key)
      redis.sadd(key, ids) unless ids.empty?
    end

    def sinter(other)
      redis.sinter(key, other.key)
    end

    def sunion(other)
      redis.sunion(key, other.key)
    end

  end
end
