# lz4_ext_spec.rb

require_relative 'spec_helper'

describe LZ4::Fixed do

  it 'should compress and decompress' do
    input = 'original string'
    LZ4::Fixed.decompress(LZ4::Fixed.compress(input)).should eql input
  end

end