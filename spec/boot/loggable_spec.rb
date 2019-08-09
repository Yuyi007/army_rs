# encoding: utf-8
# loggable_spec.rb
#
# NOTE
# This test is not automatic,
# you must check the result by reading the screen output.
#

require_relative 'spec_helper'

class TestLoggable

  def add(arg1, arg2)
    puts "add(arg1, arg2) called"
  end

  include Loggable

end

t = TestLoggable.new

describe 'loggable_spec' do

  it 'should do basic logging' do
    t.debug { 'this is debug' }
    t.info 'this is info'
    t.warn 'this is warn'
    t.error 'this is error'
    t.fatal 'this is fatal'
    t.stat 'this is stat'
  end

  it 'should log invalid messages' do
    t.info "\xFF\xAD中we文\xBF"
    t.info "¡™£¢∞§¶•ªº–≠"
  end

  it 'should log new lines' do
    t.info "abc\ndef"
  end

  it 'should log printf symbols' do
    t.info "%s %d %ld"
  end

  it 'should do long message logging' do
    normal = 'abcdefghij' * 100
    long = normal * 2
    long1 = long * 3
    long2 = long1 * 2

    t.info normal
    t.info long
    t.info long1
    t.info long2
  end

  it 'should not overlap with includer methods' do
    t.add(1, 2)
  end

  it 'should set level' do
    Loggable.set_level Logger::DEBUG
    t.info 'level = debug, this should be displayed'
    Loggable.set_level Logger::INFO
    t.info 'level = info, this should be displayed'
    Loggable.set_level Logger::ERROR
    t.info 'level = error, this should not be displayed'
  end

  it 'should suppress logs' do
    Loggable.set_suppress_logs true
    t.debug { 'suppress_logs = true, this should not be displayed' }
    Loggable.set_suppress_logs false
    t.debug { 'suppress_logs = false, this should be displayed' }
    Loggable.set_suppress_logs nil
    t.debug { 'suppress_logs = nil, this should be displayed' }
  end

  it 'should flush' do
    t.flush

    t.debug { 'before flush' }
    t.flush
    t.debug { 'after flush' }
  end

end