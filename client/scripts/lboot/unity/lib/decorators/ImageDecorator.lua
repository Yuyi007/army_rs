class('ImageDecorator')

local m = ImageDecorator
local Image = UnityEngine.UI.Image

function m.decorate(o)
  local mt = getmetatable(o)
  local t = m.funcs()
  for k, v in pairs(t) do
    rawset(mt, k, v)
  end
end

function m.funcs()
  local mt = {}

  function mt.setVisible(self, visible)
    self:get_gameObject():setVisible(visible)
  end

  function mt.setSprite(self, spriteName, sheetPath)
    if not spriteName then
      logd('ImageDecorator.setSprite no spriteName given %s', debug.traceback())
      return nil
    end
    sheetPath = sheetPath or cfg.sprites[spriteName]
    if not sheetPath then
      -- loge("------ trace:%s", tostring(debug.traceback()))
      logd('no sheetpath found for sprite %s %s', spriteName, debug.traceback())
      return nil
    end

    local sprite, mat = ss:getSprite(sheetPath, spriteName)
    if sprite then
      self:set_sprite(sprite)
      return mat
    else
      return nil
    end
  end

  function mt.setNativeSize(self)
    self:SetNativeSize()
  end

  function mt.setSpriteAsync(self, spriteName, sheetPath, onComplete)
    if not spriteName then
      logd('ImageDecorator.setSpriteAsync no spriteName given %s', debug.traceback())
      return
    end

    sheetPath = sheetPath or cfg.sprites[spriteName]
    if not sheetPath then
      -- loge("------ trace:%s", tostring(debug.traceback()))
      logd('no sheetpath found for sprite %s %s', spriteName, debug.traceback())
      return
    end

    ss:getSpriteAsync(sheetPath, spriteName, function(sprite, mat)
      if is_null(self) then return end
      self:set_sprite(sprite)
      if onComplete then
        onComplete(mat)
      end
    end)
  end

  function mt.setUseSceneDepth(self)
    self:set_material(ui:material("Shaders/UIImageWithSceneDepth"))
  end


  function mt.setGray(self)
    local sprite = self:get_sprite()

    if not sprite then
      self:set_material(ui:grayMat())
      return
    end

    local name = sprite:get_name()
    local sheetPath = cfg.sprites[name]
    if sheetPath then
      local mat = unity.loadSpriteMat(sheetPath)
      local grayMat = nil
      if mat then
        grayMat = ui:splitAlphaGrayMaterial(mat)
      else
        grayMat = ui:grayMat()
      end
      self:set_material(grayMat)
    else
      self:set_material(ui:grayMat())
    end
  end

  function mt.setNormal(self)
    local sprite = self:get_sprite()
    if sprite then
      local name = sprite:get_name()
      local sheetPath = cfg.sprites[name]
      if sheetPath then
        local mat = unity.loadSpriteMat(sheetPath)
        self:set_material(mat)
      else
        self:set_material(nil)
      end
    else
      self:set_material(nil)
    end
  end

  function mt.setProgress(self, percent, direction)
    self:set_fillAmount(percent)
    self:set_type(3) -- Image.Type.Filled
    direction = direction or 4
    -- logd("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< set progress check now:"..tostring(direction).. ","..tostr  ing(percent))
    if direction == 1 then
      -- right to left
      self:set_fillMethod(Image.FillMethod.Horizontal)
      self:set_fillOrigin(Image.OriginHorizontal.Right)
    elseif direction == 2 then
      -- up to down
      self:set_fillMethod(Image.FillMethod.Vertical)
      self:set_fillOrigin(Image.OriginVertical.Bottom)
    elseif direction == 3 then
      -- down to up
      self:set_fillMethod(Image.FillMethod.Vertical)
      self:set_fillOrigin(Image.OriginVertical.Top)
    elseif direction == 4 then
      -- left to right
      self:set_fillMethod(Image.FillMethod.Horizontal)
      self:set_fillOrigin(Image.OriginHorizontal.Left)
    elseif direction == 5 then
      -- radial360 from top
      self:set_fillMethod(Image.FillMethod.Radial360)
      self:set_fillOrigin(Image.Origin360.Top)
    elseif direction == 6 then
      -- radial180 from right
      self:set_fillMethod(Image.FillMethod.Radial180)
      self:set_fillOrigin(Image.Origin180.Right)
    else
      -- default  left to right
      self:set_fillMethod(Image.FillMethod.Horizontal)
      self:set_fillOrigin(Image.OriginHorizontal.Left)
    end
  end

  function mt.getProgress(self)
    return self:get_fillAmount()
  end

  function mt.runProgressAnim(self, options)
    local node            = options.node
    local animTime        = options.animTime or 0.5
    local fromPercent     = options.fromPercent or 0
    local toPercent       = options.toPercent or 1
    local onComplete      = options.onComplete
    local direction       = options.direction
    local delay           = options.delay or 0
    local elapsedTime     = 0
    local animRunTime     = 0
    local reseted         = false
    -- logd("----- animRunTime stop 111:"..tostring(fromPercent)..","..tostring(toPercent))
    -- self:stopProgressAnim(node)
    local t = {}
    t.h = scheduler.scheduleWithUpdate(function(deltaTime)
      elapsedTime = elapsedTime + deltaTime
      -- logd("----- animRunTime111:" .. tostring(fromPercent) .. " percent:" .. tostring(toPercent))
      if delay and delay > 0 and elapsedTime < delay then return end
      if not reseted then
        self:setProgress(fromPercent, direction)
        reseted = true
      end
      animRunTime = elapsedTime-delay
      animRunTime = math.max(0, animRunTime)
      animRunTime = math.min(animTime, animRunTime)
      local percent = fromPercent + (toPercent - fromPercent) * animRunTime/animTime
      -- logd("----- animRunTime:" .. tostring(animRunTime) .. " percent:" .. tostring(percent) .. " toPercent:" .. tostring(toPercent) .. " fromPercent:" .. tostring(fromPercent) .. " node.progressHandler:" .. tostring(node.progressHandler))
      self:setProgress(percent, direction)
      if animRunTime >= animTime then
        -- logd("----- animRunTime222 stop 222")
        scheduler.unschedule(t.h)
        if onComplete then onComplete() end
      end
    end)
    node.progressHandler = t.h
  end


  function mt.stopProgressAnim(self, node)
    -- logd("----- animRunTime real stop:"..tostring(node.progressHandler))
    if node.progressHandler then
      -- logd("----- animRunTime real stop run mmmm:"..tostring(node.progressHandler))
      scheduler.unschedule(node.progressHandler)
      node.progressHandler = nil
    end
  end

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })


