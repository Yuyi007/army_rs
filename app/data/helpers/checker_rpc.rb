module CheckerBatchPerform
  def self.perform(args)
    if args.is_a?(::Hash)
      result = {:success => true, :rets => []}
      rets = result[:rets]
      arr = args[:arr_args]
      arr.each do |msg|
        zone = msg['zone']
        ret = self.__perform(msg['msg'])
        rets[zone] ||= []
        rets[zone] << ret
      end
      return result
    else
      return self.__perform(args)
    end
  end

  def self.__perform(args)
    raise 'plz override __perform!!!'
  end
end


module CheckerRpc
  def self.init
    @instance = CheckerRpcAdapter.new
  end

  def self.instance
    self.init if @instance.nil?
    @instance
  end

  def self.send(zone, klass, args, flush_now = false)
    instance.send(zone, klass, args, flush_now)
  end

  def self.call(zone, klass, args, flush_now = false)
    instance.call(zone, klass, args, flush_now)
  end

  def self.flush
    instance.flush
  end

  class CheckerRpcAdapter
    attr_reader :msg_queue

    def initialize
      @msg_queue = []
    end

    def send(zone, klass, args, flush_now = false)
      @msg_queue << {:zone => zone, :klass => klass, :args => args, :mode => :send}
      ret = flush if flush_now
    end

    def call(zone, klass, args, flush_now = false)
      @msg_queue << {:zone => zone, :klass => klass, :args => args, :mode => :call}
      flush if flush_now
    end

    def flush
      tmp_msgs = {}
      result = {}

      @msg_queue.each do |msg|
        zone = msg[:zone]
        mode = msg[:mode]
        klass = msg[:klass]
        checker_id = CSRouter.get_zone_checker(zone)
        tmp_msgs[checker_id] ||= {}
        cmsgs = tmp_msgs[checker_id]
        cmsgs[klass] ||= {}
        kmsgs = cmsgs[klass]
        kmsgs[mode] ||= {}
        mmsgs = kmsgs[mode]
        mmsgs[:msgs] ||= []
        arr = mmsgs[:msgs]
        arr << {:zone => zone, :msg => msg}
      end

      tmp_msgs.each do |cid, cmsgs|
        cmsgs.each do |mode, kmsgs|
          kmsgs.each do |klass, mmsgs|
            msgs = mmsgs[:send]
            if msgs
              args_arr = msgs.map{|msg| msg[:args]}
              RedisRpc.cast(klass, cid, {:arr_args => args_arr}) 
            end
          end
        end
      end

      tmp_msgs.each do |cid, cmsgs|
        cmsgs.each do |mode, kmsgs|
          kmsgs.each do |klass, mmsgs|
            msgs = mmsgs[:call]
            if msgs
              args_arr = msgs.map{|msg| msg[:args]}
              ret = RedisRpc.call(klass, cid, {:arr_args => args_arr}) 
              result[klass.to_sym] = ret
            end
          end
        end
      end

      result
    end
  end
end