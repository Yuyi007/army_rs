require_relative 'spec_helper'

describe String do
  it "#constantize" do
    Kernel.should eql "Kernel".constantize
    Boot::RedisQueue.should eql 'Boot::RedisQueue'.constantize
    lambda { 'Object::MissingConstant'.constantize }.should raise_error
  end
end