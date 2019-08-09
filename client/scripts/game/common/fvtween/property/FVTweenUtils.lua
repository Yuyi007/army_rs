class('FVTweenUtils', function(self)
end)

local m = FVTweenUtils

function m.getPropertyAccessor(target, propertyName)
  if propertyName == 'position' then
    return function()
        return target.actor:setTweenPosition(target:position())
      end,
      function(pos)
        target.actor:setTweenPosition(pos)
      end
  end
  return nil, nil
end