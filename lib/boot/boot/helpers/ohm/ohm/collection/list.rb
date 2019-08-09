module Ohm
  class List
    include Collection

    attr_reader :key
    attr_reader :namespace
    attr_reader :model

    def initialize(key, namespace, model)
      @key = key
      @namespace = namespace
      @model = model
    end

    # Returns the total size of the list using LLEN.
    def size
      redis.llen(key)
    end

    # Returns the first element of the list using LINDEX.
    def first
      model[redis.lindex(key, 0)]
    end

    # Returns the last element of the list using LINDEX.
    def last
      model[redis.lindex(key, -1)]
    end

    def purge!
      each(&:delete)
      redis.del(key)
    end

    # ltrim the list
    def ltrim(length)
      redis.ltrim(key, 0, length - 1)
    end

    # ltrim the list as well as deleting the models associated
    def ltrim!(length)
      if length > 0 && length < size
        models = range(length, -1)
        model.delete_multi(models)
        redis.ltrim(key, 0, length - 1)
      end
    end

    def delete_by_id(id)
      redis.lrem(key, 0, id)
    end

    MOVE_TO_FRONT = %{
      local key = unpack(KEYS)
      local id = unpack(ARGV)
      local removed = redis.call('lrem', key, 0, id)
      redis.call('lpush', key, id)
      return (removed == 0)
    }

    # move the model to the front of the list (with lpush)
    def move_to_front(model)
      redis.evalsmart(MOVE_TO_FRONT, keys: [key.to_s], argv: [model.id])
    end

    # Returns an array of elements from the list using LRANGE.
    # #range receives 2 integers, start and stop
    #
    # Example:
    #
    #   class Comment < Ohm::Model
    #   end
    #
    #   class Post < Ohm::Model
    #     list :comments, :Comment
    #   end
    #
    #   c1 = Comment.create
    #   c2 = Comment.create
    #   c3 = Comment.create
    #
    #   post = Post.create
    #
    #   post.comments.push(c1)
    #   post.comments.push(c2)
    #   post.comments.push(c3)
    #
    #   [c1, c2] == post.comments.range(0, 1)
    #   # => true
    def range(start, stop)
      fetch(redis.lrange(key, start, stop))
    end

    # Checks if the model is part of this List.
    #
    # An important thing to note is that this method loads all of the
    # elements of the List since there is no command in Redis that
    # allows you to actually check the list contents efficiently.
    #
    # You may want to avoid doing this if your list has say, 10K entries.
    def include?(model)
      ids.include?(model.id)
    end

    # 2017-3-21 lt
    # optimize: no need to find model before call methods
    def include_id?(id)
      ids.include?(id)
    end

    # Replace all the existing elements of a list with a different
    # collection of models. This happens atomically in a MULTI-EXEC
    # block.
    #
    # Example:
    #
    #   user = User.create
    #   p1 = Post.create
    #   user.posts.push(p1)
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
      redis.rpush(key, ids) unless ids.empty?
    end

    # Pushes the model to the _end_ of the list using RPUSH.
    def push(model)
      redis.rpush(key, model.id)
    end

    # 2017-3-21 lt
    # optimize: no need to find model before call methods
    def push_id(id)
      redis.rpush(key, id)
    end

    # Pushes the model to the _beginning_ of the list using LPUSH.
    def unshift(model)
      redis.lpush(key, model.id)
    end

    # 2017-3-21 lt
    # optimize: no need to find model before call methods
    def unshift_id(id)
      redis.lpush(key, id)
    end

    def shift
      redis.lpop(key)
    end

    # Delete a model from the list.
    #
    # Note: If your list contains the model multiple times, this method
    # will delete all instances of that model in one go.
    #
    # Example:
    #
    #   class Comment < Ohm::Model
    #   end
    #
    #   class Post < Ohm::Model
    #     list :comments, :Comment
    #   end
    #
    #   p = Post.create
    #   c = Comment.create
    #
    #   p.comments.push(c)
    #   p.comments.push(c)
    #
    #   p.comments.delete(c)
    #
    #   p.comments.size == 0
    #   # => true
    #
    def delete(model)
      # LREM key 0 <id> means remove all elements matching <id>
      # @see http://redis.io/commands/lrem
      redis.lrem(key, 0, model.id)
    end

    # 2017-3-21 lt
    # optimize: no need to find model before call methods
    def delete_id(id)
      redis.lrem(key, 0, id)
    end

    # Returns an array with all the ID's of the list.
    #
    #   class Comment < Ohm::Model
    #   end
    #
    #   class Post < Ohm::Model
    #     list :comments, :Comment
    #   end
    #
    #   post = Post.create
    #   post.comments.push(Comment.create)
    #   post.comments.push(Comment.create)
    #   post.comments.push(Comment.create)
    #
    #   post.comments.map(&:id)
    #   # => ["1", "2", "3"]
    #
    #   post.comments.ids
    #   # => ["1", "2", "3"]
    #
    def ids
      redis.lrange(key, 0, -1)
    end

    private

    def redis
      model.redis
    end
  end
end
