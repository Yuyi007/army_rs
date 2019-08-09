-- View3D.lua

local Vector3 = UnityEngine.Vector3
local Animator = UnityEngine.Animator
local World = UnityEngine.Space.World
local unity = unity

local anim2Hash = {}
local hash2Anim = {}

-- 3d view
function View3D(classname, bundleFile, ctor, super)
  local cls = ViewBase(classname, bundleFile, ctor, super)

  -- By default, 3d view should not bind nodes
  cls.__bindNodes = nil

  function cls.bind(self, bundleFile, options)
    -- logd('binding %s - %s', classname, tostring(bundleFile))
    self:__bind(bundleFile, options)
  end

  function cls.on_post_bind(self)
    self.animator = self.transform:getComponent(Animator)
  end

  function cls.on_post_init(self)
    self:signal('viewInited'):fire()
  end

  function cls.onViewInitialized(self, onComplete)
    if self.__inited then
      onComplete()
    else
      self:signal('viewInited'):addOnce(onComplete)
    end
  end

  function cls._playTrigger(self, anim, onComplete)
    if not anim then return end

    if self.animator then

      -- remove previous onComplete delay call
      if self.__onPlayTriggerCompleteHandler then
        self:unschedule(self.__onPlayTriggerCompleteHandler)
        self.__onPlayTriggerCompleteHandler = nil
      end

      if not self:hasAnim(anim) then
        --logd('no anim state %s found for %s', tostring(anim), self.gameObject:getName())
        if onComplete then onComplete() end
        return
      end

      if self.curAnim then
        self.animator:ResetTrigger(self.curAnim)
      end

      -- logd('%s playTrigger %s, %s', peek(self.id), peek(anim), debug.traceback())

      self.animator:SetTrigger(anim)
      if self.curAnim ~= anim then self:notifyAnimChange(anim) end
      self.curAnim = anim
      if onComplete then
        local time = ClipUtil.getClipTime(self, anim)
        if time then
          self.__onPlayTriggerCompleteHandler = self:performWithDelay(time, onComplete)
        end
      end
    end
  end

  if not cls.playTrigger then
    function cls.playTrigger(self, anim, onComplete)
      cls._playTrigger(self, anim, onComplete)
    end
  end


  if not cls.resetTrigger then
    function cls.resetTrigger(self, anim)
      if not anim then return end

      if self.animator then
        if not self:hasAnim(anim) then
          logd('no anim state %s found for %s', tostring(anim), self.gameObject:getName())
          return
        end
        self.animator:ResetTrigger(anim)
      end
    end
  end

  if not cls.setAnimTrigger then
    function cls.setAnimTrigger(self, paramName, value)
      if self.animator then
        self.animator:SetBool(paramName, value)
      end
    end
  end

  function cls.notifyAnimChange(self, animStarted, animEnded)
    self:signal('anim_change'):fire(animStarted, animEnded or self.curAnim)
  end

  function cls.currentAnimNormalizedTime(self)
    if not self.animator then return 0 end
    local state = self.animator:GetCurrentAnimatorStateInfo(0)
    local normalalizedTime = state:get_normalizedTime()
    return normalalizedTime
  end

  -- time == 0 - start of the animation
  -- time == 1 - end of the animation
  if not cls.playAnim then
    function cls.playAnim(self, anim, time)
      if not anim then
        logd('[%s] playAnim but anim is nil', tostring(self.id))
        return
      end
      if not self.gameObject then
        logd('[%s] playAnim but gameObject is nil', tostring(self.id))
        return
      end

      if self.animator then
        if not self:hasAnim(anim) then
          logd('[%s] playAnim but no anim state %s found for %s',
            tostring(self.id), tostring(anim), self.gameObject:getName())
          return
        end

        -- force override trigger if animation changed
        if self.curAnim ~= anim then
          self:resetTrigger(anim)
          if self.curAnim then
            self:resetTrigger(self.curAnim)
          end
        end

        -- logd('%s playAnim %s, %s, %s', peek(self.id), peek(anim), peek(time), debug.traceback())

        if time == nil then
          self.animator:Play(anim)
          if self.curAnim ~= anim then self:notifyAnimChange(anim) end
        else
          self.animator:Play(anim, 0, time)
          if time == 0 or self.curAnim ~= anim then self:notifyAnimChange(anim) end
        end
        self.curAnim = anim
      else
        logd('[%s] playAnim %s but no animator', tostring(self.id), anim)
      end
    end
  end

  if not cls.playRawAnim then
    function cls.playRawAnim(self, anim, time)
      if not anim then return end
      if self.animator then

        if time == nil then
          self.animator:Play(anim)
        else
          self.animator:Play(anim, 0, time)
        end
        self.curAnim = anim
      end
    end
  end

  if not cls.hasAnim then
    function cls.hasAnim(self, anim)
      if not anim then return false end
      if self.animator then
        local id = self:getAnimToHash(anim)
        return self.animator:HasState(0, id)
      else
        return false
      end
    end
  end

  function cls.isPlayingAnim(self, anim)
    if self.animator then
      local curAnim = self:getCurAnim()
      return curAnim == anim
    else
      return false
    end
  end

  function cls.getAnimToHash(self, anim)
    local id = anim2Hash[anim]
    if not id then
      id = Animator.StringToHash(anim)
      anim2Hash[anim] = id
      hash2Anim[id] = anim
    end
    return id
  end

  function cls.getCurAnim(self)
    if self.animator then
      local state = self.animator:GetCurrentAnimatorStateInfo(0)
      return hash2Anim[state:get_shortNameHash()]
    else
      return nil
    end
  end

  -- Set entity position
  -- Note that pos should be a Vector3 object, not a plain lua table.
  if not cls.setPosition then
    function cls.setPosition(self, pos)
      self.transform:set_position(pos)
    end
  end

  if not cls.position then
    function cls.position(self)
      if self.transform then
        return self.transform:get_position()
      else
        return Vector3(0, 0, 0)
      end
    end
  end

  if not cls.positionXYZ then
    function cls.positionXYZ(self)
      if self.transform then
        return self.transform:positionXYZ()
      else
        return 0, 0, 0
      end
    end
  end

  -- setForward is the main method to control entity directions in scene.
  -- If you have a dirIndex or degree value, convert it to a forward use
  -- UIUtil.getForwardFromDirIndex(dirIndex) first.
  if not cls.setForward then
    function cls.setForward(self, forward)
      self.transform:set_forward(forward)
    end
  end

  if not cls.forward then
    function cls.forward(self)
      if self.transform then
        return self.transform:get_forward()
      else
        return Vector3(0, 0, 0)
      end
    end
  end

  -- Unlike forward, eulerAngles are usually used in UI code.
  -- It's not recommended to use euler angles to set entity direcitons,
  -- instead, always use a forward.
  if not cls.setEulerAngles then
    function cls.setEulerAngles(self, angles)
      self.transform:set_eulerAngles(angles)
    end
  end

  if not cls.setEulerAngleY then
    function cls.setEulerAngleY(self, angleY)
      self.transform:set_eulerAngles(Vector3(0, angleY, 0))
    end
  end

  if not cls.eulerAngles then
    function cls.eulerAngles(self)
      if self.transform then
        return self.transform:get_eulerAngles()
      else
        return Vector3(0, 0, 0)
      end
    end
  end

  if not cls.rotate then
    function cls.rotate(self, angles)
      self.transform:Rotate(Vector3.up, angles, World)
    end
  end

  if not cls.rotation then
    function cls.rotation(self)
      return self.transform:get_rotation()
    end
  end

  if not cls.setScale then
    function cls.setScale(self, scale)
      self.transform:set_localScale(scale)
    end
  end

  if not cls.localScale then
    function cls.localScale(self)
      return self.transform:get_localScale()
    end
  end

  function cls.OnMouseUpAsButton(self)
    if unity.isPointerOverUI() then return end
    self:onMouseDown()
  end

end
