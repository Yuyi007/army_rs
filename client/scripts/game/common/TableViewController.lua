class('TableViewController', function(self, tag, env)
  self.env = env
  self.tag = tag

  self.heightForRowAtIndexPath     = env.heightForRowAtIndexPath       -- 改变行的高度
  self.cellForRowAtIndexPath       = env.cellForRowAtIndexPath         --绘制Cell
  self.numberOfSectionsInTableView = env.numberOfSectionsInTableView   --指定有多少个分区(Section)，默认为1
  self.numberOfRowsInSection       = env.numberOfRowsInSection         --指定每个分区中有多少行，默认为1
  self.updateCellData              = env.updateCellData             ---- 过时的方法  需要用类似功能直接 调用 updateTableView(true)
  self.customScrollCheck           = env.customScrollCheck             -- 自定义滚动检测(可选)
  self.extendParameter             = env.extendParameter or 0.1    -- 延伸出屏幕的百分? 才做回收处理。 延伸的多。快速滚动起来 感觉流畅
  self.direction                   = env.direction
  self.cellPool                    = {}
  self.showingCells                = {}
  self.templateCells               = {}
  self.cacheHeight                 = {}

end)

local Direction={
  downhill ='downhill', --方向向下
  upward   ='upward',   --方向向上
}
local LayoutElement = UI.LayoutElement
local VerticalLayoutGroup = UI.VerticalLayoutGroup
local HorizontalLayoutGroup = UI.HorizontalLayoutGroup
local ContentSizeFitter = UI.ContentSizeFitter
local unity = unity
local abs = math.abs

local m = TableViewController



function m:init()
  self.direction = self.direction or Direction.downhill 
  self.sv = self.env.sv
  self.view = self.env.view                                           --chatview
  self.svTransform = self.sv.transform
  self.svRectTransform = self.sv.gameObject:getComponent(RectTransform)
  self.goList = self.sv.transform:find("List")
  self.goListTransform = self.goList
  self.goListRectTransform = self.goListTransform:getComponent(RectTransform)
  local goListTransform = self.goListTransform

  if self.direction == Direction.downhill then
    goListTransform:set_pivot(Vector2(0.5, 1))
    goListTransform:set_anchorMin(Vector2(0.5, 1))
    goListTransform:set_anchorMax(Vector2(0.5, 1))   --(正上角)
  elseif self.direction == Direction.upward then
    goListTransform:set_pivot(Vector2(0.5, 0))
    goListTransform:set_anchorMin(Vector2(0.5, 0))
    goListTransform:set_anchorMax(Vector2(0.5, 0))   --(正下角)
  end
  self:setGolListSizeHeight(1)                       --设置list宽和高
  local rect = self.goList:GetComponent(RectTransform)
  rect:set_anchoredPosition(Vector2(rect:get_anchoredPosition()[1], 0))
  self:gen()
  self:MakeVertListOptimized(self.env)
end

function m:exit()
  self:exitTemplateCells()

  -- logd('TableViewController.exit')
  if self.env then
    -- logd('TableViewController.exit env')
    local sv = self.env.sv
    local view = self.env.view
    if sv and view then
      -- logd('TableViewController.exit sv view')
      local sv_rect = sv.scrollRect
      if sv_rect then
        -- logd('TableViewController.exit sv_rect')
        view:removeAllListeners(sv_rect:get_onValueChanged())
      end
    end
    self.env = nil
  end
end

function m:exitTemplateCells()
  for k, v in pairs(self.templateCells) do
    if not_null(v.gameObject) then
      v.gameObject:destroy()
    end
    v:exit()
  end
  self.templateCells = {}
end

function m:viewPortSize()
  return self.svRectTransform:get_rect():get_height()
end

function m:genTemplateCell(cellIdentifier, cell)
  -- unity.beginSample('TableViewController.genTemplateCell')

  -- local cell = self:genCell(section, row)
  -- logd("gen templateCells 11112314312")
  local cellTransform = cell.transform
  if self.direction == Direction.downhill then
    cellTransform:set_anchorMin(Vector2(0.5, 1))
    cellTransform:set_anchorMax(Vector2(0.5, 1))   --左上角
  elseif self.direction == Direction.upward then
    cellTransform:set_anchorMin(Vector2(0.5, 0))
    cellTransform:set_anchorMax(Vector2(0.5, 0))   --左下角
  end
  cellTransform:set_anchoredPosition(Vector2(-self.svRectTransform:get_rect():get_width(), 0))
  cell:setParent(self.goList:get_parent(), false)
  -- cellTransform:set_name("Template_"..cellIdentifier)
  self.templateCells[cellIdentifier] = cell

  -- unity.endSample()
end

function m:getTemplateCell(cellIdentifier, section, row)
  if self.templateCells[cellIdentifier] == nil then
    -- loge("error templateCells type:"..tostring(cellIdentifier))
    self.templateCells[cellIdentifier] = self:genCell(section, row)
  end
  return self.templateCells[cellIdentifier]
end

function m:dequeueReusableCellWithIdentifier(cellIdentifier, selectFunc, data)
  if self.cellPool[cellIdentifier] == nil then self.cellPool[cellIdentifier] = {} end
  local pool = self.cellPool[cellIdentifier]

  local size = #pool
  if size > 0 then
    if selectFunc then
      for i = size, 1, -1 do
        -- logd('try select id=%s i=%d cell=%s data=%s', cellIdentifier, i, tostring(pool[i]), tostring(data))
        if selectFunc(pool[i], data) then
          -- logd('select id=%s i=%d cell=%s data=%s', cellIdentifier, i, tostring(pool[i]), tostring(data))
          return table.remove(pool, i)
        end
      end
    end

    local top = pool[size]
    pool[size] = nil
    return top
  else
    return nil
  end

end

function m:isShowEnd()  --展示到底边了
  return self:getEndLowerLimb() >  self:screenEnd()
end      --50

function m:isShowHead()  --展示到顶边边了
  if self:getHeadTopLimb() then
    return self:getHeadTopLimb() <= self:screenHead()
  else
    return false
  end
end

function m:isDataAllShow()  --所有的数据展示完了
  if self:getNextIndexPath() then
    return false
  else
    return true
  end
end

function m:isForwardDataAllShow()
  if self:getForwardIndexPath() then
    return false
  else
    return true
  end
end

-- 更新tableview
-- isToHead 是否置起始位置  还是保持当前高度
-- sortCells 对cells排序，减少cell的update
function m:updateTableView(isToHead, sortCells)
  unity.beginSample('TableViewController.updateTableView')

  if isToHead == nil then
    isToHead = true
  end

  if sortCells and #self.showingCells > 1 then
    sortCells(self.showingCells)
  end

  self:poolAll()

  if isToHead then
    self:setGoListPosY(0)
    if self.sv_rect then
      self.sv_rect:StopMovement()
    end
  end
  self:gen()

  unity.endSample()
end

function m:getSections()
  local sectionNum = 1
  if self.numberOfSectionsInTableView then
    sectionNum = self.numberOfSectionsInTableView(self.view, self)
  end
  return sectionNum
end

function m:updateToIndexPath(targetSection, targetRow)
  self:poolAll()
  local defaultSections = 1
  local defaultRow      = 1
  local rowNum          = self.numberOfRowsInSection(self.view, self, defaultSections)  --如果有东西  就去 1  1 位置
  local sectionNum      = self:getSections()
  if sectionNum > 0 and rowNum > 0 then
    local _section     = 1
    local _row         = 1
    local _height      = 0
    local _lastSection = 1
    local _lastRow     = 1
    local goH = 0
    while _section
    do
      _height = _height +  self:getHeight(_section, _row, nil)
      if targetSection == _section and targetRow == _row then
        goH = _height
      end
      _section, _row = self:getNextWithIndexPath(_section, _row)
      if _section then
        _lastSection = _section
        _lastRow     = _row
      end
    end
    if _height > self:viewPortSize() then
      local goY = goH - self:viewPortSize()
      if self.direction == Direction.downhill then
        self:setGoListPosY(goY)
      elseif self.direction == Direction.upward then
        self:setGoListPosY(-goY)
      end
      self:setGolListSizeHeight(_height)
    else
      self:setGoListPosY(0)
    end
    local cell = self:genCell(_lastSection, _lastRow)
    self:appearCell(cell)
    local showingCells = self.showingCells
    showingCells[#showingCells + 1] = cell
    local poxY = 0
    if self.direction == Direction.downhill then
      poxY = _height - self:getHeight(_lastSection, _lastRow, cell)
    elseif self.direction == Direction.upward then
      poxY = _height
    end

    self:setCellPosition(cell, self:correctVector(0, poxY), _lastSection, _lastRow)
    while (self:isShowHead() or self:isForwardDataAllShow()) == false
    do
      self:genHead()
    end
  end
end

function m:updateToEnd()  -- 更新tableview到最后一条数据的位置
  local _lastSection      = self:getSections()
  local _lastRow = self.numberOfRowsInSection(self.view, self, _lastSection)
  self:updateToIndexPath(_lastSection, _lastRow)
end


function m:updateShowingCell()
  for _i, cell in pairs(self.showingCells) do
    if self.updateCellData then
      self.updateCellData(self.view, self, cell, cell.section, cell.row)
    end
  end
end

function m:setGoListPosY(posY)
  self:setGoListPos(Vector2(self.goListTransform:get_anchoredPosition()[1], posY))
end

function m:setGoListPos(pos)
  self.goListTransform:set_anchoredPosition(pos)
end

function m:getGoListPos()
  return self.goListTransform:get_anchoredPosition()
end

function m:decrGoListY(num)
  local pos = self.goListTransform:get_anchoredPosition()
  self.goListTransform:set_anchoredPosition(Vector2(pos[1], pos[2] + num))
end

function m:poolAll()  --移除全部cell
  local showingCells = self.showingCells

  for i = #showingCells, 1 ,-1 do
    self:poolEnd()
  end
end

function m:gen()
  -- unity.beginSample('TableViewController.gen')

  while (self:isShowEnd() or self:isDataAllShow()) == false
  do
    self:check()
  end

  -- unity.endSample()
end

function m:appearCell(cell)
  -- unity.beginSample('TableViewController.appearCell')

  -- logd('appearCell %s %s', tostring(cell), debug.traceback())
  -- cell.gameObject:setVisible(true)

  -- unity.endSample()
end

local invisiblePos = Vector2.new(5000,5000)
function m:poolCell(cell)
  -- unity.beginSample('TableViewController.poolCell')

  -- cell.gameObject:setVisible(false)
  cell.transform:set_anchoredPosition(invisiblePos)

  -- unity.endSample()
end

function m:setGolListSize(size)
  self.goListTransform:set_sizeDelta(size)
end

function m:setGolListSizeHeight(height)
  self:setGolListSize(Vector2(self.goListTransform:get_sizeDelta()[1], height))
end

function m:genCell(section, row)
  -- unity.beginSample('TableViewController.genCell')

  -- logd("gen cell for tableview section and row:"..tostring(section)..","..tostring(row))
  local cell = self.cellForRowAtIndexPath(self.view, self, section, row)
  cell.tableTag   = self.tag
  if not cell.identifier then
    loge("error table view cell with out identifier, please make sure cell.identifier has a fittable value")
  end
  -- logd("ready to gen celltemplate:"..tostring(cell.identifier))
  if not self.templateCells[cell.identifier] then
    local cellTemplate = self.cellForRowAtIndexPath(self.view, self, section, row)
    self:genTemplateCell(cell.identifier, cellTemplate)
  end

  -- cell.transform:set_name(cell.identifier.."row--"..row)

  -- unity.endSample()
  return cell
end

function m:getNextWithIndexPath(section, row)
  if section >= self:getSections() and row >= self.numberOfRowsInSection(self.view, self, section) then
    return nil
  else
    local _section = 0
    local _row = 0
    if row >= self.numberOfRowsInSection(self.view, self, section) then
      for _section = section + 1, self:getSections() do
        if self.numberOfRowsInSection(self.view, self, _section) > 0 then
          _row = 1
          return _section, _row
        end
      end
      return nil
    else
      _section = section
      _row = row + 1
    end
    -- logd(">>>>[getNextS]:%s,[getNextR]:%s",tostring(_section),tostring(_row))
    return _section, _row
  end
end

function m:getNextIndexPath()
  local endCell = self:getEndCell()
  if endCell == nil then
    local defaultSections = 1
    local defaultRow = 1
    local rowNum = self.numberOfRowsInSection(self.view, self, defaultSections)  --如果有东西  就去 1  1 位置
    if rowNum > 0 then
      return 1, 1
    else
      return nil
    end
  end
  local nextS, nextR = self:getNextWithIndexPath(endCell.section, endCell.row)
  -- logd(">>>>[nextS]:%s,[nextR]:%s",tostring(nextS),tostring(nextR))
  return nextS, nextR
end

function m:getForwardWithIndexPath(section, row)
  if section == 1 and row <= 1 then
    return nil
  else
    local _section = 0
    local _row = 0
    if row <= 1 then
      for _section = section - 1, 1, -1 do
        _row = self.numberOfRowsInSection(self.view, self, _section)
        if _row > 0 then
          return _section, _row
        end
      end
      return nil
    else
      _section = section
      _row = row - 1
    end
    -- logd(">>>>[section]:%s,[row]:%s",tostring(_section),tostring(row))
    return _section, _row
  end
end

function m:getForwardIndexPath()
  local forwardCell = self:getHeadCell()
  if forwardCell == nil then return nil end
  return self:getForwardWithIndexPath(forwardCell.section, forwardCell.row)
end

function m:getHeight(section, row, cell)
  -- unity.beginSample('TableViewController.getHeight')
  -- logd(">>>>>>getHeight:%s",debug.traceback())
  if self.cacheHeight == nil then self.cacheHeight = {} end
  if self.cacheHeight[section] == nil then self.cacheHeight[section] = {} end

  local height
  if cell and type(cell.getHeight) == "function" then
    height = cell:getHeight()
  else
    height = self.heightForRowAtIndexPath(self.view, self, section, row)
  end
  self.cacheHeight[section][row] = height
  -- logd(">>>>[getHeight]:%s",tostring(height))
  -- unity.endSample()
  return height
end

function m:getCacheHeight(section, row)
  return self.cacheHeight[section][row]
end

function m:getEndPosY()
  -- logd(">>>>>>getHeadPosY:%s",debug.traceback())
  local showingCells = self.showingCells
  local endCell = showingCells[#self.showingCells]
  if endCell then
    -- logd(">>>>[endCell]:%s",tostring(abs(endCell.transform:get_anchoredPosition()[2])))
    return abs(endCell.transform:get_anchoredPosition()[2]) -- 不管方向 实际的 坐标是像 正 或 负 增长 。内部都是正增长
  else
    return 0
  end
end

function m:getHeadPosY()
  -- logd(">>>>>>getHeadPosY:%s",debug.traceback())
  local headCell = self:getHeadCell()
  if headCell then
    -- logd(">>>>[headCell]:%s",tostring(abs(headCell.transform:get_anchoredPosition()[2])))
    return abs(headCell.transform:get_anchoredPosition()[2]) -- 不管方向 实际的 坐标是像 正 或 负 增长 。内部都是正增长
  else
    return nil
  end
end

function m:getNextEndPosY(nSection, nRow, cell)
  -- logd(">>>>>>getNextEndPosY:%s",debug.traceback())
  local endLowerLime = self:getEndLowerLimb()
  if self.direction == Direction.downhill then
    -- logd(">>>>[getNextEndPosY111]:%s",tostring(endLowerLime))
    return endLowerLime
  elseif self.direction == Direction.upward then
    local height = self:getHeight(nSection, nRow, cell)
    local posY = endLowerLime +  height
    -- logd(">>>>[getNextEndPosY222]:%s",tostring(posY))
    return posY
  end
end

function m:getForwardHeadPosY(fSection, fRow, cell)
  -- logd(">>>>>>getForwardHeadPosY:%s",debug.traceback())
  local headTopLimb = self:getHeadTopLimb()
  if self.direction == Direction.downhill then
    local posY = abs(headTopLimb) - self:getHeight(fSection, fRow, cell) -- 不管方向 实际的 坐标是像 正 或 负 增长 。内部都是正增长
    -- logd(">>>>[getForwardHeadPosY111]:%s",tostring(posY))
    return posY
  elseif self.direction == Direction.upward then
    -- logd(">>>>[getForwardHeadPosY222]:%s",tostring(headTopLimb))
    return headTopLimb
  end
end

function m:getHeadCell()
  local headCell = self.showingCells[1]
  return headCell
end

function m:getEndCell()
  local showingCells = self.showingCells
  local EndCell = showingCells[#showingCells]
  return EndCell
end

function m:setCellPosition(cell, pos, section, row)
  -- unity.beginSample('TableViewController.setCellPosition')
  -- logd(">>>>>>setCellPosition:%s",debug.traceback())
  local cellTransform = cell.transform
  if self.direction == Direction.downhill then
    cellTransform:set_anchorMin(Vector2(0.5, 1))
    cellTransform:set_anchorMax(Vector2(0.5, 1))   --左上角
  elseif self.direction == Direction.upward then
    cellTransform:set_anchorMin(Vector2(0.5, 0))
    cellTransform:set_anchorMax(Vector2(0.5, 0))   --左下角
  end

  local le = cell.gameObject:getComponent(LayoutElement)
  if le then le:set_ignoreLayout(true) end
  cell:setParent(self.goList, false)
  cellTransform:set_anchoredPosition(pos)
  cell.section = section
  cell.row     = row
  local height = abs(pos[2])
  if self.direction == Direction.downhill then
     height = height + self:getHeight(section, row, cell)
     -- logd(">>>>[setPosition]:%s",tostring(height))
  end

  if  self.goListTransform:get_sizeDelta()[2] < height then
    self:setGolListSizeHeight(height)
  end

  -- unity.endSample()
end

function m:extendDistance()     --偏移值
  return self:viewPortSize() * self.extendParameter
end

function m:judgeNeedInHead()
  local headTopLimb = self:getHeadTopLimb()
  if headTopLimb then
    if headTopLimb > (self:screenHead() - self:extendDistance()) then   -- 顶部cell的
      self:genHead()
    end
  end
end

function m:judgeNeedOutHead()
  local headLowerLimb = self:getHeadLowerLimb()
  if headLowerLimb then
    if (self:screenHead() - self:extendDistance()) > headLowerLimb then    -- 顶部cell 的下边缘 比 屏幕显示顶 再高出的半个屏还高 就回收了
      self:poolHead()
    end
  end
end

function m:judgeNeedInEnd()
  if self:isDataAllShow() then return end
  if (self:screenEnd() + self:extendDistance()) > self:getEndLowerLimb() then
    self:genEnd()
  end
end

function m:judgeNeedOutEnd()
  if self:getEndTopLimb() > (self:screenEnd() + self:extendDistance())  then
    self:poolEnd()
  end
end

function m:getHeadLowerLimb()
  local nowHeadPosY = self:getHeadPosY()
  local nowHeadCell = self:getHeadCell()
  if nowHeadCell == nil then
    return 0
  else
    local height = 0
    height = self:getHeight(nowHeadCell.section, nowHeadCell.row, nowHeadCell)
    local posY = abs(nowHeadPosY) + height
    -- logd(">>>>[getHeadLowerLimb]:%s",tostring(posY))
    return posY
  end
end

function m:getEndLowerLimb()
  local nowEndPosY = self:getEndPosY()         --显示最后一个聊天的高度
  local nowEndCell = self:getEndCell()         --显示最后一个聊天
  if nowEndCell == nil then   --没有聊天记录
    return 0
  else
    local height = self:getCacheHeight(nowEndCell.section, nowEndCell.row)
    if self.direction == Direction.downhill then
      local posY = abs(nowEndPosY) + height
      -- logd(">>>>[getEndLowerLimb111]:%s",tostring(posY))
      return posY
    elseif self.direction == Direction.upward then
      ogd(">>>>[getEndLowerLimb222]:%s",tostring(abs(nowEndPosY)))
      return abs(nowEndPosY)
    end
  end
end

function m:getHeadTopLimb()
  local nowHeadPosY = self:getHeadPosY()
  local nowHeadCell = self:getHeadCell()
  if nowHeadCell == nil then
    return 0
  else
    local height = 0
    height = self:getHeight(nowHeadCell.section, nowHeadCell.row, nowHeadCell)
    local posY = abs(nowHeadPosY)
    if self.direction == Direction.downhill then
      -- logd(">>>>[HeadTopHeight111]:%s",tostring(posY))
      return posY
    elseif self.direction == Direction.upward then
      -- logd(">>>>[HeadTopHeight222]:%s",tostring(posY))
      -- logd(">>>>[HeadTopHeight333]:%s",tostring(height))
      return posY - height
    end
  end
end

function m:getEndTopLimb()
  local nowEndPosY = self:getEndPosY()
  local nowEndCell = self:getEndCell()
  if nowEndCell == nil then
    return 0
  else
    local height = self:getCacheHeight(nowEndCell.section, nowEndCell.row)
    local posY = abs(nowEndPosY)
    -- logd(">>>>[EndTopHeight]:%s",tostring(posY))
    return posY
  end
end

function m:poolHead()
  -- unity.beginSample('TableViewController.poolHead')

  local index = 1
  local section = 1
  local showingCells = self.showingCells
  local cell = showingCells[index]
  --  避免空列表 无法做验证
  if #showingCells <= 1 then
    -- unity.endSample()
    return
  end

  if cell and cell.identifier then
    local pool = self.cellPool[cell.identifier]
    self:poolCell(cell)
    pool[#pool + 1] = cell
    table.remove(showingCells, index)
  end

  -- unity.endSample()
end

function m:genHead()
  -- unity.beginSample('TableViewController.genHead')

  local genSection, genRow = self:getForwardIndexPath()
  if genSection == nil then
    -- unity.endSample()
    return
  end

  local cell = self:genCell(genSection, genRow)
  self:appearCell(cell)
  local forwardPosY = self:getForwardHeadPosY(genSection, genRow)
  self:setCellPosition(cell, self:correctVector(0, forwardPosY), genSection, genRow)
  local showingCells = self.showingCells
  table.insert(showingCells, 1, cell)  --每次都插入开始

  -- unity.endSample()
end

function m:correctVector(posX, posY)
  if self.direction == Direction.downhill then
    posY = -posY
  elseif self.direction == Direction.upward then
    posY = posY
  end
  return Vector2(posX, posY)
end

function m:poolEnd()
  -- unity.beginSample('TableViewController.poolEnd')

  local showingCells = self.showingCells
  local index = #showingCells
  local cell = showingCells[index]

  --  避免空列表 无法做验证
  -- if #showingCells <= 1 then
  --   unity.endSample()
  --   return
  -- end

  if cell and cell.identifier then
    local pool = self.cellPool[cell.identifier]
    self:poolCell(cell)
    pool[#pool + 1] = cell
    table.remove(showingCells, index)
    local height = self:getEndLowerLimb()--self:getBottomLowerLimb()
    self:setGolListSizeHeight(height) -- 调整高度
  end

  -- unity.endSample()
end

function m:genEnd()
  -- unity.beginSample('TableViewController.genEnd')

  if self:isDataAllShow() then
    -- unity.endSample()
    return
  end
  local genSection, genRow = self:getNextIndexPath()
  if genSection == nil then
    -- unity.endSample()
    return
  end

  local cell = self:genCell(genSection, genRow)
  local poxY = self:getNextEndPosY(genSection, genRow)
  self:appearCell(cell)
  local showingCells = self.showingCells
  showingCells[#showingCells + 1] = cell
  self:setCellPosition(cell, self:correctVector(0, poxY), genSection, genRow)

  -- unity.endSample()
end

function m:screenEnd() -- 屏幕底
  -- logd(">>>>>>screenEnd:%s",debug.traceback())
  local offset = self.goListRectTransform:get_anchoredPosition()[2]
  -- return self:viewPortSize() + abs(offset)  -- 所以偏移都按照正值计算  518
  if self.direction == Direction.downhill then   --上拉到屏幕底         =518
    local downLa = self:viewPortSize() + abs(offset) -- 所以偏移都按照正值计算
    -- logd(">>>>[downLa]:%s",tostring(downLa))
    return downLa
  elseif self.direction == Direction.upward then
    -- 下拉刷新
    local upLa = self:viewPortSize() - offset
    -- logd(">>>>[upLa]:%s",tostring(upLa))
    return upLa
  end
end

function m:screenHead()   -- 屏幕顶
  -- logd(">>>>>>screenHead:%s",debug.traceback())
  local offset = self.goListRectTransform:get_anchoredPosition()[2]
  if self.direction == Direction.downhill then
    offset = offset
  elseif self.direction == Direction.upward then
    offset = -offset
  end
  -- logd(">>>>[screenHead]:%s",tostring(offset))
  return offset
end

local function fixScrollingCanvas(view)
  -- local sv = view.sv
  -- local canvas = sv.gameObject:addComponent(Canvas)
  -- sv.gameObject:addComponent(UI.GraphicRaycaster)
  -- canvas:overrideDepth(true)
  -- view.canvas:refresh()
  -- canvas:setDepth(view:maxDepth() + 1)
  -- view:incrMaxDepth()
end

function m:MakeVertListOptimized(env)
  local view = env.view
  local sv   = env.sv

  view.sv = sv

  local goList  = sv.transform:find("List")
  local rt      = goList:GetComponent(RectTransform)
  local sv_rect = sv.scrollRect
  local sr_bar  = sv_rect:get_verticalScrollbar()
  self.sv_rect  = sv_rect

  local vlg = goList:GetComponent(VerticalLayoutGroup)
  if vlg then vlg:set_enabled(false) end

  local csf = goList:GetComponent(ContentSizeFitter)
  if csf then csf:set_enabled(false) end
  assert(goList)
  self:MakeVertListWrapped(env, true)

  if sv_rect:get_movementType() == UI.ScrollRect.MovementType.Elastic then
    sv_rect:set_movementType(UI.ScrollRect.MovementType.Clamped)
    view:performWithDelay(0.1, function()
      sv_rect:set_movementType(UI.ScrollRect.MovementType.Elastic)
    end)
  end

  local onValueChanged = sv_rect:get_onValueChanged()
  view:removeAllListeners(onValueChanged)
  view:addListener(onValueChanged, function()
    self:MakeVertListWrapped(env)
  end)
end

function m:MakeVertListWrapped(env, firstMake)
  local view    = env.view
  local sv      = env.sv
  local goList  = sv.transform:find("List")
  local sv_rect = sv.scrollRect
  local sr_bar  = sv_rect:get_verticalScrollbar()
  self:check()
end

function m:check()
  self:judgeNeedOutHead()
  self:judgeNeedOutEnd()
  self:judgeNeedInEnd()
  self:judgeNeedInHead()
  if self.customScrollCheck then
    self.customScrollCheck(self.view, self)
  end
end






