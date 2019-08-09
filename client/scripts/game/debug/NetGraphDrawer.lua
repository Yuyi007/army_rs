
class('NetGraphDrawer')

local m = NetGraphDrawer

local Text = UnityEngine.UI.Text
local Image = UnityEngine.UI.Image
local RectTransform = UnityEngine.RectTransform
local Rect = UnityEngine.Rect

local historyNetData           = {}
local maxHistoryNetDataNum     = 64
local selectedNetDataKeys      = {}
local maxSelectedNetDataKeyNum = 3
local maxYValue                = 1000.0

local graphX                   = 0
local graphY                   = 0
local graphWidth               = 192
local graphHeight              = 64

function m.startUpdateStats(parent, x, y, width, height)
  if m.updateStatsHandle then return end
  if x then graphX = x end
  if y then graphY = y end
  if width then graphWidth = width end
  if height then graphHeight = height end

  m.updateStatsHandle = coroutineStart(function (delta)
    m.initNetGraph(parent)
    coroutine.yield()

    while true do
      m.updateNetData(true)
      m.drawNetGraph(true)
      coroutine.yield()
    end
  end, 0, {global=false})
end

function m.stopUpdateStats()
  if m.updateStatsHandle then
    scheduler.unschedule(m.updateStatsHandle)
    m.updateStatsHandle = nil
    m.destroyNetGraph()
  end
end

function m.updateNetData(yield)
  table.insert(historyNetData, clone(mp.detailedRate))
  if #historyNetData > maxHistoryNetDataNum then
    table.remove(historyNetData, 1)
  end

  -- select keys that hold current max values
  local kvs = {}
  for k, v in pairs(mp.allDetailed) do
    table.insert(kvs, {k, v})
  end
  if yield then coroutine.yield() end
  table.sort(kvs, function (a, b) return a[2] > b[2] end)

  selectedNetDataKeys = {}
  local curMaxYValue = 0
  for i = 1, #kvs do local v = kvs[i]
    if i > maxSelectedNetDataKeyNum then break end
    local key = v[1]
    curMaxYValue = curMaxYValue + (mp.detailedRate[key] or 0)
    table.insert(selectedNetDataKeys, key)
    if yield then coroutine.yield() end
  end

  if curMaxYValue > maxYValue then
    maxYValue = curMaxYValue
  end
end

function m.initNetGraph(parent)
  local self = m
  local trans = 0.5
  -- local axisColor = Color(1, 1, 1, trans)
  -- local backgroundColor = Color(0, 0, 0, 0)
  local keyColors = { Color(1, 0, 0, trans), Color(0, 1, 0, trans), Color(1, 1, 0, trans) }

  local xStep = graphWidth / maxHistoryNetDataNum

  self.netText = GameObject()
  local text = self.netText:AddComponent(Text)
  text.font = UnityEngine.Resources.GetBuiltinResource(UnityEngine.Font, "Arial.ttf")
  text.fontSize = 12
  self.netText:GetComponent(RectTransform).anchoredPosition = Vector2(8, 26)
  self.netText:GetComponent(RectTransform).sizeDelta = Vector2(600, 30)

  local parentGo = parent.gameObject
  parentGo:addChild(self.netText)

  self.netBars = {}
  for i = 1, maxHistoryNetDataNum, 1 do
    local group = {}
    for j = 1, maxSelectedNetDataKeyNum, 1 do
      local bar = GameObject()
      local image = bar:AddComponent(Image)
      image.color = keyColors[j]
      bar:GetComponent(RectTransform).anchoredPosition = Vector2(graphX + xStep * (i - 1), graphY)
      bar:GetComponent(RectTransform).sizeDelta = Vector2(xStep, 0)
      bar:GetComponent(RectTransform).pivot = Vector2(0.5, 0)
      parentGo:addChild(bar)
      table.insert(group, bar)
    end
    table.insert(self.netBars, group)
  end
end

function m.destroyNetGraph()
  local self = m
  unity.destroy(self.netText)

  for _, group in ipairs(self.netBars) do
    for i = 1, #group do local bar = group[i]
      unity.destroy(bar)
    end
  end
  self.netBars = {}
end

function m.drawNetGraph(yield)
  local netStats = string.format(
    "Ping:%d ms,%d ms In:%d KB,%.3f KB/S Out: %d KB,%.3f KB/S Graph:[R]%s,[G]%s,[Y]%s,y-max %.3f",
    mp:getLastRTT(), mp:getAverageRTT(),
    mp.allReceived / 1000, mp.receiveRate / 1000.0,
    mp.allSent / 1000, mp.sentRate / 1000.0,
    tostring(selectedNetDataKeys[1]), tostring(selectedNetDataKeys[2]),
    tostring(selectedNetDataKeys[3]), maxYValue / 1000.0)

  m.netText:GetComponent(Text).text = netStats

  m._drawNetGraphWithImages(yield)
end

function m._drawNetGraphWithImages(yield)
  local barMaxHeight = graphHeight - 10
  local yScale = maxYValue * 1.0 / barMaxHeight
  local dataIndex = 1

  -- logd("selectedNetDataKeys=%s", peek(selectedNetDataKeys))
  -- logd("historyNetData=%s", peek(historyNetData))

  for dataIndex = 1, #historyNetData, 1 do
    local y = graphY
    for keyIndex = 1, #selectedNetDataKeys, 1 do
      local bar = m.netBars[dataIndex][keyIndex]
      local valueTop = historyNetData[dataIndex][selectedNetDataKeys[keyIndex]] or 0
      local oldY = y
      local height = valueTop / yScale
      y = graphY + height
      local rectTransform = bar:GetComponent(RectTransform)
      rectTransform.anchoredPosition = Vector2(rectTransform.anchoredPosition[1], oldY)
      rectTransform.sizeDelta = Vector2(rectTransform.sizeDelta[1], height)
    end
    if yield then coroutine.yield() end
  end
end

-- Deprecated: drawing on texture is slow
function m.drawNetGraphWithTexture()
  local netStats = string.format(
    "Ping:%d ms,%d ms\nIn:%d KB,%.3f KB/S\nOut: %d KB,%.3f KB/S\nGraph:[R]%s,[G]%s,[Y]%s,y-max %.3f",
    mp:getLastRTT(), mp:getAverageRTT(),
    mp.allReceived / 1000, mp.receiveRate / 1000.0,
    mp.allSent / 1000, mp.sentRate / 1000.0,
    tostring(selectedNetDataKeys[1]), tostring(selectedNetDataKeys[2]),
    tostring(selectedNetDataKeys[3]), maxYValue / 1000.0)

  local comp = GameObject.Find('/ShowStats'):GetComponent(LBoot.ShowStatsBehaviour)
  comp.CustomStats = netStats
  comp.Rect = Rect(340, 0, 400, 200)

  local image, imageRect = m._drawNetGraphWithTexture()
  if image and imageRect then
    imageRect[1], imageRect[2] = 500, 1
    comp.Image, comp.ImageRect = image, imageRect
  end
end

function m._drawNetGraphWithTexture(yield)
  local trans = 0.5
  local axisColor = Color(1, 1, 1, trans)
  local backgroundColor = Color(0, 0, 0, 0)
  local keyColors = { Color(1, 0, 0, trans), Color(0, 1, 0, trans), Color(1, 1, 0, trans) }

  -- xStep: width of one data bar
  -- yScale: 1 pixel for yScale bytes/second
  local xStep = graphWidth / maxHistoryNetDataNum
  local yScale = maxYValue * 1.0 / graphHeight

  local imageRect = Rect(0, 80, graphWidth, graphHeight)
  local image = Texture2D(graphWidth, graphHeight)
  local dataIndex = 1

  -- logd("selectedNetDataKeys=%s", peek(selectedNetDataKeys))
  -- logd("historyNetData=%s", peek(historyNetData))

  for x = 0,graphWidth-1,1 do
    local keyIndex = 1
    if x <= xStep * dataIndex then
    elseif dataIndex < #historyNetData then
      dataIndex = dataIndex + 1
    end
    local valueTop = historyNetData[dataIndex][selectedNetDataKeys[keyIndex]] or 0

    for y = 0,graphHeight-1,1 do
      local c = backgroundColor
      if x == 0 or y == 0 then
        c = axisColor
      elseif x <= xStep * dataIndex then
        if y * yScale <= valueTop then
          c = keyColors[keyIndex]
        elseif keyIndex < #selectedNetDataKeys then
          keyIndex = keyIndex + 1
          local value = historyNetData[dataIndex][selectedNetDataKeys[keyIndex]] or 0
          valueTop = valueTop + value
        end
      end
      image:SetPixel(x, y, c)
    end

    if yield then coroutine.yield() end
  end

  image:Apply(false)

  return image, imageRect
end
