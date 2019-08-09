module Ohm
  class BasicSet
    include Collection

    # Allows you to sort by any attribute in the hash, this doesn't include
    # the +id+. If you want to sort by ID, use #sort.
    #
    #   class User < Ohm::Model
    #     attribute :name
    #   end
    #
    #   User.all.sort_by(:name, :order => "ALPHA")
    #   User.all.sort_by(:name, :order => "ALPHA DESC")
    #   User.all.sort_by(:name, :order => "ALPHA DESC", :limit => [0, 10])
    #
    # Note: This is slower compared to just doing `sort`, specifically
    # because Redis has to read each individual hash in order to sort
    # them.
    #
    def sort_by(att, options = {})
      sort(options.merge(by: to_key(att)))
    end

    # Allows you to sort your models using their IDs. This is much
    # faster than `sort_by`. If you simply want to get records in
    # ascending or descending order, then this is the best method to
    # do that.
    #
    # Example:
    #
    #   class User < Ohm::Model
    #     attribute :name
    #   end
    #
    #   User.create(:name => "John")
    #   User.create(:name => "Jane")
    #
    #   User.all.sort.map(&:id) == ["1", "2"]
    #   # => true
    #
    #   User.all.sort(:order => "ASC").map(&:id) == ["1", "2"]
    #   # => true
    #
    #   User.all.sort(:order => "DESC").map(&:id) == ["2", "1"]
    #   # => true
    #
    def sort(options = {})
      if options.key?(:get)
        options[:get] = to_key(options[:get])
        return execute { |key| Utils.sort(redis, key, options) }
      end

      if options.key?(:store)
        return execute { |key| Utils.sort(redis, key, options) }
      end

      fetch(execute { |key| Utils.sort(redis, key, options) })
    end

    # Check if a model is included in this set.
    #
    # Example:
    #
    #   u = User.create
    #
    #   User.all.include?(u)
    #   # => true
    #
    # Note: Ohm simply checks that the model's ID is included in the
    # set. It doesn't do any form of type checking.
    #
    def include?(model)
      exists?(model.id)
    end

    # 2017-3-21 lt
    # optimize: no need to find model before call methods
    def include_id?(id)
      exists?(id)
    end

    # Returns the total size of the set using SCARD.
    def size
      execute { |key| redis.scard(key) }
    end

    # Syntactic sugar for `sort_by` or `sort` when you only need the
    # first element.
    #
    # Example:
    #
    #   User.all.first ==
    #     User.all.sort(:limit => [0, 1]).first
    #
    #   User.all.first(:by => :name, "ALPHA") ==
    #     User.all.sort_by(:name, :order => "ALPHA", :limit => [0, 1]).first
    #
    def first(options = {})
      opts = options.dup
      opts.merge!(limit: [0, 1])

      if opts[:by]
        sort_by(opts.delete(:by), opts).first
      else
        sort(opts).first
      end
    end

    # Returns an array with all the ID's of the set.
    #
    #   class Post < Ohm::Model
    #   end
    #
    #   class User < Ohm::Model
    #     attribute :name
    #     index :name
    #
    #     set :posts, :Post
    #   end
    #
    #   User.create(name: "John")
    #   User.create(name: "Jane")
    #
    #   User.all.ids
    #   # => ["1", "2"]
    #
    #   User.find(name: "John").union(name: "Jane").ids
    #   # => ["1", "2"]
    #

    def ids
      execute { |key| redis.smembers(key) }
    end

    # Retrieve a specific element using an ID from this set.
    #
    # Example:
    #
    #   # Let's say we got the ID 1 from a request parameter.
    #   id = 1
    #
    #   # Retrieve the post if it's included in the user's posts.
    #   post = user.posts[id]
    #
    def [](id)
      # model[id] if exists?(id)
      model[id]
    end

    # Returns +true+ if +id+ is included in the set. Otherwise, returns +false+.
    #
    # Example:
    #
    #   class Post < Ohm::Model
    #   end
    #
    #   class User < Ohm::Model
    #     set :posts, :Post
    #   end
    #
    #   user = User.create
    #   post = Post.create
    #   user.posts.add(post)
    #
    #   user.posts.exists?('nonexistent') # => false
    #   user.posts.exists?(post.id)       # => true
    #
    def exists?(id)
      execute { |key| redis.sismember(key, id) }
    end

    private

    def to_key(att)
      if model.counters.include?(att)
        namespace['*:counters->%s' % att]
      else
        namespace['*->%s' % att]
      end
    end
  end
end
