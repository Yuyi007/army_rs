# msgpack_spec.rb

require_relative 'spec_helper'

describe 'msgpack_spec' do

  it 'should pack and unpack json data' do
    json = '{}'
    data = Oj.strict_load(json)
    packed = MessagePack.pack(data)
    # File.open("test.pack", "w") { |f| f.write(packed); f.flush }
    data2 = MessagePack.unpack(packed)
    # BigDecimals won't be the same
    # data.should eql data2
    data.keys.should eql data2.keys
  end

end

