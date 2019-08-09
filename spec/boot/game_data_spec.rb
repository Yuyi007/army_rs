# game_data_spec.rb

require_relative 'spec_helper'

describe 'when using game data' do

  AppConfig.preload(ENV['USER'], nil)
  Statsable.init(AppConfig.statsd)

  before do
    @id = 1
    @zone = 1
    GameData.redis = Redis.new
  end

  after do
    GameData.redis = nil
  end

  it 'should delete, create, read and update' do
    GameData.delete(@id, @zone)
    model0 = GameData.create(@id, @zone, ComputerHashStorable.new)
    model1 = GameData.read(@id, @zone)
    model0.should be
    model1.should be
    model0.name.should eql model1.name

    GameData.lock(@id, @zone) do
      model = GameData.read(@id, @zone)
      model.name = "strange computer"
      GameData.update(@id, @zone, model)
    end

    model2 = GameData.read(@id, @zone)
    model2.name.should eql "strange computer"

    GameData.delete(@id, @zone).should be_truthy
  end

  it 'should raise error when create, read invalid id or zone' do
    [[nil, 1], ['$noauth$', 1], [-2, 0]].each do |id_zone|
      id, zone = *id_zone
      lambda { GameData.read(id, zone)
        }.should raise_error /invalid id zone/
      lambda { GameData.create(id, zone, ComputerHashStorable.new)
        }.should raise_error /invalid id zone/
    end
  end

  it 'should raise error if lock timeout' do
    GameData.create(@id, @zone, ComputerHashStorable.new).should be

    GameData.lock(@id, @zone, :lock_timeout => 0.1) do
      model = GameData.read(@id, @zone)
      model.name = "strange computer"
      Kernel.sleep 0.1 * 1.01
      lambda { GameData.update(@id, @zone, model) }.should raise_error /update after/
    end
  end

  it 'should raise error if version is not monotonically increasing' do
    GameData.lock(@id, @zone, :lock_timeout => 0.1) do
      model = GameData.read(@id, @zone)
      model.version = model.version - 1

      lambda { GameData.update(@id, @zone, model) }.should raise_error /UPDATE_BLOB failed/
    end
  end

end