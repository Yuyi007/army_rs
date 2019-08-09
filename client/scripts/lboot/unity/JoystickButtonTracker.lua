class('JoystickButtonTracker', function(self, old)
  self:checkJoystickConnected()
  self:init(old)
end)

local m = JoystickButtonTracker
local unity = unity
local InputSource = InputSource

local allButtons = {
  'BtnX',
  'BtnY',
  'BtnA',
  'BtnB',
  'BtnL1',
  'BtnL2',
  'BtnR1',
  'BtnR2',
  'BtnPause',
  'BtnSelect',
}

function m.onClassReloaded(_clz)
  jbt.checkfuncs = nil
  jbt:getCheckFuncs()
end

function m:checkJoystickConnected()
  self.enableJoystick = false
  local gjns = UnityEngine.Input.GetJoystickNames()
  each(function(jn)
    -- logd('JoystickButtonTracker checkJoystickConnected 1 %s', peek(jn))
    self.enableJoystick = true
  end, gjns)
  -- logd('JoystickButtonTracker checkJoystickConnected 2')
end

function m:init(old)
  if old then old:exit() end
  self.frameResult = {}
  self.hasInput = false
  self:getCheckFuncs()
  self:initCheckUpdate()
  self:initSchedulerUpdate()

  self.allButtons = clone(allButtons)

  -- for i = 0, 19 do
  --   table.insert(self.allButtons, 'TestBtn'..i)
  -- end

  -- self.allAxis = {}
  -- for i = 0, 27 do
  --   table.insert(self.allAxis, 'TestAxis'..i)
  -- end
end

function m:exit()
  self:exitSchedulerUpdate()
  self:exitCheckUpdate()
end

function m:initCheckUpdate()
  self:exitCheckUpdate()
  self.checkHandler = scheduler.schedule(function()
    unity.beginSample('JoystickButtonTracker.checkHandler')
    local preEnable = self.enableJoystick
    self:checkJoystickConnected()
    if preEnable ~= self.enableJoystick then
      if self.enableJoystick then
        self:initSchedulerUpdate()
      else
        self:exitSchedulerUpdate()
      end
    end
    unity.endSample()
  end, 10)
end

function m:initSchedulerUpdate()
  if not self.enableJoystick then return end

  -- logd('JoystickButtonTracker checkJoystickButtons 0')
  self:exitSchedulerUpdate()
  self.updateHandler = scheduler.schedule(function()
    unity.beginSample('JoystickButtonTracker.updateHandler')
    -- logd('JoystickButtonTracker checkJoystickButtons 1')
    self:checkJoystickButtons()
    unity.endSample()
  end, 0)
end

function m:exitSchedulerUpdate()
  if self.updateHandler then
    scheduler.unschedule(self.updateHandler)
    self.updateHandler = nil
  end
end

function m:exitCheckUpdate()
  if self.checkHandler then
    scheduler.unschedule(self.checkHandler)
    self.checkHandler = nil
  end
end

function m:getCheckFuncs()
  self.checkfuncs = self.checkfuncs or {
    function()
      if not self.hasInput then return true end
      -- if showing loading view, do nothing
      return not not ui.loading
    end,

    function()
      -- if showing cutscene, press BtnA to skip
      local cs = CutsceneManager.getFullscreenCutscene()
      if self.frameResult['BtnA'] and cs and cs.skipView then
        cs.skipView:onBtn()
        return true
      end
      return false
    end,

    function()
      logd('JoystickButtonTracker func3')
      -- process top view in stack
      local vsindex, view = ui:topStackTopView()
      -- logd('JoystickButtonTracker func3 a %s', peek(view))
      return self:processViewBtnFunctions(view)
    end,

    function()
      -- process combat ui
      if cc.combatUI then
        return self:processViewBtnFunctions(cc.combatUI)
      end
      return false
    end,

    function()
      -- process main ui
      if cc.mainUI then
        return self:processViewBtnFunctions(cc.mainUI)
      end
      return false
    end,

  }
  return self.checkfuncs
end

function m:checkJoystickButtons()
  if mp:isBusyShown() then
    return
  end

  table.clear(self.frameResult)
  self.hasInput = false

  for i = 1, #self.allButtons do local keyName = self.allButtons[i]
    local val = InputSource.getButtonDown(keyName)
    if val then
      self.frameResult[keyName] = true
      self.hasInput = true
    end
  end

  -- for i = 1, #self.allAxis do local axisName = self.allAxis[i]
  --   local val = Input.GetAxis(axisName)
  --   if val ~= 0 then
  --     self.frameResult[axisName] = true
  --     self.hasInput = true
  --   end
  -- end

  if not self.hasInput then return end

  -- logd('JoystickButtonTracker checkJoystickButtons %s', peek(self.frameResult))

  for i = 1, #self.checkfuncs do local func = self.checkfuncs[i]
    if func() then
      break
    end
  end
end

function m:processViewBtnFunctions(view)
  if view and view.__joystick_functions and jbt.enableJoystick then
    -- logd('JoystickButtonTracker func3 1' )
    for k, v in pairs(view.__joystick_functions) do
      -- logd('JoystickButtonTracker view.classname %s, func %s', peek(view.classname), peek(v))
      if self.frameResult[k] then
        if type(v) == 'string' and type(view[v]) == 'function' then
          view[v](view)
          return true
        elseif type(v) == 'table' then

          if v.funcs then
            for i = 1, #v.funcs do local f = v.funcs[i]
              if type(f) == 'string' and type(view[f]) == 'function' then
                view[f](view)
              end
            end
          end

          if type(v.fallback) == 'function' then
            v.fallback(view)
            return true
          end

        end
      end
    end

    return true
  end
  return false
end

function m:commonViewJoystickFunction()
  self.cvjf = self.cvjf or {
    BtnA = {
      funcs = {
        'onBtnClose',
      },
    },
  }
  return self.cvjf
end

function m:addBtnToFunction(view, options)
  -- logd('addBtnToFunction %s', view.classname)
  view.__joystick_functions = options
end

