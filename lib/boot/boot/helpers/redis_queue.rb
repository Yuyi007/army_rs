# redis_queue.rb
# Redis reliable queue implementation
# Credit from https://github.com/taganaka/redis-queue

module Boot

  class RedisQueue

    VERSION = "0.0.4"

    def self.version
      "redis-queue version #{VERSION}"
    end

    def initialize(queue_name, process_queue_name, options = {})
      raise ArgumentError, 'First argument must be a non empty string'  if !queue_name.is_a?(String) || queue_name.empty?
      raise ArgumentError, 'Second argument must be a non empty string' if !process_queue_name.is_a?(String) || process_queue_name.empty?
      raise ArgumentError, 'Queue and Process queue have the same name'  if process_queue_name == queue_name

      @redis = options[:redis] || Redis.current
      @queue_name = queue_name
      @process_queue_name = process_queue_name
      @last_message = nil
      @timeout = options[:timeout] ||= 0
    end

    def name
      @queue_name
    end

    def length
      @redis.llen @queue_name
    end

    def process_length
      @redis.llen @process_queue_name
    end

    def clear(clear_process_queue = false)
      @redis.del @queue_name
      self.clear_process_queue if clear_process_queue
    end

    def clear_process_queue
      @redis.del @process_queue_name
    end

    def empty?
      !(length > 0)
    end

    def push(obj)
      @redis.lpush(@queue_name, obj)
    end

    def push_batch(*args)
      @redis.lpush_batch(@queue_name, *args)
    end

    def pop(non_block=false)
      if non_block
        @last_message = @redis.rpoplpush(@queue_name,@process_queue_name)
      else
        @last_message = @redis.brpoplpush(@queue_name,@process_queue_name, @timeout)
      end
      @last_message
    end

    def commit
      @redis.lrem(@process_queue_name, 0, @last_message)
    end

    def process(non_block=false, timeout = nil, &blk)
      @timeout = timeout unless timeout.nil?
      loop do
        message = process_one non_block, &blk
        break if message.nil? || (non_block && empty?)
      end
    end

    def process_one(non_block=false)
      message = pop(non_block)
      ret = yield message if block_given?
      commit if ret
      message
    end

    def refill
      while message=@redis.lpop(@process_queue_name)
        @redis.rpush(@queue_name, message)
      end
      true
    end

    alias :size  :length
    alias :dec   :pop
    alias :shift :pop
    alias :enc   :push
    alias :<<    :push
  end

end