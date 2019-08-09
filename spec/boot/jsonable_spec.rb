# jsonable_spec.rb

require_relative 'spec_helper'

class Skill
  include Jsonable
  attr_accessor :name

  def initialize name = 'default_name'
    @name = name
  end
end

class Skill2
  include Jsonable
  attr_accessor :name
  attr_accessor :type

  def initialize name = 'default_name'
    @name = name
    @type = 'unknown'
  end
end

class Equipment
  include Jsonable
  attr_accessor :name

  def initialize name = 'default_name'
    @name = name
  end
end

class Formation
  include Jsonable
  attr_accessor :name

  def initialize name = 'default_name'
    @name = name
  end
end

class TestJsonable

  attr_accessor :skills

  include Jsonable

  json_array :skills, :Skill

  # this keeps @@objects, @@hashes, @@arrays at current state
  # won't be affected by subclasses overwriting them
  gen_from_hash
  gen_to_hash

  def initialize
    @skills = []
  end
end

class TestJsonable2 < TestJsonable

  attr_accessor :skills
  attr_accessor :equips
  attr_accessor :formation

  include Jsonable

  json_hash :equips, :Equipment
  json_array :skills, :Skill
  json_object :formation, :Formation

  gen_from_hash
  gen_to_hash

  def initialize
    @equips = {}
    @skills = []
    @formation = Formation.new
  end
end

class TestJsonable3 < TestJsonable2

  json_array :skills, :Skill2

  gen_from_hash
  gen_to_hash

  def initialize
    @equips = {}
    @skills = []
    @formation = Formation.new
  end
end

describe 'jsonable_spec' do

  before do
    @m = TestJsonable.new
    @m2 = TestJsonable2.new
  end

  describe 'when dump' do
    it 'should dump correct for empty array ' do
      @m.skills = []
      s = @m.to_hash
      s.empty?.should be_falsey
    end

    it 'should dump correct for array with nils ' do
      @m.skills = [nil]
      s = @m.to_hash
      s['skills'].empty?.should be_falsey
    end

    it 'should restore correctly' do
      @m.skills = [ ]
      @m.skills << Skill.new('a')

      m = TestJsonable.new.load!(@m.dump)

      m.skills.length.should eql @m.skills.length
      m.skills[0].name.should eql @m.skills[0].name
    end

    it 'should restore correctly for inherited classes' do
      @m2.skills = [ ]
      @m2.skills << Skill.new('a')
      @m2.skills << Skill.new('b')
      @m2.equips = { 'e1' => Equipment.new('e1'), 'e2' => Equipment.new('e2')  }

      m2 = TestJsonable2.new.load!(@m2.dump)

      m2.skills.length.should eql @m2.skills.length
      m2.skills[0].class.should eql @m2.skills[0].class
      m2.skills[0].name.should eql @m2.skills[0].name
      m2.skills[1].name.should eql @m2.skills[1].name

      m2.equips.length.should eql @m2.equips.length
      m2.equips['e1'].name.should eql @m2.equips['e1'].name
      m2.equips['e2'].name.should eql @m2.equips['e2'].name

      m2.formation.name.should eql @m2.formation.name
    end

    it 'should restore correctly for inherited members' do
    end
  end

  describe 'When members are deserialized' do
    it 'Should have the __owner__ set ' do
      @m.skills = []
      @m.skills << Skill.new
      @m.skills.first.__owner__.should be nil
      s = @m.to_hash
      @m.from_hash!(s)
      @m.skills.first.__owner__.should be @m
    end
  end


end