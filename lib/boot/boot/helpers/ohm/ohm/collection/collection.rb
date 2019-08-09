module Ohm
  module Collection
    include Enumerable

    def each
      if block_given?
        ids.each_slice(1000) do |slice|
          fetch(slice).each { |e| yield(e) }
        end
      else
        to_enum
      end
    end

    # Fetch the data from Redis in one go.
    def to_a
      fetch(ids)
    end

    def empty?
      size == 0
    end

    # Wraps the whole pipelining functionality.

    FETCH = %{
      table.remove(KEYS, 1)
      local keys = KEYS
      local list = {}
      for i = 1, #keys do
        local key = keys[i]
        local data = redis.call('hgetall', key)
        list[#list + 1] = data
      end

      return cjson.encode(list)
    }

    FETCH_ATTRS = %{
      table.remove(KEYS, 1)
      local keys = KEYS
      local attr = ARGV[1]
      local list = {}
      for i = 1, #keys do
        local key = keys[i]
        local value = redis.call('hget', key, attr)
        if value == nil then value = 'nil' end
        list[#list + 1] = value
      end

      return list
    }

    def hashify(array)
      hash = {}
      array.each_slice(2) do |field, value|
        hash[field] = value
      end
      hash
    end

    def fetch_attrs(attr, ids = nil)
      ids = ids || self.ids
      redis.evalsmart(FETCH_ATTRS, keys: [model.key[:all]].concat(ids.map { |id| namespace[id].to_s }), argv: [attr.to_s])
    end

    def fetch(ids)
      data = nil

      data_raw = redis.evalsmart(FETCH, keys: [model.key[:all]].concat(ids.map { |id| namespace[id].to_s }), argv: [])
      data_array = Oj.load(data_raw)
      data = data_array.map do |a|
        hashify(a)
      end

      return [] if data.nil?

      [].tap do |result|
        data.each_with_index do |atts, idx|
          result << model.new(atts.update(id: ids[idx])) if atts
        end
      end
    end
  end
end
