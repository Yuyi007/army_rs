-- This behaviour tree imp is adapted from:
-- https://github.com/tanema/behaviourtree.lua

-- base
require 'game/lib/bt/base/Node'
require 'game/lib/bt/base/BranchNode'

-- decorators
require 'game/lib/bt/decorators/Decorator'
require 'game/lib/bt/decorators/Inverter'
require 'game/lib/bt/decorators/Failer'
require 'game/lib/bt/decorators/Succeeder'
require 'game/lib/bt/decorators/Repeater'
require 'game/lib/bt/decorators/Monitor'

-- composites
require 'game/lib/bt/composites/Sequence'
require 'game/lib/bt/composites/Priority'
require 'game/lib/bt/composites/RandomSelector'
require 'game/lib/bt/composites/Parallel'

-- BT
require 'game/lib/bt/BehaviourTree'

declare('BT', BehaviourTree)
BT.Task = Node

BT.Priority = Priority
BT.Sequence = Sequence
BT.Random = RandomSelector
BT.Parallel = Parallel

BT.Decorator = Decorator
BT.Inverter = Inverter
BT.Failer = Failer
BT.Succeeder = Succeeder
BT.Monitor = Monitor

BT.priority = function(config)
  return BT.Priority.new(config)
end

BT.parallel = function(config)
  return BT.Parallel.new(config)
end

BT.sequence = function(config)
  return BT.Sequence.new(config)
end

BT.random = function(config)
  return BT.Random.new(config)
end

BT.task = function(config)
  return BT.Task.new(config)
end

BT.monitor = function(config)
  return BT.Monitor.new(config)
end

BT.succeeder = function(config)
  return BT.Succeeder.new(config)
end


