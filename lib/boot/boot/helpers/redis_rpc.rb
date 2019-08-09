# redis_rpc.rb
# RPC implementation based on RedisQueue
# Aims to be simple and cross-platform
# The protocol use a json-rpc like format

module Boot

  module RedisRpc

    DEFAULT_POLL_INTERVAL = 0.1 unless defined? DEFAULT_POLL_INTERVAL
    DEFAULT_CALL_TIMEOUT = 6.0 unless defined? DEFAULT_CALL_TIMEOUT
    DEFAULT_MAX_QUEUE_LENGTH = 1000 unless defined? DEFAULT_MAX_QUEUE_LENGTH

    # Module interface, provide helper methods over RpcEndpoint

    def self.instance; @instance; end

    def self.worker
      if @instance
        @instance.worker
      end
    end

    # call: call rpc with return value
    #
    # @param klass the rpc function job class
    # @param [String] server_id destination server id
    # @param args args to be passed to rpc function class
    # @return the return value of rpc function
    def self.call(klass, server_id, *args)
      if @instance
        @instance.call(klass, server_id, *args)
      end
    end

    # cast: call rpc without return value
    #
    # @param klass the rpc function job class
    # @param [String] server_id destination server id
    # @param args args to be passed to rpc function class
    # @return [String] the id of the rpc call
    def self.cast(klass, server_id, *args)
      if @instance
        @instance.cast(klass, server_id, *args)
      end
    end

    # init RedisRpc module
    # init a RpcEndpoint object and use it as a singleton
    #
    # @param redis the redis instance for rpc
    # @param [Hash] options options
    # @return the singleton
    def self.init redis, options = {}
      raise "RedisRpc was already inited!" if @instance
      @instance = RpcEndpoint.new(redis, options)
    end

    # destroy the RedisRpc singleton, allow RedisRpc to init again
    def self.destroy redis = nil
      if @instance
        @instance.cleanup(redis)
        @instance = nil
      end
    end

    # start the RedisRpc work loop for handling rpc calls and replies
    # @param [Proc] blk a block that is called everytime a call or reply is processed
    def self.work_loop &blk
      @instance.worker.work_loop &blk
    end

    # RpcEndpoint is the main RedisRpc class that can be initialized
    class RpcEndpoint

      attr_reader :redis, :worker, :my_id

      def call(klass, server_id, *args)
        get_stub(klass, server_id).call(*args)
      end

      def cast(klass, server_id, *args)
        get_stub(klass, server_id).cast(*args)
      end

      def get_stub(klass, server_id)
        Stub.new(self, klass, server_id, @options)
      end

      def initialize redis, options = {}
        @redis = redis
        @my_id = options[:my_id] || AppConfig.server_id
        @options = options

        # lock on my id, avoid two instances sharing the same id
        # set a small timeout since rails do not destroy the endpoint when terminates
        if not @redis.set(lock_key, 1, :ex => 90, :nx => true)
          raise "RpcEndpoint acquires unique lock #{lock_key} failure!"
        end
        @redis.hset(reg_key, @my_id, Time.now.to_f)

        @worker = Worker.new self, @options
      end

      def cleanup redis = nil
        if @worker
          # when cleanup, we should use failsafe redis unless specified
          redis = redis || RedisHelper_.get_redis
          redis.del(lock_key)
          redis.hdel(reg_key, @my_id)
        end
      end

      def all_registered_ids
        @redis.hkeys(reg_key)
      end

      def lock_key
        Boot::RedisHelper_.redis_key_by_tag 'rpc_lock', @my_id
      end

      def reg_key
        'rpc_endpoint_registry'
      end

    end

    # Call job is a RedisMessageQueue job for storing rpc requests
    class CallJob

      @queue = ''

      def self.set_server_id(my_id); @queue = "rrcj_#{my_id}"; end

      def self.perform *args
        # left as empty intentionaly
      end

    end

    # Reply job is a RedisMessageQueue job for storing rpc replies
    class ReplyJob

      @queue = ''

      def self.set_server_id(server_id); @queue = "rrrj_#{server_id}"; end

      def self.perform *args
        # left as empty intentionaly
      end

    end

    # Client stub for initiating remote procedure calls on client side
    class Stub

      include Loggable

      def initialize rpc, klass, server_id, options = {}
        @options = options
        @options[:redis] = rpc.redis

        @klass = klass
        @server_id = server_id
        @my_id = rpc.my_id
        @worker = rpc.worker
        @redis = rpc.redis
        @call_timeout = options[:call_timeout] || DEFAULT_CALL_TIMEOUT
        @poll_interval ||= options[:poll_interval] || DEFAULT_POLL_INTERVAL
        @max_queue_length = options[:max_queue_length] || DEFAULT_MAX_QUEUE_LENGTH

        CallJob.set_server_id(server_id)
        @call_queue = RedisMessageQueue::Queue.new(@redis, RedisRpc::CallJob, @options)
      end

      def call(*args)
        call_id = cast(*args)
        puts ">>>>>>call_id:#{call_id}"
        wait_for_result(call_id)
      end

      CALL_COUNTER_BLOB = %Q{
        local key = KEYS[1]
        local val = redis.call('incr', key)
        if val > 1000000000 then
          if redis.call('set', key, '1') then
            val = 1
          end
        end
        return val
      }

      def cast(*args)
        raise ServerBusyError.new('call queue is full') unless @call_queue.length < @max_queue_length

        call_counter = @redis.evalsmart(CALL_COUNTER_BLOB,
          :keys => [ counter_key ], :argv => [])
        call_id = "#{@my_id}-#{call_counter}"

        rpc_call = {
          'id' => call_id,
          'class' => @klass.to_s,
          'args' => args,
          'reply-to' => @my_id,
        }
        @call_queue.enqueue('rpc_call', rpc_call)

        call_id
      end

      def wait_for_result(call_id)
        @worker.add_waiting_call(call_id, self)

        @cur_result = nil
        @returned = false
        wait_time = 0

        while !@returned do
          Boot::Helper.sleep @poll_interval

          wait_time = wait_time + @poll_interval
          if wait_time > @call_timeout then
            @worker.remove_waiting_call(call_id)
            raise CallTimeoutError.new("call #{call_id} timeout: wait_time=#{wait_time}")
          end

          @worker.process_reply_queue
        end

        if @cur_result =~ /^call_error/ then
          raise CallError.new("call #{call_id} error: #{@cur_result}")
        else
          @cur_result
        end
      end

      def notify_result call_id, result
        @cur_result = result
        @returned = true
      end

    # private

      def counter_key
        "#{@my_id}_call_counter"
      end

    end # Stub

    # Worker provides a work loop for processing rpc method calls iteratively
    class Worker

      include Loggable
      include Statsable

      # Config options
      # @return [Hash<Symbol,Object>] (see #initialize)
      attr_accessor :options

      attr_reader :shutdown, :waiting_calls

      def initialize(rpc, options = {})
        @redis = rpc.redis
        @my_id = rpc.my_id

        @shutdown = false
        @waiting_calls = {}

        CallJob.set_server_id(@my_id)
        ReplyJob.set_server_id(@my_id)
        @mq_worker = RedisMessageQueue::Worker.new(@redis,
          [RedisRpc::CallJob, RedisRpc::ReplyJob], options)
      end

      def add_waiting_call(call_id, stub)
        @waiting_calls[call_id] = stub
      end

      def remove_waiting_call(call_id)
        @waiting_calls[call_id] = nil
      end

      # Jobs are pulled from a queue and processed in intervals.
      def work_loop &blk
        info "RedisRpc: starting work loop..."

        @mq_worker.work_loop do |job, res|
          handle_job_result(job, res, &blk)
        end

        info "RedisRpc: work loop stopped."
      end

      # poll queue once
      # to get reply efficiently when a lot of calls are sent in short time
      def process_reply_queue &blk
        reply_queue = @mq_worker.get_queue_by_index(1)
        @mq_worker.process_queue(reply_queue) do |job, res|
          handle_job_result(job, res, &blk)
        end
      end

      def handle_job_result(job, _res)
        job_args = job['args']
        job_type, job_content = *job_args

        if job_type == 'rpc_call' then
          rpc_result = process_rpc_call(job_content)
          reply_rpc_call(job_content, rpc_result)
          yield job_args, rpc_result if block_given?
        elsif job_type == 'rpc_reply' then
          notify_waiting_call(job_content)
          yield job_args, nil if block_given?
        else
          yield job_args, nil if block_given?
          raise InvalidArgsError.new("invalid job type #{job_type}")
        end
      end

      def process_rpc_call(rpc_call)
        begin
          klass_name = rpc_call['class']
          with_time_redis_stats "rpc.#{klass_name}" do
            klass = klass_name.constantize
            klass.perform(*(rpc_call['args']))
          end
        rescue => er
          error "RedisRpc: call Error #{er.message}"
          error "RedisRpc: call Error backtrace #{er.backtrace}"
          error "RedisRpc: failed call is #{rpc_call}"
          "call_error: #{er.message}"
        end
      end

      def reply_rpc_call(rpc_call, result)
        ReplyJob.set_server_id rpc_call['reply-to']
        reply_queue = RedisMessageQueue::Queue.new(@redis, RedisRpc::ReplyJob)

        rpc_reply = {
          'id' => rpc_call['id'],
          'result' => result,
        }
        reply_queue.enqueue('rpc_reply', rpc_reply)
      end

      def notify_waiting_call(rpc_reply)
        call_id = rpc_reply['id']
        stub = @waiting_calls[call_id]
        @waiting_calls[call_id] = nil

        stub.notify_result(call_id, rpc_reply['result']) if stub
      end

      def shutdown?
        @mq_worker.shutdown?
      end

      def shutdown
        @mq_worker.shutdown
      end

      def clear(clear_process_queue)
        @mq_worker.clear(clear_process_queue)
      end

      def refill
        @mq_worker.refill
      end

      def queues
        @mq_worker.queues
      end

      def dequeue_count
        @mq_worker.dequeue_count
      end

      def dequeue_count= val
        @mq_worker.dequeue_count = val
      end

    end # Worker

    # Raised when server is over capacity
    class ServerBusyError < RuntimeError; end

    # Raised when met invalid args
    class InvalidArgsError < RuntimeError; end

    # Raised when remote calls timed out
    class CallTimeoutError < RuntimeError; end

    # Raised when error happens in remote calls
    class CallError < RuntimeError; end

  end

end