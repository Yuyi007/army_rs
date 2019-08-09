# hash_ext_spec.rb

require_relative 'spec_helper'

describe 'hash_ext_spec' do

  it 'deep_reject' do
    a = { 'a' => 1, 'b' => 2, 'c' => [ 1 ], 'd' => { 'e' => 1, 'f' => 2 } }
    b = { 'b' => 2, 'c' => [ 1 ], 'd' => { 'f' => 2 } }
    a.deep_reject(3).should eql a
    a.deep_reject(1).should eql b
  end

  it 'deep_merge' do
    a = { 'a' => 1, 'b' => 2, 'c' => [ 1 ], 'd' => { 'e' => 1 } }
    b = { 'b' => 3, 'c' => [ 1 ], 'd' => { 'e' => 3, 'f' => 2 } }
    c = { 'a' => 1, 'b' => 3, 'c' => [ 1, 1 ], 'd' => { 'e' => 3, 'f' => 2 } }
    a.deep_merge(b).should eql c
  end

  it 'deep_substract' do
    a = { 'a' => 1, 'b' => 2, 'c' => [ 1 ], 'd' => { 'e' => 1 }, 'g' => { 'h' => 3 } }
    b = { 'b' => 3, 'c' => [ 2 ], 'd' => { 'e' => 3, 'f' => 2 }, 'g' => {} }
    c = a.deep_merge(b)
    c.deep_substract(b).deep_merge(b).should eql c
  end

  it 'deep_merge_hash' do
    a = { 'a' => 1, 'b' => 2, 'c' => [ 1 ], 'd' => { 'e' => 1 } }
    b = { 'b' => 3, 'c' => [ 1 ], 'd' => { 'e' => 3, 'f' => 2 } }
    c = { 'a' => 1, 'b' => 3, 'c' => [ 1 ], 'd' => { 'e' => 3, 'f' => 2 } }
    a.deep_merge_hash(b).should eql c
  end

end

