
class('TransitionResult', function (self, toState)
  self.toState = toState
end, StructureData)

local m = TransitionResult

m.allFields = {
  'toState',
  'data'
}
