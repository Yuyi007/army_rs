# redis_index_spec.rb

require_relative 'spec_helper'

describe 'redis_index_spec' do

  before do
    @redis_index = RedisIndex.new(Redis.new, 'test_redis_index')
    @redis_index2 = RedisIndex.new(Redis.new, 'test_redis_index2')
  end

  it 'should update_prefix' do
    @redis_index.length(:name).should be 0

    @redis_index.update_prefix(:name, 'k1', 'ab')
      .update_prefix(:name, 'k1', 'abc')
      .update_prefix(:name, 'k2', 'abcd')
    lambda { @redis_index.update_prefix(:name, 1, 'a:') }.should raise_error(/invalid prefix/)

    @redis_index.check_index_validness(:name).should be true
    @redis_index.length(:name).should be 2
    @redis_index.length(:level).should be 0
    @redis_index2.length(:name).should be 0
  end

  it 'should search by prefix' do
    @redis_index.search_by_prefix(:name, 'ab').length.should be 2
    @redis_index.search_by_prefix(:name, 'ab', 1).length.should be 1
    @redis_index.search_by_prefix(:name, 'abcd').length.should be 1

    @redis_index.search_by_prefix(:name, 'cd').length.should be 0
    @redis_index.search_by_prefix(:name, '').length.should be 0
    lambda { @redis_index.search_by_prefix(:name, 'a:') }.should raise_error(/invalid prefix/)
  end

  it 'should read by prefix' do
    @redis_index.read_by_prefix(:name, 'abc').should eql 'k1'
    @redis_index.read_by_prefix(:name, 'abcd').should eql 'k2'

    @redis_index.read_by_prefix(:name, '').should be nil
    @redis_index.read_by_prefix(:name, 'a').should be nil
    @redis_index.read_by_prefix(:name, 'ab').should be nil
    lambda { @redis_index.read_by_prefix(:name, 'a:') }.should raise_error(/invalid prefix/)
  end

  it 'should update_score' do
    @redis_index.length(:level).should be 0

    @redis_index.update_score(:level, 'abc', 1).update_score(:level, 'abcd', 2)

    @redis_index.check_index_validness(:level).should be true
    @redis_index.length(:level).should be 2
    @redis_index.length(:name).should be 2
  end

  it 'should search by score' do
    @redis_index.search_by_score(:level, 1, 1).length.should be 1
    @redis_index.search_by_score(:level, 2, 2).length.should be 1
    @redis_index.search_by_score(:level, 1, 2).length.should be 2
    @redis_index.search_by_score(:level, 0, 3).length.should be 2
    @redis_index.search_by_score(:level, 0, 3, 1).length.should be 1
    @redis_index.search_by_score(:level, 3, 3).length.should be 0
  end

  it 'should delete' do
    @redis_index.delete(:name).delete(:level)

    @redis_index.length(:name).should be 0
    @redis_index.length(:level).should be 0
  end

end
