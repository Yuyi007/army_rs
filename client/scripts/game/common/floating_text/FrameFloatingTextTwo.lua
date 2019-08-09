View('FrameFloatingTextTwo', "prefab/ui/common/tips-ui", function(self)

end)

local m = FrameFloatingTextTwo

local FROM_POS = Vector3.new(0, -20, 0)
local TO_OFFSET = Vector3.new(0, 15, 0)
local COLOR = Color.new(Color.yellow)

m.showId = 0 
m.instance = nil

function m:mayCreateChain(popupDuration, stayDuration, toOffset)
  popupDuration = popupDuration or 0.2
  stayDuration = stayDuration or 1
  toOffset = toOffset or TO_OFFSET

  if self.stayDuration == stayDuration and self.popupDuration == popupDuration and self.toOffset == toOffset then
    return
  end

  toOffset = Vector3.new(toOffset)
  local transform = self.tips.transform

  local chain = unity.createTweenChain()
  chain:append(GoTween(transform, popupDuration, GoTweenConfig()
    :localPosition(toOffset, true)
    :setEaseType(GoEaseType.SineOut)))
  chain:append(GoTween(self.transform, stayDuration, GoTweenConfig()))
  chain:set_autoRemoveOnComplete(false)

  self.chain = chain
  self.popupDuration = popupDuration
  self.stayDuration = stayDuration
  self.toOffset = toOffset
end	

function m:reopenInit()
	self.tag     = nil 
	self.initPos = Vector3.new(self.transform:get_position())
end

function m:reopenExit()
  
end


function m:show(options)
  -- logd(">>>>>options:%s",inspect(options))
  if m.instance ~= self then
    m.deleteTipView()
  end


  m.instance = self
  m.showId = m.showId + 1
  -- logd('show %s (%s) options=%s', tostring(self), game.frameCount, peek(options))
  self.onComplete = options.onComplete
  
  self:setDepth(102)
  local fromPos = options.fromPos or FROM_POS
   
  if options.color then
  	self.tips:setColor(options.color)
  end	
  
  self.tips_text:setString(options.text)

  self:setVisible(true)

  self:mayCreateChain(options.popupDuration, options.stayDuration, options.toOffset)

  local showId = m.showId
  self.chain:setOnCompleteHandler(function ()
    if m.instance.destroyed then
      return
    end
    if m.instance == self and m.showId == showId then
      m.deleteTipView()
    end
  end)
  -- self.chain:prepareAllTweenProperties()
  self.chain:restart(true)
end

function m:deleteView()
  -- logd('deleteView %s (%s) trace=%s', tostring(self), game.frameCount, debug.traceback())
  if self.onComplete then
    self.onComplete()
    self.onComplete = nil
  end
  self:destroy()
end

function m.deleteTipView()
  local instance = m.instance
  if instance and not instance.destroyed then
    instance:deleteView()
    instance = nil
  end
end