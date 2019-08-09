#less redis ops and faster searching
module Ohm
  class MemorySet < Ohm::BasicSet
    attr_reader :keys
    attr_reader :namespace
    attr_reader :criteria
    attr_reader :model
    attr_reader :results

    def initialize(keys, namespace, model, criteria)
      @keys = keys
      @namespace = namespace
      @model = model
      @criteria = criteria
    end

    def sort_by(att, options = {})
      sort(options.merge(by: att))
    end

    def sort(options = {})
      fetch_results

      fail 'MemorySet does not support sort/get!' if options.key?(:get)

      fail 'MemorySet does not support sort/store!' if options.key?(:store)

      @results.sort
      fetch(@results)
    end

    def first(options = {})
      opts = options.dup
      opts.merge!(limit: [0, 1])

      if opts[:by]
        sort_by(opts.delete(:by), opts).first
      else
        sort(opts).first
      end
    end

    def include?(model)
      exists?(model.id)
    end

    # optimize: no need to find model before call methods
    def include_id?(id)
      exists?(id)
    end

    def size
      fetch_results
      @results.size
    end

    def ids
      fetch_results
      @results
    end

    def exists?(id)
      fetch_results
      @results.include?(id)
    end

    # TODO: support chaining by passing current results to a new MemorySet
    def find(_dict)
      fail 'MemorySet does not support chaining yet!'
    end

    def except(_dict)
      fail 'MemorySet does not support chaining yet!'
    end

    def union(_dict)
      fail 'MemorySet does not support chaining yet!'
    end

    # reset results to fetch again
    def reset
      @results = nil
    end

    private

    def fetch_results
      return if @results

      # puts "MemorySet.fetch_results: criteria=#{@criteria} keys=#{@keys}"

      if @criteria == :sinter
        @results = redis.sinter(@keys)
      elsif @criteria == :sdiff
        @results = redis.sdiff(@keys)
      elsif @criteria == :sunion
        @results = redis.sunion(@keys)
      else
        fail "MemorySet: invalid criteria #{@criteria}!"
      end

      # puts "MemorySet.fetch_results: results=#{@results}"
    end

    def redis
      model.redis
    end
  end
end
