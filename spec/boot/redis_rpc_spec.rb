require_relative 'spec_helper'

class BuyBookJob
  def self.perform name
    return name
  end
end

class ReadBookJob
  def self.perform name, pages
    return [name, pages]
  end
end

class ReadBookSleepJob
  def self.perform name, pages
    Kernel.sleep 0.2
  end
end

class BorrowBookJob
  def self.perform name, from, days
    raise "borrow #{name} from #{from} failed!"
  end
end

describe RedisRpc do

  before(:all) do
    @redis = Redis.new
    @my_id = 'test-rpc1'
    @my_id2 = 'test-rpc2'
    @my_id3 = 'test-rpc3'

    @book_name1 = 'TAOCP'
    @book_name2 = 'Unix Advanced Programming'
    @book_name3 = 'The Art of Unix Programming'

    RedisRpc.init(@redis, :my_id => @my_id, :poll_interval => 0.01,
      :call_timeout => 0.1, :max_queue_length => 5)
    RedisRpc.worker.clear(true)

    @rpc_instances = [@my_id2, @my_id3].map do |my_id|
      RedisRpc::RpcEndpoint.new(@redis, :my_id => my_id, :poll_interval => 0.01,
        :call_timeout => 0.5, :max_queue_length => 5)
    end
    @rpc_instances.each { |rpc| rpc.worker.clear(true) }
  end

  after(:all) do
    puts "cleaning up RedisRpc..."
    RedisRpc.worker.clear(true)
    RedisRpc.destroy(@redis)
    @rpc_instances.each { |inst| inst.cleanup(@redis) }
  end

  before :example do |x|
    puts "-------------- In Spec #{x.metadata[:description]} --------------"
  end

  it 'should call with order' do
    call_thread = Thread.new do
      begin
        RedisRpc.call(BuyBookJob, @my_id, @book_name1).should eql @book_name1
        RedisRpc.call(ReadBookJob, @my_id, @book_name2, 10).should eql [@book_name2, 10]
        lambda { RedisRpc.call(BorrowBookJob, @my_id, @book_name3, 'Firevale', 30)
          }.should raise_error /^call.+error/
        RedisRpc.worker.shutdown
      rescue => er
        puts "call with order Error: #{er} #{er.backtrace}"
      end
    end

    RedisRpc.worker.dequeue_count = 0
    RedisRpc.worker.work_loop do |job, res|
      count = RedisRpc.worker.dequeue_count
      puts "rpc.worker: count=#{count} job=#{job}"
      case count
      when 1
        res.should eql @book_name1
      when 3
        res.should eql [@book_name2, 10]
      when 5
        res.should match /^call_error/
      when 6
        RedisRpc.worker.shutdown
      else
        res.should eql nil
      end
    end

    call_thread.join
  end

  it 'two instances should call each other' do
    @rpc_instances.each { |rpc| rpc.worker.shutdown }

    call_threads = @rpc_instances.map do |rpc|
      Thread.new do
        begin
          server_id = ((rpc.my_id == @my_id2) and @my_id3 or @my_id2)
          rpc.call(BuyBookJob, server_id, @book_name1).should eql @book_name1
        rescue => er
          puts "Error[#{rpc.my_id}]: #{er}"
        end
      end
    end

    worker_threads = @rpc_instances.map do |rpc|
      Thread.new do
        rpc.worker.work_loop do |job, res|
          count = rpc.worker.dequeue_count
          puts "rpc.worker[#{rpc.my_id}]: count=#{count} job=#{job}"
          case count
          when 1
            res.should eql @book_name1
          when 2
            rpc.worker.shutdown
          end
        end
      end
    end

    call_threads.each { |t| t.join }
    @rpc_instances.each { |rpc| rpc.worker.shutdown }
    worker_threads.each { |t| t.join }
  end

  it 'should refill' do
    queue = RedisRpc.worker.queues.first

    # simulate process error, leave some data in process queue
    queue.push(MessagePack.pack({}))
    queue.process_one(true) { |data| false }

    # refill
    RedisRpc.worker.refill
    queue.process_length.should eql 0
    queue.length.should eql 1
  end

  it 'should fail again after refill' do
    RedisRpc.worker.dequeue_count = 0
    RedisRpc.worker.work_loop do |job, res|
      count = RedisRpc.worker.dequeue_count
      puts "rpc.worker after refill: count=#{count}"
      case count
      when 1
        res.should eql nil
        RedisRpc.worker.shutdown
      end
    end
  end

  it 'should raise timeout error' do
    lambda{ RedisRpc.call(ReadBookSleepJob, @my_id, @book_name1)
      }.should raise_error /call.+timeout/
  end

  it 'should raise server busy error' do
    (0..3).each do |_|
      RedisRpc.cast(ReadBookJob, @my_id, @book_name1)
    end

    lambda{ RedisRpc.call(ReadBookJob, @my_id, @book_name1)
      }.should raise_error /call queue is full/
  end

  it 'should raise for invalid inputs' do
    lambda { RedisRpc.init(@redis, :my_id => nil) }.should raise_error
    lambda { RedisRpc.init(@redis, :my_id => '') }.should raise_error
    lambda { RedisRpc.init(@redis, :my_id => []) }.should raise_error
  end

end