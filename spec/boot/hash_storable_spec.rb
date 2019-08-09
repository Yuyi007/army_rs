# hash_storable_spec.rb

require_relative 'spec_helper'

class ComputerHashStorable1 < Computer
  include HashStorable
  hash_field :applications
  gen_from_hash
  gen_to_hash
end

class ComputerHashStorable2 < Computer
  include HashStorable
  hash_field :applications
  hash_field :databases
  gen_from_hash
  gen_to_hash
end

class ComputerHashStorable3 < Computer
  include HashStorable
  hash_field :applications
  hash_field :databases
  hash_field :cpu
  gen_from_hash
  gen_to_hash
end

class ComputerHashStorable2_fix < Computer
  include HashStorable
  hash_field :applications
  hash_field :databases
  hash_load :cpu
  gen_from_hash
  gen_to_hash
end

class ComputerHashStorable1_fix < Computer
  include HashStorable
  hash_field :applications
  hash_load :databases
  hash_load :cpu
  gen_from_hash
  gen_to_hash
end

def test_dump_restore_to_hash_storable m, clz
  res = m.dump

  preload_fields = [ res, 0 ]

  m2 = clz.new.init_hash_storable! preload_fields do |field_name, cur_value|
    cur_value
  end

  # puts "======= dump two models ========"
  # puts "#{m}"
  # puts "#{m2}"

  m.dump.should eql m2.dump(:ignored => { 'version' => true })

  m2
end

def test_dump_restore_from_hash_storable m, clz
  res = m.breakdown_dump
  res_hash = Hash[res.each_slice(2).to_a]

  m2 = clz.new
  m2.load! res_hash['model']
  res_hash.each do |name, field|
    m2.send("#{name}=", Jsonable.load_hash(field)) if not HashStorableMeta.preload_fields.include? name
  end

  # puts "======= dump two models ========"
  # puts "#{m}"
  # puts "#{m2}"

  m.dump(:ignored => { 'version' => true }).should eql m2.dump

  m2
end

def test_dump_restore m, clz
  res = m.breakdown_dump
  res_hash = Hash[res.each_slice(2).to_a]

  preload_fields = []
  HashStorableMeta.preload_fields.each do |field_name|
    preload_fields << res_hash[field_name]
  end

  m2 = clz.new.init_hash_storable! preload_fields do |field_name, _|
    res_hash[field_name]
  end

  # puts "======= dump two models ========"
  # puts "#{m}"
  # puts "#{m2}"

  m.dump.should eql m2.dump

  m2
end

describe 'hash_storable_spec' do

  before do
    @computer = Computer.new.init 'Mac Pro'
    @computer.cpu = Cpu.new.init 'Intel Xeon 5'
    @computer.applications = {
      'a1' => Application.new.init('Xcode 6'),
      'a2' => Application.new.init('Xcode 5'),
      'a3' => Application.new.init('Garage Band')
    }
    @computer.databases = [
      Database.new.init('redis'),
      Database.new.init('mysql')
    ]

    @m = ComputerHashStorable1.new
    @m.init_hash_storable! @computer.dump
  end

  describe 'when changing class' do

    it 'dump and restore should maintain data integrity' do
      computer1 = test_dump_restore_to_hash_storable @computer, ComputerHashStorable1
      computer = test_dump_restore_from_hash_storable computer1, Computer
    end

  end

  describe 'when changing storable scheme' do

    it 'dump and restore should maintain data integrity' do
      computer1 = test_dump_restore @m, ComputerHashStorable1        # 1 -> 1
      computer1 = test_dump_restore computer1, ComputerHashStorable1 # 1 -> 1
      computer2 = test_dump_restore computer1, ComputerHashStorable2 # 1 -> 2
      computer3 = test_dump_restore computer2, ComputerHashStorable3 # 2 -> 3
      computer3 = test_dump_restore computer1, ComputerHashStorable3 # 1 -> 3

      computer2_fix = test_dump_restore computer3, ComputerHashStorable2_fix     # 3 -> 2
      computer1_fix = test_dump_restore computer2_fix, ComputerHashStorable1_fix # 2 -> 1
      computer1_fix = test_dump_restore computer3, ComputerHashStorable1_fix     # 3 -> 1
      computer1_fix = test_dump_restore computer1_fix, ComputerHashStorable1_fix # 1 -> 1

      computer2 = test_dump_restore computer1_fix, ComputerHashStorable2 # 1 -> 2
      computer3 = test_dump_restore computer1, ComputerHashStorable3     # 1 -> 3
      computer3 = test_dump_restore computer2, ComputerHashStorable3     # 2 -> 3
    end

  end

end