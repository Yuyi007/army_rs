ViewUnique('DebuggerView', 'prefab/ui/others/debugger', function(self, options)
  self.options = DebuggerView.loadDebuggerSettings()
  self.options = table.merge(self.options, options)

  self.colorIdx = 0
  self.alphaIdx = 0

  if game.debuggerView then
    error("There only can be one DebuggerView")
  end
  game.debuggerView = self
end)

local m = DebuggerView
local Color = UnityEngine.Color
local Text = UnityEngine.UI.Text
local Image = UnityEngine.UI.Image
local RectTransform = UnityEngine.RectTransform
local Rect = UnityEngine.Rect

local MOVE_SCALE = 0.02

function m.defaultDebuggerSettings()
  return {
    minimized = false, -- start minimized
    enableNet = false, -- enable net profiler?
    enableLua = 0, -- enable lua profiler? (0 - disabled, 1 - time, 2 - alloc)
    enableMem = false, -- enable memory profiler?
    enableLogs = false, -- enable debugger logs?
    enableStats = true, -- enable stats?
  }
end

function m.loadDebuggerSettings()
  logd('DebuggerView: loadDebuggerSettings...')

  local text = unity.getString('app.debuggerSettings')
  local settings = nil

  if text and text ~= '' then
    local ok, res = pcall(function () return cjson.decode(text) end)
    if ok then settings = res end
  end

  return table.merge(m.defaultDebuggerSettings(), settings)
end

function m.saveDebuggerSettings(settings)
  settings = settings or game.debuggerView.options
  local json = cjson.encode(settings)
  unity.setString('app.debuggerSettings', json)

  logd('DebuggerView: saveDebuggerSettings success')
end

function m:init()
  local canvas = self.gameObject:GetComponent(UnityEngine.Canvas)
  canvas.sortingOrder = 50 -- set always on top

  local canvasScaler = self.gameObject:GetComponent(UI.CanvasScaler)
  canvasScaler.uiScaleMode = UI.CanvasScaler.ScaleMode.ScaleWithScreenSize
  canvasScaler.referenceResolution = Vector2(1136, 640)

  local rect = self.btnEnlarge:GetComponent(RectTransform)
  local _, onMove = self:registerTouch()
  onMove(nil, Vector2(
    -rect.anchoredPosition[1] - 200 / MOVE_SCALE,
    -rect.anchoredPosition[2] + 80 / MOVE_SCALE))

  self.panel_statsPanel_txtLine1:GetComponent(Text).text = ""

  if self.options.minimized then
    self:minimize()
  else
    self:maximize()
  end
end

function m:exit()
  m.saveDebuggerSettings()
  game.debuggerView = nil

  self:minimize()
end

function m:registerTouch()
  local rects = {
    self.btnEnlarge:GetComponent(RectTransform),
    self.panel:GetComponent(RectTransform)
  }
  local function onClickEnlarge()
    self:maximize()
  end
  local function onMove(pos, delta)
    for i = 1, #rects do local rect = rects[i]
      rect:set_anchoredPosition(rect:get_anchoredPosition() + delta * MOVE_SCALE)
    end
  end
  self.onHandleDragButton = TouchUtil.click(onClickEnlarge, nil, nil, onMove)
  self.onHandleDrag = TouchUtil.click(nil, nil, nil, onMove)

  self.btnEnlarge:registerTouch(self.onHandleDragButton)
  self.panel:registerTouch(self.onHandleDrag)
  self.panel_netPanel:registerTouch(self.onHandleDrag)
  self.panel_luaPanel:registerTouch(self.onHandleDrag)
  self.panel_memPanel:registerTouch(self.onHandleDrag)
  self.panel_statsPanel:registerTouch(self.onHandleDrag)
  self.panel_toolsPanel:registerTouch(self.onHandleDrag)

  return rects, onMove
end

function m:initNetPanel()
  local x = self.panel_netPanel_xAxis.transform:get_rect():get_x() + 3
  local y = self.panel_netPanel_yAxis.transform:get_rect():get_y() + 2
  local width = self.panel_netPanel_xAxis.transform:get_rect():get_width()
  local height = self.panel_netPanel_yAxis.transform:get_rect():get_height()

  NetGraphDrawer.startUpdateStats(self.panel_netPanel, x, y, width, height)
end

function m:exitNetPanel()
  NetGraphDrawer.stopUpdateStats()
end

function m:initLuaPanel()
  local margin = 4
  local x = self.panel_luaPanel.transform:get_rect():get_x() + margin
  local y = self.panel_luaPanel.transform:get_rect():get_y() + margin
  local width = self.panel_luaPanel.transform:get_rect():get_width() - margin * 2
  local height = self.panel_luaPanel.transform:get_rect():get_height() - margin * 2

  if self.options.enableLua == 1 then
    LuaTimeGraphDrawer.startDraw(self.panel_luaPanel, x, y, width, height)
  elseif self.options.enableLua == 2 then
    if game.platform ~= 'ios' then
      LuaAllocGraphDrawer.startDraw(self.panel_luaPanel, x, y, width, height)
    end
  end
end

function m:exitLuaPanel()
  if self.options.enableLua == 1 then
    LuaTimeGraphDrawer.stopDraw()
  elseif self.options.enableLua == 2 then
    if game.platform ~= 'ios' then
      LuaAllocGraphDrawer.stopDraw()
    end
  end
end

function m:initMemPanel()
  local margin = 4
  local x = self.panel_memPanel.transform:get_rect():get_x() + margin
  local y = self.panel_memPanel.transform:get_rect():get_y() + margin
  local width = self.panel_memPanel.transform:get_rect():get_width() - margin * 2
  local height = self.panel_memPanel.transform:get_rect():get_height() - margin * 2

  MemGraphDrawer.startDraw(self.panel_memPanel, x, y, width, height)
end

function m:exitMemPanel()
  MemGraphDrawer.stopDraw()
end

function m:initStatsPanel()
  StatsDrawer.startDraw(self.panel_statsPanel, self.panel_statsPanel_txtLine1)
end

function m:exitStatsPanel()
  StatsDrawer.stopDraw()
end

function m:initLogPanel()
  self.panel_logPanel:setVisible(true)
  self.panel_netPanel:setVisible(false)
  self.panel_luaPanel:setVisible(false)
  self.panel_memPanel:setVisible(false)

  self:exitNetPanel()
  self:exitLuaPanel()
  self:exitMemPanel()

  local input = self.panel_toolsPanel_inputEval:GetComponent(UnityEngine.UI.InputField)
  local text = input.text
  if text and string.len(text) > 0 then
    local fstr = text
    if not string.match(text, 'return') then
      fstr = string.format('return %s', text)
    end
    local f = loadstring(fstr)
    dvclear()
    dvlog('Eval result:\n%s', inspect(f()))
  end

  LuaLogDrawer.startDraw(self.panel_logPanel, self.panel_logPanel_txtLine1)
end

function m:exitLogPanel()
  self.panel_logPanel:setVisible(false)
  self.panel_netPanel:setVisible(true)
  self.panel_luaPanel:setVisible(true)
  self.panel_memPanel:setVisible(true)

  LuaLogDrawer.stopDraw()
end

function m:onPanel_toolsPanel_btnToggleNet()
  self.options.enableNet = (not self.options.enableNet)
  if self.options.enableNet then
    FloatingTextFactory.makeNormal{ text='Show Net Graph' }
    self:initNetPanel()
  else
    self:exitNetPanel()
  end
end

function m:onPanel_toolsPanel_btnToggleLua()
  if self.options.enableLua > 0 then
    self:exitLuaPanel()
  end

  self.options.enableLua = (self.options.enableLua + 1) % 3

  if self.options.enableLua > 0 then
    if self.options.enableLua == 1 then
      FloatingTextFactory.makeNormal{ text='Profiling Lua Time' }
    elseif self.options.enableLua == 2 then
      FloatingTextFactory.makeNormal{ text='Profiling Lua Memory Allocs (not available on iOS)' }
    end
    self:initLuaPanel()
  else
    self:exitLuaPanel()
  end
end

function m:onPanel_toolsPanel_btnToggleMem()
  self.options.enableMem = (not self.options.enableMem)
  if self.options.enableMem then
    FloatingTextFactory.makeNormal{ text='Profiling Lua Memory Objects' }
    self:initMemPanel()
  else
    self:exitMemPanel()
  end
end

function m:onPanel_toolsPanel_btnToggleStats()
  self.options.enableStats = (not self.options.enableStats)
  if self.options.enableStats then
    FloatingTextFactory.makeNormal{ text='Show Stats' }
    self:initStatsPanel()
  else
    self:exitStatsPanel()
  end
end

function m:onPanel_toolsPanel_btnToggleEval()
  self.options.enableLogs = (not self.options.enableLogs)
  if self.options.enableLogs then
    FloatingTextFactory.makeNormal{ text='Show Logs' }
    self:initLogPanel()
  else
    self:exitLogPanel()
  end
end

function m:onPanel_toolsPanel_btnToggleJIT()
  if game.platform == 'android' then
    local s1, s2 = jit.status()
    if s1 then
      jit.off()
      self:testVector3()
    else
      jit.on()
      self:testVector3()
    end
    s1, s2 = jit.status()
    FloatingTextFactory.makeNormal{ text=string.format(
      "JIT: enabled=%s desc=%s", tostring(s1), tostring(s2)) }
  else
    FloatingTextFactory.makeNormal{ text=string.format(
      "JIT not supported by this platform") }
  end
end

function m:testVector3()
  collectgarbage('collect')
  local a = Vector3(1, 2, 3)
  local b = Vector3(2, 3, 4)
  local on, _ = jit.status()
  local t = os.clock()

  for i = 1, 15000 do
    a = Vector3.new(1, 2, 3)
    b = Vector3.new(2, 3, 4)
  end
  logd('testVector3 new: jit=%s clock=%d', tostring(on), os.clock() - t)

  for i = 1, 150000 do
    a = a + b
  end
  logd('testVector3 add: jit=%s clock=%d', tostring(on), os.clock() - t)
end

function m:onPanel_toolsPanel_btnToggleCheat()
  -- game.testCheat = (not game.testCheat)

  -- FloatingTextFactory.makeNormal{ text=string.format(
  --   "Cheat mode: now %s", tostring(game.testCheat)) }

  self.panel_toolsPanel_btnToggleCheat.gameObject:GetComponentInChildren(UnityEngine.UI.Text):set_text('Mono GC')

  monoGC()
end

function m:onPanel_toolsPanel_btnLuaGC()
  local oldCount = tonumber(collectgarbage("count"))
  collectgarbage("collect")
  local curCount = tonumber(collectgarbage("count"))

  FloatingTextFactory.makeNormal{ text=string.format(
    "before %0.2f KB after %0.2f KB", oldCount, curCount) }
end

local togglePollCount = 0
function m:onPanel_toolsPanel_btnTogglePoll()
  if game.script == 'debug folder' then
    togglePollCount = togglePollCount + 1
    if togglePollCount % 2 == 1 then
      stopScriptMonitoring()
      FloatingTextFactory.makeNormal{ text='Script monitoring stopped' }
    else
      startScriptMonitoring()
      FloatingTextFactory.makeNormal{ text='Script monitoring started' }
    end
  else
    FloatingTextFactory.makeNormal{ text='In device mode' }
  end
end

function m:onPanel_toolsPanel_btnStartFrame()
  FrameDebugger.startFrame()
  FloatingTextFactory.makeNormal{ text='Frame update started!' }
end

function m:onPanel_toolsPanel_btnStopFrame()
  FrameDebugger.stopFrame()
  FloatingTextFactory.makeNormal{ text='Frame update stopped!' }
end

function m:onPanel_toolsPanel_btnStepFrame()
  FrameDebugger.stepFrame()
end

function m:onPanel_toolsPanel_btnEnterDebug()
  ui:goto(DebugServerScene.new())
end

function m:onPanel_toolsPanel_btnUpdate()
  ui:goto(UpdatingScene.new())
end

function m:onPanel_toolsPanel_btnLogin()
  ui:goto(LoginView.new())
end

function m:onPanel_toolsPanel_btnQuality()
  ui:push(QualityView.new(self))
end

function m:onPanel_toolsPanel_btnReconnect()
  testReconnect()
end

function m:onPanel_toolsPanel_btnDestroy()
  self:destroy()
end

function m:onPanel_toolsPanel_btnMinimize()
  m.saveDebuggerSettings()
  self:minimize()
end

local panelColors = {
  {0.0, 0.0, 0.0},
  {1.0, 1.0, 1.0},
}
local panelAlphas = {
  0.0, 0.2, 0.4, 0.6, 0.8, 1.0
}

function m:onPanel_toolsPanel_btnColor()
  local c = panelColors[self.colorIdx + 1]
  self.panel:GetComponent(Image).color = Color(
    c[1], c[2], c[3], panelAlphas[self.alphaIdx + 1])

  self.colorIdx = (self.colorIdx + 1) % #panelColors
end

function m:onPanel_toolsPanel_btnAlpha()
  local c = panelColors[self.colorIdx + 1]
  self.panel:GetComponent(Image).color = Color(
    c[1], c[2], c[3], panelAlphas[self.alphaIdx + 1])

  self.alphaIdx = (self.alphaIdx + 1) % #panelAlphas
end

function m:onPanel_toolsPanel_btnCustom1()
  self:toggleGameObjectActive('UIRoot')
  self:toggleGameObjectActive(md.account.id)
end

function m:onPanel_toolsPanel_btnCustom2()

end

function m:onPanel_toolsPanel_btnCustom3()
end

function m:onPanel_toolsPanel_btnCustom4()

end

function m:onPanel_toolsPanel_btnCustom5()
  self:toggleGameObjectActive('joystick')
  self:toggleGameObjectActive('GoKit')
end

local lastToggleActiveGameObjects = {}
function m:toggleGameObjectActive(path)
  local go = GameObject.Find(path) or lastToggleActiveGameObjects[path]
  local hint

  if go then
    go:SetActive(not go.activeInHierarchy)
    lastToggleActiveGameObjects[path] = go
    hint = string.format("%s active=%s", path, tostring(go.activeInHierarchy))
  else
    hint = string.format("%s not found", path)
  end

  FloatingTextFactory.makeNormal{ text=hint }
  logd(hint)
end

function m:onBtnEnlarge()
  -- will be handled by onClickEnlarge
end

function m:show()
  local app = GameObject.Find('/LBootApp')
  -- logd('DebuggerView.show app=%s', tostring(app))
  self.gameObject:setParent(app)
end

function m:destroy()
  self:exit()

  local app = GameObject.Find('/LBootApp')
  unity.destroy(self.gameObject)
end

function m:maximize()
  self.panel:setVisible(true)
  self.btnEnlarge:setVisible(false)

  self:initPanels()

  LuaScriptDebugger.start()
end

function m:minimize()
  self.panel:setVisible(false)
  self.btnEnlarge:setVisible(true)

  self:exitPanels()

  LuaScriptDebugger.stop()
end

function m:initPanels()
  if self.options.enableNet then self:initNetPanel() end
  if self.options.enableLua > 0 then self:initLuaPanel() end
  if self.options.enableMem then self:initMemPanel() end
  if self.options.enableStats then self:initStatsPanel() end
  if self.options.enableLogs then self:initLogPanel() end
end

function m:exitPanels()
  self:exitNetPanel()
  self:exitLuaPanel()
  self:exitMemPanel()
  self:exitStatsPanel()
  self:exitLogPanel()
end
