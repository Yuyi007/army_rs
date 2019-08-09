
class('BarGraph', function (self, parent, options)
  self.options = table.merge({
    barNum = 20,
    color = Color(1, 1, 0.1, 0.5),
    x = 0,
    y = 0,
    width = 192,
    height = 64,
  }, options)

  self.parent = parent
  self.barNum = self.options.barNum
  self.barColor = self.options.color
  self.barHeight = nil
  self.graphX = self.options.x
  self.graphY = self.options.y
  self.graphWidth = self.options.width
  self.graphHeight = self.options.height
end)

local m = BarGraph

local Time = UnityEngine.Time
local Text = UnityEngine.UI.Text
local Image = UnityEngine.UI.Image
local RectTransform = UnityEngine.RectTransform
local Rect = UnityEngine.Rect

function m:init()
  local yStep = self.graphHeight / self.barNum
  self.barHeight = yStep - 2

  self.barGroups = {}
  for i = 1, self.barNum, 1 do
    local group = {}
    local curX = self.graphX + 4
    local curY = self.graphY + self.graphHeight - yStep * (i - 1) - self.barHeight / 2

    local bar = GameObject()
    local image = bar:AddComponent(Image)
    image.color = self.barColor
    bar:GetComponent(RectTransform).pivot = Vector2(0, 0.5)
    bar:GetComponent(RectTransform).anchoredPosition = Vector2(curX, curY)
    bar:GetComponent(RectTransform).sizeDelta = Vector2(1, self.barHeight)

    local text1 = GameObject()
    local text = text1:AddComponent(Text)
    text.font = UnityEngine.Resources.GetBuiltinResource(UnityEngine.Font, "Arial.ttf")
    text.fontSize = 12
    text1:GetComponent(RectTransform).pivot = Vector2(0, 0.5)
    text1:GetComponent(RectTransform).anchoredPosition = Vector2(curX, curY)
    text1:GetComponent(RectTransform).sizeDelta = Vector2(100, 15)

    local text2 = GameObject()
    local text = text2:AddComponent(Text)
    text.font = UnityEngine.Resources.GetBuiltinResource(UnityEngine.Font, "Arial.ttf")
    text.fontSize = 12
    text2:GetComponent(RectTransform).pivot = Vector2(0, 0.5)
    text2:GetComponent(RectTransform).anchoredPosition = Vector2(curX, curY)
    text2:GetComponent(RectTransform).sizeDelta = Vector2(500, 15)

    local parentGo = self.parent.gameObject
    parentGo:addChild(bar)
    parentGo:addChild(text1)
    parentGo:addChild(text2)

    group.bar = bar
    group.text1 = text1
    group.text2 = text2

    table.insert(self.barGroups, group)
  end
end

function m:exit()
  for _, group in ipairs(self.barGroups) do
    for _, go in pairs(group) do
      unity.destroy(go)
    end
  end
  self.barGroups = {}
end

function m:updateBar(groupIndex, percent, text, offset)
  offset = offset or 50

  local group = self.barGroups[groupIndex]
  local bar = group.bar
  local text1 = group.text1
  local text2 = group.text2

  local rectBar = bar:GetComponent(RectTransform)
  local rectText1 = text1:GetComponent(RectTransform)
  local rectText2 = text2:GetComponent(RectTransform)
  local barWidth = self.graphWidth * percent / 100.0

  text1:GetComponent(Text).text = string.format("%.2f%%", percent)
  text2:GetComponent(Text).text = text
  rectBar.sizeDelta = Vector2(barWidth, self.barHeight)
  rectText1.anchoredPosition = Vector2(
    rectBar.anchoredPosition[1], rectText1.anchoredPosition[2])
  rectText2.anchoredPosition = Vector2(
    rectBar.anchoredPosition[1] + offset,
    rectText1.anchoredPosition[2])
end
