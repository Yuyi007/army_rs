
class('FloatingTextFactory', function (self)
end)

local m = FloatingTextFactory
m.debug = nil
m.id = 0

function m.makeNormal(options)
  local view, pool = ViewFactory.make('text_normal')
  if view then
    view:show(options)
  end
  return view, pool
end

function m.makeFramed(options)
  FramedFloatingText.deleteTipView()

  local view, pool = ViewFactory.make('text_framed')
  if view then
    view:show(options)
  end
  return view
end

function m.makeIcon(options)
  local view, pool = ViewFactory.make('text_icon')
  if view then
    view:show(options)
  end
  return view
end

function m.makeFramedTwo(options)
   local view, pool = ViewFactory.make('text_framed_two')
  if view then
    view:show(options)
  end
  return view
end
