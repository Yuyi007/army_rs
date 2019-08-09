# The base class for all your models. In order to better understand
# it, here is a semi-realtime explanation of the details involved
# when creating a User instance.
#
# Example:
#
#   class User < Ohm::Model
#     attribute :name
#     index :name
#
#     attribute :email
#     unique :email
#
#     counter :points
#
#     set :posts, :Post
#   end
#
#   u = User.create(:name => "John", :email => "foo@bar.com")
#   u.incr :points
#   u.posts.add(Post.create)
#
# When you execute `User.create(...)`, you run the following Redis
# commands:
#
#   # Generate an ID
#   INCR User:id
#
#   # Add the newly generated ID, (let's assume the ID is 1).
#   SADD User:all 1
#
#   # Store the unique index
#   HSET User:uniques:email foo@bar.com 1
#
#   # Store the name index
#   SADD User:indices:name:John 1
#
#   # Store the HASH
#   HMSET User:1 name John email foo@bar.com
#
# Next we increment points:
#
#   HINCR User:1:counters points 1
#
# And then we add a Post to the `posts` set.
# (For brevity, let's assume the Post created has an ID of 1).
#
#   SADD User:1:posts 1
#
module Ohm
  class Model
    class << self
      attr_writer :redis
    end

    def self.redis
      defined?(@redis) ? @redis : Ohm.redis
    end

    def self.mutex
      @@mutex ||= Mutex.new
    end

    def self.synchronize(&block)
      mutex.synchronize(&block)
    end

    # Returns the namespace for all the keys generated using this model.
    #
    # Example:
    #
    #   class User < Ohm::Model
    #   end
    #
    #   User.key == "User"
    #   User.key.kind_of?(String)
    #   # => true
    #
    #   User.key.kind_of?(Nido)
    #   # => true
    #
    # To find out more about Nido, see:
    #   http://github.com/soveran/nido
    #
    def self.key
      @key ||= Nido.new(name)
    end

    # Retrieve a record by ID.
    #
    # Example:
    #
    #   u = User.create
    #   u == User[u.id]
    #   # =>  true
    #
    def self.[](id)
      get(id)
    end

    # Get the record by given id
    # Example:
    #
    #   u = User.create
    #   u == User.get(u.id)
    #   # =>  true
    #
    def self.get(id)
      # new(id: id).load! if id && exists?(id)
      new(id: id).load! if id
    end

    # Retrieve a set of models given an array of IDs.
    #
    # Example:
    #
    #   ids = [1, 2, 3]
    #   ids.map(&User)
    #
    # Note: The use of this should be a last resort for your actual
    # application runtime, or for simply debugging in your console. If
    # you care about performance, you should pipeline your reads. For
    # more information checkout the implementation of Ohm::List#fetch.
    #
    def self.to_proc
      ->(id) { self[id] }
    end

    # Check if the ID exists within <Model>:all.
    def self.exists?(id)
      redis.sismember(key[:all], id)
    end

    WITH = %{
      local att_key, namespace = unpack(KEYS)
      local val = ARGV[1]
      local id = tostring(redis.call('hget', att_key, val))
      local key = namespace .. ':'.. id
      local data = redis.call('hgetall', key)
      if id ~= 'nil' and id ~= nil and id ~= 'false' then
        data[#data + 1] = 'id'
        data[#data + 1] = id
      else
        return nil
      end

      return cjson.encode(data)
    }

    # Find values in `unique` indices.
    #
    # Example:
    #
    #   class User < Ohm::Model
    #     unique :email
    #   end
    #
    #   u = User.create(:email => "foo@bar.com")
    #   u == User.with(:email, "foo@bar.com")
    #   # => true
    #
    def self.with(att, val)
      fail IndexNotFound unless uniques.include?(att)
      att_key = key[:uniques][att].to_s
      data_raw = redis.evalsmart(WITH, keys: [att_key, key], argv: [val])
      if data_raw
        data_raw = Oj.load(data_raw)
        data = hashify(data_raw)
        new(data.update(id: data.id))
      end
    end

    WITH_MULTI = %{
      local att_key, namespace = unpack(KEYS)
      local values = ARGV
      local list = {}
      for i = 1, #values do
        local val = values[i]
        local id = tostring(redis.call('hget', att_key, val))
        local key = namespace .. ':'.. id
        local data = redis.call('hgetall', key)
        if id ~= 'nil' and id ~= nil and id ~= 'false' then
          data[#data + 1] = 'id'
          data[#data + 1] = id
          list[#list + 1] = data
        end
      end

      return cjson.encode(list)
    }

    #
    # retrieve multiple models with the unique index
    # @param att [string] the unique att
    # @param vals [array] array of the att values
    #
    # @return [Array] array of models
    def self.with_multi(att, vals)
      fail IndexNotFound unless uniques.include?(att)
      att_key = key[:uniques][att].to_s

      data_raw = redis.evalsmart(WITH_MULTI, keys: [att_key, key], argv: vals)
      data_array = Oj.load(data_raw)
      data = data_array.map do |a|
        hashify(a)
      end

      return [] if data.nil?

      [].tap do |result|
        data.each_with_index do |atts, _idx|
          result << new(atts.update(id: atts.id)) if atts
        end
      end
    end

    WITH_MULTI_FETCH_ATTR = %{
      local att_key, namespace = unpack(KEYS)
      local attr_to_fetch = table.remove(ARGV, 1)
      local values = ARGV

      local list = {}
      for i = 1, #values do
        local val = values[i]
        local id = tostring(redis.call('hget', att_key, val))
        local key = namespace .. ':'.. id
        local fetch_value = redis.call('hget', key, attr_to_fetch)
        if id ~= 'nil' and id ~= nil and id ~= 'false' then
          list[#list + 1] = fetch_value
        else
          list[#list + 1] = 'nil'
        end
      end

      return list
    }

    #
    # retrieve multiple models with the unique index
    # @param att [string] the unique att
    # @param vals [array] array of the att values
    # @param att2 [string] the att2 to fetch
    #
    # @return [Array] array of values of the att2
    def self.with_multi_fetch_attr(att, vals, att2)
      fail IndexNotFound unless uniques.include?(att)
      att_key = key[:uniques][att].to_s

      list = redis.evalsmart(WITH_MULTI_FETCH_ATTR, keys: [att_key, key], argv: [att2] + vals)
    end


    def self.hashify(array)
      hash = {}
      array.each_slice(2) do |field, value|
        hash[field] = value
      end
      hash
    end

    # less redis ops and faster search than original find()
    # original find() has been renamed to find_multi()
    def self.find(dict)
      keys = filters(dict)

      Ohm::MemorySet.new(keys, key, self, :sinter)
    end

    # Find values in indexed fields.
    #
    # Example:
    #
    #   class User < Ohm::Model
    #     attribute :email
    #
    #     attribute :name
    #     index :name
    #
    #     attribute :status
    #     index :status
    #
    #     index :provider
    #     index :tag
    #
    #     def provider
    #       email[/@(.*?).com/, 1]
    #     end
    #
    #     def tag
    #       ["ruby", "python"]
    #     end
    #   end
    #
    #   u = User.create(name: "John", status: "pending", email: "foo@me.com")
    #   User.find(provider: "me", name: "John", status: "pending").include?(u)
    #   # => true
    #
    #   User.find(:tag => "ruby").include?(u)
    #   # => true
    #
    #   User.find(:tag => "python").include?(u)
    #   # => true
    #
    #   User.find(:tag => ["ruby", "python"]).include?(u)
    #   # => true
    #
    def self.find_multi(dict)
      keys = filters(dict)

      if keys.size == 1
        Ohm::Set.new(keys.first, key, self)
      else
        Ohm::MultiSet.new(key, self, Command.new(:sinterstore, *keys))
      end
    end

    def self.save_multi(collection)
      # Ensure the uniqueness in the collection before save
      # Assuming the last one in the collection is the latest one
      hash = {}
      collection.each do |o|
        next if o.nil?
        hash[o.id] = o
      end

      list = hash.values

      fa = []
      sa = []
      ia = []
      ua = []

      list.each do |data|
        f, s, i, u = data.save_info
        fa << f
        sa << s
        ia << i
        ua << u
      end

      redis.evalsmart(
        LUA_SAVE_MULTI,
        keys: [key[:all]],
        argv: [fa.to_msgpack,
               sa.to_msgpack,
               ia.to_msgpack,
               ua.to_msgpack
              ]
      )
    end

    def self.delete_multi(collection)
      marr = []
      uarr = []
      tarr = []

      ####################################
      # no check for the size of the collection
      # because check the size is also a redis operation
      ####################################

      collection.each do |data|
        m, u, t = data.delete_info
        marr << m
        uarr << u
        tarr << t
      end

      redis.evalsmart(
        LUA_DELETE_MULTI,
        keys: [key[:all]],
        argv: [marr.to_msgpack,
               uarr.to_msgpack,
               tarr.to_msgpack
              ]
      )
    end

    # Retrieve a set of models given an array of IDs.
    #
    # Example:
    #
    #   User.fetch([1, 2, 3])
    #
    def self.fetch(ids)
      all.fetch(ids)
    end

    #
    # Fetch a simple list of attrs on the collection
    # @param attr [array] array of ids of the model
    # @param ids [array] array of ids, can be nil
    #
    # @return [array] array of the attrs of the models
    def self.fetch_attrs(attr, ids = nil)
      all.fetch_attrs(attr, ids)
    end

    # Index any method on your model. Once you index a method, you can
    # use it in `find` statements.
    def self.index(attribute)
      indices << attribute unless indices.include?(attribute)
    end

    # Create a unique index for any method on your model. Once you add
    # a unique index, you can use it in `with` statements.
    #
    # Note: if there is a conflict while saving, an
    # `Ohm::UniqueIndexViolation` violation is raised.
    #
    def self.unique(attribute)
      uniques << attribute unless uniques.include?(attribute)
    end

    # Declare an Ohm::Set with the given name.
    #
    # Example:
    #
    #   class User < Ohm::Model
    #     set :posts, :Post
    #   end
    #
    #   u = User.create
    #   u.posts.empty?
    #   # => true
    #
    # Note: You can't use the set until you save the model. If you try
    # to do it, you'll receive an Ohm::MissingID error.
    #
    def self.set(name, model)
      track(name)

      define_method name do
        model = Utils.const(self.class, model)
        Ohm::MutableSet.new(key[name], model.key, model)
      end
    end

    def self.sorted_set(name, model, sort_with)
      track(name)

      define_method name do
        model = Utils.const(self.class, model)
        Ohm::SortedSet.new(key[name], model.key, model, sort_with)
      end
    end

    # Declare an Ohm::List with the given name.
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
    #   p.comments.push(Comment.create)
    #   p.comments.unshift(Comment.create)
    #   p.comments.size == 2
    #   # => true
    #
    # Note: You can't use the list until you save the model. If you try
    # to do it, you'll receive an Ohm::MissingID error.
    #
    def self.list(name, model)
      track(name)

      define_method name do
        model = Utils.const(self.class, model)
        Ohm::List.new(key[name], model.key, model)
      end
    end

    # A macro for defining a method which basically does a find.
    #
    # Example:
    #   class Post < Ohm::Model
    #     reference :user, :User
    #   end
    #
    #   class User < Ohm::Model
    #     collection :posts, :Post
    #   end
    #
    #   # is the same as
    #
    #   class User < Ohm::Model
    #     def posts
    #       Post.find(:user_id => self.id)
    #     end
    #   end
    #
    def self.collection(name, model, reference = to_reference)
      define_method name do
        model = Utils.const(self.class, model)
        model.find(:"#{reference}_id" => id)
      end
    end

    # A macro for defining an attribute, an index, and an accessor
    # for a given model.
    #
    # Example:
    #
    #   class Post < Ohm::Model
    #     reference :user, :User
    #   end
    #
    #   # It's the same as:
    #
    #   class Post < Ohm::Model
    #     attribute :user_id
    #     index :user_id
    #
    #     def user
    #       @_memo[:user] ||= User[user_id]
    #     end
    #
    #     def user=(user)
    #       self.user_id = user.id
    #       @_memo[:user] = user
    #     end
    #
    #     def user_id=(user_id)
    #       @_memo.delete(:user_id)
    #       self.user_id = user_id
    #     end
    #   end
    #
    def self.reference(name, model)
      reader = :"#{name}_id"
      writer = :"#{name}_id="

      attributes << reader unless attributes.include?(reader)

      index reader

      define_method(reader) do
        @attributes[reader]
      end

      define_method(writer) do |value|
        @_memo.delete(name)
        @attributes[reader] = value
      end

      define_method(:"#{name}=") do |value|
        @_memo.delete(name)
        send(writer, value ? value.id : nil)
      end

      define_method(name) do
        @_memo[name] ||= begin
          model = Utils.const(self.class, model)
          model[send(reader)]
        end
      end
    end

    # The bread and butter macro of all models. Basically declares
    # persisted attributes. All attributes are stored on the Redis
    # hash.
    #
    #   class User < Ohm::Model
    #     attribute :name
    #   end
    #
    #   user = User.new(name: "John")
    #   user.name
    #   # => "John"
    #
    #   user.name = "Jane"
    #   user.name
    #   # => "Jane"
    #
    # A +lambda+ can be passed as a second parameter to add
    # typecasting support to the attribute.
    #
    #   class User < Ohm::Model
    #     attribute :age, ->(x) { x.to_i }
    #   end
    #
    #   user = User.new(age: 100)
    #
    #   user.age
    #   # => 100
    #
    #   user.age.kind_of?(Integer)
    #   # => true
    #
    # Check http://rubydoc.info/github/cyx/ohm-contrib#Ohm__DataTypes
    # to see more examples about the typecasting feature.
    #
    def self.attribute(name, cast = nil)
      attributes << name unless attributes.include?(name)

      if cast
        define_method(name) do
          @attributes[name] = cast[@attributes[name]]
          @attributes[name]
        end
      else
        define_method(name) do
          @attributes[name]
        end
      end

      define_method(:"#{name}=") do |value|
        @attributes[name] = value
      end
    end

    # Declare a counter. All the counters are internally stored in
    # a different Redis hash, independent from the one that stores
    # the model attributes. Counters are updated with the `incr` and
    # `decr` methods, which interact directly with Redis. Their value
    # can't be assigned as with regular attributes.
    #
    # Example:
    #
    #   class User < Ohm::Model
    #     counter :points
    #   end
    #
    #   u = User.create
    #   u.incr :points
    #
    #   u.points
    #   # => 1
    #
    # Note: You can't use counters until you save the model. If you
    # try to do it, you'll receive an Ohm::MissingID error.
    #
    def self.counter(name)
      counters << name unless counters.include?(name)

      define_method(name) do
        return 0 if new?
        redis.hget(key[:counters], name).to_i
      end
    end

    # Keep track of `key[name]` and remove when deleting the object.
    def self.track(name)
      tracked << name unless tracked.include?(name)
    end

    # An Ohm::Set wrapper for Model.key[:all].
    def self.all
      Set.new(key[:all], key, self)
    end

    # Syntactic sugar for Model.new(atts).save
    def self.create(atts = {})
      new(atts).save
    end

    # Returns the namespace for the keys generated using this model.
    # Check `Ohm::Model.key` documentation for more details.
    def key
      model.key[id]
    end

    # Initialize a model using a dictionary of attributes.
    #
    # Example:
    #
    #   u = User.new(:name => "John")
    #
    def initialize(atts = {})
      @attributes = {}
      @_memo = {}
      update_attributes(atts)
    end

    # Access the ID used to store this model. The ID is used together
    # with the name of the class in order to form the Redis key.
    #
    # Example:
    #
    #   class User < Ohm::Model; end
    #
    #   u = User.create
    #   u.id
    #   # => 1
    #
    #   u.key
    #   # => User:1
    #
    def id
      fail MissingID unless defined?(@id)
      @id
    end

    # Check for equality by doing the following assertions:
    #
    # 1. That the passed model is of the same type.
    # 2. That they represent the same Redis key.
    #
    def ==(other)
      other.is_a?(model) && other.key == key
    rescue MissingID
      false
    end

    # Preload all the attributes of this model from Redis. Used
    # internally by `Model::[]`.
    def load!
      # 2017-3-17 lt
      # return nil if key is empty to save a sismember ops
      attrs = redis.hgetall(key)
      return nil if attrs.length == 0

      update_attributes(attrs) unless new?
      self
    end

    # Read an attribute remotely from Redis. Useful if you want to get
    # the most recent value of the attribute and not rely on locally
    # cached value.
    #
    # Example:
    #
    #   User.create(:name => "A")
    #
    #   Session 1     |    Session 2
    #   --------------|------------------------
    #   u = User[1]   |    u = User[1]
    #   u.name = "B"  |
    #   u.save        |
    #                 |    u.name == "A"
    #                 |    u.get(:name) == "B"
    #
    def get(att)
      @attributes[att] = redis.hget(key, att)
      send(att) if respond_to?(att)
    end

    # Update an attribute value atomically. The best usecase for this
    # is when you simply want to update one value.
    #
    # Note: This method is dangerous because it doesn't update indices
    # and uniques. Use it wisely. The safe equivalent is `update`.
    #
    def set(att, val)
      att = att.to_sym
      if val.to_s.empty?
        redis.hdel(key, att)
      else
        redis.hset(key, att, val)
      end

      @attributes[att] = val
    end

    # Returns +true+ if the model is not persisted. Otherwise, returns +false+.
    #
    # Example:
    #
    #   class User < Ohm::Model
    #     attribute :name
    #   end
    #
    #   u = User.new(:name => "John")
    #   u.new?
    #   # => true
    #
    #   u.save
    #   u.new?
    #   # => false
    def new?
      !defined?(@id)
    end

    INCR_CLAMP = %{
      local counter_key = unpack(KEYS)
      local att, count, min, max = unpack(ARGV)
      local num = redis.call('hget', counter_key, att) or 0
      if max and max ~= '' then max = tonumber(max) end
      if min and min ~= '' then min = tonumber(min) end
      count = tonumber(count)
      num = tonumber(num)
      local res_num = num + count
      if max and max ~= '' and res_num > max then res_num = max end
      if min and min ~= '' and res_num < min then res_num = min end
      count = res_num - num
      return redis.call('hincrby', counter_key, att, count)
    }

    def incr_clamp(att, count = 1, min = '', max = '')
      redis.evalsmart(INCR_CLAMP,
                      keys: [key[:counters]],
                      argv: [att, count, min, max])
    end

    def decr_clamp(att, count = 1, min = '', max = '')
      incr_clamp(att, -count, min, max)
    end

    def set_counter(att, num)
      redis.hset(key[:counters], att, num)
    end

    # Incr the normal attribute (of which tag is 'attribute' and type is integer)]
    # @param att [string] [description]
    # @param num [integer] [description]
    def incr_attr(att, num)
      att = att.to_sym
      @attributes[att] = redis.hincrby(key, att, num)
    end

    # multi update automaticly for multiple attributes
    def mset(*attrs)
      redis.hmset(key, *attrs)

      attrs.each_slice(2) do |k, v|
        k = k.to_sym
        @attributes[k] = v
      end
    end

    # Increment a counter atomically. Internally uses HINCRBY.
    def incr(att, count = 1)
      redis.hincrby(key[:counters], att, count)
    end

    # Decrement a counter atomically. Internally uses HINCRBY.
    def decr(att, count = 1)
      incr(att, -count)
    end

    # Return a value that allows the use of models as hash keys.
    #
    # Example:
    #
    #   h = {}
    #
    #   u = User.new
    #
    #   h[:u] = u
    #   h[:u] == u
    #   # => true
    #
    def hash
      new? ? super : key.hash
    end
    alias_method :eql?, :==

    # Returns a hash of the attributes with their names as keys
    # and the values of the attributes as values. It doesn't
    # include the ID of the model.
    #
    # Example:
    #
    #   class User < Ohm::Model
    #     attribute :name
    #   end
    #
    #   u = User.create(:name => "John")
    #   u.attributes
    #   # => { :name => "John" }
    #
    attr_reader :attributes

    # Export the ID of the model. The approach of Ohm is to
    # whitelist public attributes, as opposed to exporting each
    # (possibly sensitive) attribute.
    #
    # Example:
    #
    #   class User < Ohm::Model
    #     attribute :name
    #   end
    #
    #   u = User.create(:name => "John")
    #   u.to_hash
    #   # => { :id => "1" }
    #
    # In order to add additional attributes, you can override `to_hash`:
    #
    #   class User < Ohm::Model
    #     attribute :name
    #
    #     def to_hash
    #       super.merge(:name => name)
    #     end
    #   end
    #
    #   u = User.create(:name => "John")
    #   u.to_hash
    #   # => { :id => "1", :name => "John" }
    #
    def to_hash
      attrs = {}
      attrs[:id] = id unless new?

      attrs
    end

    # Persist the model attributes and update indices and unique
    # indices. The `counter`s and `set`s are not touched during save.
    #
    # Example:
    #
    #   class User < Ohm::Model
    #     attribute :name
    #   end
    #
    #   u = User.new(:name => "John").save
    #   u.kind_of?(User)
    #   # => true
    #
    def save
      fs, sas, is, us = save_info

      response = script(LUA_SAVE,
                        fs.to_msgpack,
                        sas.to_msgpack,
                        is.to_msgpack,
                        us.to_msgpack
                       )

      if response.is_a?(RuntimeError)
        if response.message =~ /(UniqueIndexViolation: (\w+))/
          fail UniqueIndexViolation, Regexp.last_match(1)
        else
          fail response
        end
      end

      @id = response

      self
    end

    def from_hash!(hash)
      model.attributes.each do |key|
        _hash_assign(hash, key)
      end

      self
    end

    def _hash_assign(hash, key)
      if hash.key? key
        send("#{key}=", hash[key])
      elsif hash.key? key.to_s
        send("#{key}=", hash[key.to_s])
      end
    end

    def save_with_lock(&_blk)
      lock(:lock) do |_, _lock|
        obj = model[id]
        obj = yield(obj)
        obj.save
        self.from_hash!(obj.to_hash)
      end
    end

    def lock(hkey)
      RedisLock.new(redis, "#{key}:#{hkey}").lock do |key, lock|
        yield(key, lock)
      end
    end

    def save_info
      indices = {}
      model.indices.each { |field| indices[field] = Array(send(field)) }

      uniques = {}
      model.uniques.each { |field| uniques[field] = send(field) }

      features = {
        'name' => model.key
      }

      # puts "save_info: #{model.key}"
      # puts "indices=#{indices}"
      # puts "uniques=#{uniques}"

      features['id'] = @id if defined?(@id)
      [features, _sanitized_attributes, indices, uniques]
    end

    # Run lua scripts and cache the sha in order to improve
    # successive calls.
    def script(src, *args)
      redis.evalsmart(src, keys: [model.key[:all]], argv: args)
    end

    # Delete the model, including all the following keys:
    #
    # - <Model>:<id>
    # - <Model>:<id>:counters
    # - <Model>:<id>:<set name>
    #
    # If the model has uniques or indices, they're also cleaned up.
    #
    def delete
      model_info, uniques, trackeds = delete_info

      script(LUA_DELETE,
             model_info.to_msgpack,
             uniques.to_msgpack,
             trackeds.to_msgpack
            )

      self
    end

    def delete_info
      model_info = {
        'name' => model.key.to_s,
        'id' => id,
        'key' => key.to_s
      }
      uniques = {}
      model.uniques.each { |field| uniques[field] = send(field) }
      trackeds = model.tracked
      [model_info, uniques, trackeds]
    end

    # Update the model attributes and call save.
    #
    # Example:
    #
    #   User[1].update(:name => "John")
    #
    #   # It's the same as:
    #
    #   u = User[1]
    #   u.update_attributes(:name => "John")
    #   u.save
    #
    def update(attributes)
      update_attributes(attributes)
      save
    end

    # Write the dictionary of key-value pairs to the model.
    def update_attributes(atts)
      atts.each do |att, val|
        send(:"#{att}=", val) if respond_to?("#{att}=", true)
      end
    end

    protected

    def self.to_reference
      name.to_s
        .match(/^(?:.*::)*(.*)$/)[1]
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase.to_sym
    end

    def self.indices
      @indices ||= []
    end

    def self.uniques
      @uniques ||= []
    end

    def self.counters
      @counters ||= []
    end

    def self.tracked
      @tracked ||= []
    end

    def self.attributes
      @attributes ||= []
    end

    def self.filters(dict)
      unless dict.is_a?(Hash)
        fail ArgumentError,
             'You need to supply a hash with filters. ' \
             "If you want to find by ID, use #{self}[id] instead."
      end

      dict.map { |k, v| to_indices(k, v) }.flatten
    end

    def self.to_indices(att, val)
      fail IndexNotFound unless indices.include?(att)

      if val.is_a?(Enumerable)
        val.map { |v| key[:indices][att][v] }
      else
        [key[:indices][att][val]]
      end
    end

    attr_writer :id

    def model
      self.class
    end

    def redis
      model.redis
    end

    def _sanitized_attributes
      result = []

      model.attributes.each do |field|
        val = send(field)

        result.push(field, val.to_s) unless val.nil?
      end

      result
    end
  end
end
