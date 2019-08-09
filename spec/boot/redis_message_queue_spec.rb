require_relative 'spec_helper'

class BuyBookJob
  def self.perform name
    return name
  end
end

class ReadBookJob
  def self.perform name, pages
    return name, pages
  end
end

class BorrowBookJob
  def self.perform name, from, days
    raise "borrow #{name} from #{from} failed!"
  end
end

describe RedisMessageQueue do

  before(:all) do
    @redis = Redis.new

    @book_name1 = 'TAOCP'
    @book_name2 = 'Unix Advanced Programming'
    @book_name3 = 'The Art of Unix Programming'

    @buy_book_queue = RedisMessageQueue::Queue.new(@redis, BuyBookJob)
    @buy_book_queue.clear true

    @read_book_queue = RedisMessageQueue::Queue.new(@redis, ReadBookJob)
    @read_book_queue.clear true

    @borrow_book_queue = RedisMessageQueue::Queue.new(@redis, BorrowBookJob)
    @borrow_book_queue.clear true

    @worker_buy = RedisMessageQueue::Worker.new(@redis, 'buy_book')
    @worker_read = RedisMessageQueue::Worker.new(@redis, 'read_book')
    @worker_borrow = RedisMessageQueue::Worker.new(@redis, 'borrow_book')
    @worker_all = RedisMessageQueue::Worker.new(@redis, [ 'buy_book', 'read_book', 'borrow_book' ],
      :poll_interval => 0.01)
  end

  after(:all) do
    @buy_book_queue.clear true
    @read_book_queue.clear true
    @borrow_book_queue.clear true
  end

  it 'should publish' do
    @buy_book_queue.enqueue @book_name1
    @buy_book_queue.enqueue @book_name2
    @read_book_queue.enqueue @book_name1, 10
    @borrow_book_queue.enqueue @book_name3, 'Firevale', 30
    @buy_book_queue.enqueue @book_name3
    @read_book_queue.enqueue @book_name2, 5

    @buy_book_queue.length.should eql 3
    @read_book_queue.length.should eql 2
    @borrow_book_queue.length.should eql 1

    @buy_book_queue.process_length.should eql 0
    @read_book_queue.process_length.should eql 0
    @borrow_book_queue.process_length.should eql 0
  end

  it 'should process with order' do
    @worker_buy.work_loop do |job, res|
      count = count = @worker_buy.dequeue_count
      puts "worker_buy: count=#{count}"
      case count
      when 1
        res.should eql @book_name1
      when 2
        res.should eql @book_name2

        @worker_buy.shutdown
      end
    end

    @buy_book_queue.length.should eql 1
    @read_book_queue.length.should eql 2
    @borrow_book_queue.length.should eql 1

    @buy_book_queue.process_length.should eql 0
    @read_book_queue.process_length.should eql 0
    @borrow_book_queue.process_length.should eql 0

    @worker_all.work_loop do |job, res|
      count = @worker_all.dequeue_count
      puts "worker_all: count=#{count}"
      case count
      when 1
        res.should eql @book_name3
      when 2
        res.should eql [ @book_name1, 10 ]
      when 3
        res.should eql [ @book_name2, 5 ]
      when 4
        @worker_all.shutdown
      end
    end

    @buy_book_queue.length.should eql 0
    @read_book_queue.length.should eql 0
    @borrow_book_queue.length.should eql 0

    @buy_book_queue.process_length.should eql 0
    @read_book_queue.process_length.should eql 0
    @borrow_book_queue.process_length.should eql 1
  end

  it 'should refill' do
    @borrow_book_queue.refill

    @buy_book_queue.length.should eql 0
    @read_book_queue.length.should eql 0
    @borrow_book_queue.length.should eql 1

    @buy_book_queue.process_length.should eql 0
    @read_book_queue.process_length.should eql 0
    @borrow_book_queue.process_length.should eql 0
  end

  it 'should fail again after refill' do
    @worker_borrow.work_loop do |job, res|
      count = @worker_borrow.dequeue_count
      puts "worker_borrow: count=#{count}"
      case count
      when 1
        res.should eql nil
        @worker_borrow.shutdown
      end
    end

    @buy_book_queue.length.should eql 0
    @read_book_queue.length.should eql 0
    @borrow_book_queue.length.should eql 0

    @buy_book_queue.process_length.should eql 0
    @read_book_queue.process_length.should eql 0
    @borrow_book_queue.process_length.should eql 1
  end

  it 'should enqueue_batch' do
    @buy_book_queue.length.should eql 0
    @buy_book_queue.enqueue_batch [ @book_name1 ], [ @book_name2 ], [ @book_name3 ]
    @buy_book_queue.length.should eql 3
  end

  it 'should ensure errors caught' do
  end

  it 'should raise for invalid inputs' do
    lambda { RedisMessageQueue::Queue.new(@redis, '') }.should raise_error
    lambda { RedisMessageQueue::Worker.new(@redis, []) }.should raise_error
  end

end