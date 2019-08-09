# redis_message_queue.rb
# Redis message queue implementation
# Aims to be basically compatible with resque and sidekiq, but leverages evented fibers

module Boot

  module RedisMessageQueue

    PREFIX = '_mq_' unless defined? PREFIX
    SUFFIXES = %w(Job Worker).freeze unless defined? SUFFIXES

    class Queue

      include Loggable

      attr_accessor :klass, :queue_name, :process_queue_name, :queue, :options

      def initialize redis, klass, options = {}
        self.klass = klass
        self.queue_name = RedisMessageQueue::Queue.queue_from_class(klass)
        self.process_queue_name = "#{self.queue_name}_process"
        validate(klass, self.queue_name)

        self.options = options
        self.options[:redis] = redis
        self.queue = RedisQueue.new(self.queue_name, self.process_queue_name, self.options)
      end

      def enqueue(*args)
        data = encode_job args
        self.queue.push data
      end

      def encode_job(args)
        job = { 'class' => self.klass.to_s, 'args' => args }
        data = MessagePack.pack job
      end

      def enqueue_batch(*arrays)
        datum = arrays.map do |arr|
          encode_job arr
        end
        self.queue.push_batch *datum
      end

      def clear(clear_process_queue = false)
        self.queue.clear clear_process_queue
      end

      def clear_process_queue
        self.queue.clear_process_queue
      end

      def length
        self.queue.length
      end

      def process_length
        self.queue.process_length
      end

      def refill
        self.queue.refill
      end

      # Given a class, try to extrapolate an appropriate queue based on a class
      # instance variable, `queue` method, or (finally) the class name
      # @param klass [Class]
      # @return [#to_s]
      def self.queue_from_class(klass)
        queue   = klass.instance_variable_get(:@queue)
        queue ||= klass.queue if klass.respond_to?(:queue)

        if !(queue) && klass.to_s =~ (suffix = /(#{SUFFIXES.join('|')})$/)
          suffix_removed = klass.to_s.gsub(suffix,'')

          queue = suffix_removed.
            gsub(/(.)(?<![A-Z])([A-Z])/,'\1_\2').   # insert underscore before capital letters
            gsub(/::/,'_').                         # replace namespace separators with underscores
            gsub(/_+/,'_').                         # replace multiple underscores with a single
            gsub(/_$/,'').                          # replace terminating underscores
            downcase
        end

        Boot::RedisHelper_.redis_key_by_tag("#{PREFIX}#{queue}")
      end

      # Validates if the given klass could be a valid Resque job
      #
      # If no queue can be inferred this method will raise a `Resque::NoQueueError`
      #
      # If given klass is nil this method will raise a `Resque::NoClassError`
      # @param klass [Class]
      # @param queue [#to_s] (see #queue_from_class(klass))
      # @raise [NoQueueError] if queue cannot be detected
      # @raise [NoClassError] if klass not valid
      def validate(klass, queue = nil)
        queue ||= RedisMessageQueue::Queue.queue_from_class(klass)

        unless queue and queue.length > PREFIX.length
          raise NoQueueError.new("Jobs must be placed onto a queue. No queue could be inferred for class #{klass}")
        end

        if klass.to_s.empty?
          raise NoClassError.new("Jobs must be given a class.")
        end
      end

    end # Queue

    class Worker

      include Loggable

      # Config options
      # @return [Hash<Symbol,Object>] (see #initialize)
      attr_accessor :options, :dequeue_count

      attr_reader :queues

      attr_reader :shutdown

      # Workers should be initialized with an array of string queue
      # names. The order is important: a Worker will check the first
      # queue given for a job. If none is found, it will check the
      # second queue name given. If a job is found, it will be
      # processed. Upon completion, the Worker will again check the
      # first queue given, and so forth. In this way the queue list
      # passed to a Worker on startup defines the priorities of queues.
      #
      # @param queues (see WorkerQueueList#initialize)
      # @param options [Hash<Symbol,Object>]
      # @option options [Boolean] :graceful_term
      # @option options [#warn,#unknown,#error,#info,#debug] :logger duck-typed ::Logger
      # @option options [#await] :awaiter (IOAwaiter.new)
      # @option options [Resque::Backend] :client
      def initialize(redis, queues = [], options = {})
        options[:poll_interval] ||= 0.2
        @interval = Float(options[:poll_interval])

        @options = options
        @options[:redis] = redis
        @shutdown = false
        @mutex = {}
        @dequeue_count = 0

        queues = [ queues ] unless queues.is_a? Array
        @queues = queues.map do |klass_or_queue_name|
          if klass_or_queue_name.is_a? String
            queue_name = Boot::RedisHelper_.redis_key_by_tag("#{PREFIX}#{klass_or_queue_name}")
            process_queue_name = "#{queue_name}_process"
          elsif klass_or_queue_name.is_a? Class
            queue_name = RedisMessageQueue::Queue.queue_from_class(klass_or_queue_name)
            process_queue_name = "#{queue_name}_process"
          else
            raise NoQueueError.new("Cannot infer queue name from arguments")
          end

          unless queue_name and queue_name.length > PREFIX.length
            raise NoQueueError.new("Invalid queue name: #{queue_name}")
          end

          @mutex[queue_name] = Mutex.new
          RedisQueue.new(queue_name, process_queue_name, @options)
        end

        if @queues.empty?
          raise NoQueueError.new("Please give each worker at least one queue.")
        end
      end

      # Jobs are pulled from a queue and processed.
      def work_loop &blk
        @shutdown = false
        i = 0

        queue_names = @queues.map { |q| q.name }
        info "RedisMessageQueue: starting work loop..."
        info "RedisMessageQueue: queues=#{queue_names}"

        loop do
          break if shutdown?
          i = 0 if i >= @queues.length
          queue = @queues[i]
          i += 1
          begin
            process_queue(queue) do |job, res|
              i = 0
              yield job, res if block_given?
            end
          rescue => er
            error("Worker Error: ", er)
          end
          Boot::Helper.sleep @interval if i > 0
        end

        info "RedisMessageQueue: work loop stopped."
      end

      def process_queue(queue)
        mutex = @mutex[queue.name]
        Boot::Helper.lock_mutex(mutex)
        begin
          queue.process_one(true) do |data|
            if data
              @dequeue_count += 1
              job = MessagePack.unpack data
              res = nil
              begin
                res = process_job(job)
              ensure
                yield job, res if block_given?
              end
              true
            end
          end
        ensure
          Boot::Helper.unlock_mutex(mutex)
        end
      end

      def process_job(job)
        klass = job['class'].constantize
        klass.perform *(job['args'])
      end

      def shutdown?
        @shutdown
      end

      def shutdown
        @shutdown = true
      end

      def clear(clear_process_queue)
        @queues.each { |q| q.clear(clear_process_queue) }
      end

      def refill
        @queues.each { |q| q.refill }
      end

      def get_queue_by_index(idx)
        @queues[idx]
      end

    end # Worker

    # Raised whenever we need a queue but none is provided.
    class NoQueueError < RuntimeError; end

    # Raised when trying to create a job without a class
    class NoClassError < RuntimeError; end

    # Raised when a worker was killed while processing a job.
    class DirtyExit < RuntimeError; end

    # Raised when child process is TERM'd so job can rescue this to do shutdown work.
    class TermException < SignalException; end

    # Raised from a before_perform hook to abort the job.
    class DontPerform < StandardError; end

  end # RedisMessageQueue

end # Boot