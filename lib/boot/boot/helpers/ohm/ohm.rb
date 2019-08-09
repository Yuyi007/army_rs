# encoding: UTF-8

require 'msgpack'
require 'nido'
require 'securerandom'
require_relative 'ohm/command'
require_relative 'ohm/model'
require_relative 'ohm/utils'
require_relative 'ohm/collection/collection'
require_relative 'ohm/collection/basic_set'
require_relative 'ohm/collection/set'
require_relative 'ohm/collection/multi_set'
require_relative 'ohm/collection/mutable_set'
require_relative 'ohm/collection/memory_set'
require_relative 'ohm/collection/list'
require_relative 'ohm/collection/simple_set'
require_relative 'ohm/collection/sorted_set'
require_relative 'ohm/contrib/contrib'

module Ohm
  LUA_CACHE = Hash.new { |h, k| h[k] = {} }

  # All of the known errors in Ohm can be traced back to one of these
  # exceptions.
  #
  # MissingID:
  #
  #   Comment.new.id # => Error
  #   Comment.new.key # => Error
  #
  #   Solution: you need to save your model first.
  #
  # IndexNotFound:
  #
  #   Comment.find(:foo => "Bar") # => Error
  #
  #   Solution: add an index with `Comment.index :foo`.
  #
  # UniqueIndexViolation:
  #
  #   Raised when trying to save an object with a `unique` index for
  #   which the value already exists.
  #
  #   Solution: rescue `Ohm::UniqueIndexViolation` during save, but
  #   also, do some validations even before attempting to save.
  #

  LUA_SAVE_UTIL = %{
    local function save_model(model, attrs, indices, uniques)
      local function save(model, attrs)
        if model.id == nil then
          model.id = redis.call("INCR", model.name .. ":id")
        end

        model.key = model.name .. ":" .. model.id

        redis.call("SADD", model.name .. ":all", model.id)
        redis.call("DEL", model.key)

        if math.mod(#attrs, 2) == 1 then
          error("Wrong number of attribute/value pairs")
        end

        if #attrs > 0 then
          redis.call("HMSET", model.key, unpack(attrs))
        end
      end

      local function index(model, indices)
        for field, enum in pairs(indices) do
          for _, val in ipairs(enum) do
            local key = model.name .. ":indices:" .. field .. ":" .. tostring(val)

            redis.call("SADD", model.key .. ":_indices", key)
            redis.call("SADD", key, model.id)
          end
        end
      end

      local function remove_indices(model)
        local memo = model.key .. ":_indices"
        local existing = redis.call("SMEMBERS", memo)

        for _, key in ipairs(existing) do
          redis.call("SREM", key, model.id)
          redis.call("SREM", memo, key)
        end
      end

      local function unique(model, uniques)
        for field, value in pairs(uniques) do
          local key = model.name .. ":uniques:" .. field

          redis.call("HSET", model.key .. ":_uniques", key, value)
          redis.call("HSET", key, value, model.id)
        end
      end

      local function remove_uniques(model)
        local memo = model.key .. ":_uniques"

        for _, key in pairs(redis.call("HKEYS", memo)) do
          redis.call("HDEL", key, redis.call("HGET", memo, key))
          redis.call("HDEL", memo, key)
        end
      end

      local function verify(model, uniques)
        local duplicates = {}

        for field, value in pairs(uniques) do
          local key = model.name .. ":uniques:" .. field
          local id = redis.call("HGET", key, tostring(value))

          if id and id ~= tostring(model.id) then
            duplicates[#duplicates + 1] = field
          end
        end

        return duplicates, #duplicates ~= 0
      end

      local duplicates, err = verify(model, uniques)

      if err then
        error("UniqueIndexViolation: " .. duplicates[1])
      end

      save(model, attrs)

      remove_indices(model)
      index(model, indices)

      remove_uniques(model, uniques)
      unique(model, uniques)

      return tostring(model.id)
    end
  }

  LUA_SAVE = %{
    -- This script receives four parameters, all encoded with
    -- MessagePack. The decoded values are used for saving a model
    -- instance in Redis, creating or updating a hash as needed and
    -- updating zero or more sets (indices) and zero or more hashes
    -- (unique indices).
    --
    -- # model
    --
    -- Table with one or two attributes:
    --    name (model name)
    --    id (model instance id, optional)
    --
    -- If the id is not provided, it is treated as a new record.
    --
    -- # attrs
    --
    -- Array with attribute/value pairs.
    --
    -- # indices
    --
    -- Fields and values to be indexed. Each key in the indices
    -- table is mapped to an array of values. One index is created
    -- for each field/value pair.
    --
    -- # uniques
    --
    -- Fields and values to be indexed as unique. Unlike indices,
    -- values are not enumerable. If a field/value pair is not unique
    -- (i.e., if there was already a hash entry for that field and
    -- value), an error is returned with the UniqueIndexViolation
    -- message and the field that triggered the error.
    --
    local model   = cmsgpack.unpack(ARGV[1])
    local attrs   = cmsgpack.unpack(ARGV[2])
    local indices = cmsgpack.unpack(ARGV[3])
    local uniques = cmsgpack.unpack(ARGV[4])

    #{LUA_SAVE_UTIL}

    local res = save_model(model, attrs, indices, uniques)
    return res

  }

  LUA_SAVE_MULTI = %{

    local model_list   = cmsgpack.unpack(ARGV[1])
    local attrs_list   = cmsgpack.unpack(ARGV[2])
    local indices_list = cmsgpack.unpack(ARGV[3])
    local uniques_list = cmsgpack.unpack(ARGV[3])

    #{LUA_SAVE_UTIL}

    local res = {}
    for i = 1, #model_list do
      local id = save_model(model_list[i], attrs_list[i], indices_list[i], uniques_list[i])
      table.insert(res, id)
    end

    return res
  }

  LUA_DELETE_UTIL = %{

    local function delete_model(model, uniques, tracked)

      local function remove_indices(model)
        local memo = model.key .. ":_indices"
        local existing = redis.call("SMEMBERS", memo)

        for _, key in ipairs(existing) do
          redis.call("SREM", key, model.id)
          redis.call("SREM", memo, key)
        end
      end

      local function remove_uniques(model, uniques)
        local memo = model.key .. ":_uniques"

        for field, _ in pairs(uniques) do
          local key = model.name .. ":uniques:" .. field

          redis.call("HDEL", key, redis.call("HGET", memo, key))
          redis.call("HDEL", memo, key)
        end
      end

      local function remove_tracked(model, tracked)
        for _, tracked_key in ipairs(tracked) do
          local key = model.key .. ":" .. tracked_key

          redis.call("DEL", key)
        end
      end

      local function delete(model)
        local keys = {
          model.key .. ":counters",
          model.key .. ":_indices",
          model.key .. ":_uniques",
          model.key
        }

        redis.call("SREM", model.name .. ":all", model.id)
        redis.call("DEL", unpack(keys))
      end

      remove_indices(model)
      remove_uniques(model, uniques)
      remove_tracked(model, tracked)
      delete(model)

      return model.id

    end

  }

  LUA_DELETE = %{
    -- This script receives three parameters, all encoded with
    -- MessagePack. The decoded values are used for deleting a model
    -- instance in Redis and removing any reference to it in sets
    -- (indices) and hashes (unique indices).
    --
    -- # model
    --
    -- Table with three attributes:
    --    id (model instance id)
    --    key (hash where the attributes will be saved)
    --    name (model name)
    --
    -- # uniques
    --
    -- Fields and values to be removed from the unique indices.
    --
    -- # tracked
    --
    -- Keys that share the lifecycle of this model instance, that
    -- should be removed as this object is deleted.
    --

    #{LUA_DELETE_UTIL}

    local model   = cmsgpack.unpack(ARGV[1])
    local uniques = cmsgpack.unpack(ARGV[2])
    local tracked = cmsgpack.unpack(ARGV[3])

    return delete_model(model, uniques, tracked)
  }

  LUA_DELETE_MULTI = %{
    -- This script receives three parameters, all encoded with
    -- MessagePack. The decoded values are used for deleting a model
    -- instance in Redis and removing any reference to it in sets
    -- (indices) and hashes (unique indices).
    --
    -- # model
    --
    -- Table with three attributes:
    --    id (model instance id)
    --    key (hash where the attributes will be saved)
    --    name (model name)
    --
    -- # uniques
    --
    -- Fields and values to be removed from the unique indices.
    --
    -- # tracked
    --
    -- Keys that share the lifecycle of this model instance, that
    -- should be removed as this object is deleted.
    --

    #{LUA_DELETE_UTIL}

    local model_list   = cmsgpack.unpack(ARGV[1])
    local uniques_list = cmsgpack.unpack(ARGV[2])
    local tracked_list = cmsgpack.unpack(ARGV[3])

    local res = {}
    for i = 1, #model_list do
      local id = delete_model(model_list[i], uniques_list[i], tracked_list[i])
      table.insert(res, id)
    end

    return res
  }

  class Error < StandardError; end
  class MissingID < Error; end
  class IndexNotFound < Error; end
  class UniqueIndexViolation < Error; end



  # Use this if you want to do quick ad hoc redis commands against the
  # defined Ohm connection.
  #
  # Examples:
  #
  #   Ohm.redis.call("SET", "foo", "bar")
  #   Ohm.redis.call("FLUSH")
  #
  def self.redis
    @redis ||= Redis.new
  end

  def self.redis=(redis)
    @redis = redis
  end

  # Wrapper for Ohm.redis.call("FLUSHDB").
  def self.flush
    # redis.flushdb
  end




  # Defines most of the methods used by `Set` and `MultiSet`.








end
