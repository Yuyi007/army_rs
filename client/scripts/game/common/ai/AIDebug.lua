declare("aidbg", {})

local m = aidbg

m.debug_log = false
m.debug = false
m.INFO = 0
m.DEBUG = 1
m.WARNING = 2
m.ERROR = 3
m.loglevel = m.INFO

m.log = function (level, ...)
  if m.debug then
    level =  level or m.INFO
    if level >= m.loglevel then
      if m.debug_log then
        if not game.editor() then
          m.log2scr(...)
        else
          logd(...)
        end
      end
    end
  end
end

m.scrLabel = nil
m.logRecords = {}
m.log2scr = function(...)
  if not m.scrLabel then
    return
  end

  local tbl = {...}
  for i, v in pairs(tbl) do
    table.insert(m.logRecords, inspect(v))
    if #m.logRecords > 40 then
      table.remove(m.logRecords, 1)
    end
  end

  local strLogs = table.concat(m.logRecords, "\n")
  m.scrLabel.text = strLogs
end

m.setLogLevel = function(level)
  m.loglevel = level
end

m.levelCounts = {}
m.proclst = {}
m.genDbgInfo = function(bt)
  m.proclst = {nodes = {bt.tree}, levelInc = 1}
  m._genInfo()
end

m._genInfo = function()
  local lst = {nodes = {}, levelInc = m.proclst.levelInc + 1}
  local count = #m.proclst.nodes
  --logd(">>>"..m.proclst.levelInc.." : "..count)
  m.levelCounts[m.proclst.levelInc] = count
  for i=1, count do
    local n = m.proclst.nodes[i]
    --logd(">>>level:"..m.proclst.levelInc.." name:"..n.nodeName.." nodes:"..#n.nodes)
    n.level = m.proclst.levelInc
    n.index = i

    if n.nodes then
      for j = 1, #n.nodes do
        table.insert(lst.nodes, n.nodes[j])
      end
    elseif n.node then
      table.insert(lst.nodes, n.node)
    end
  end
  m.proclst = lst
  if #lst.nodes > 0 then
    m._genInfo()
  end
end

m.clear = function(bt, container)
  local count = container.transform.childCount
  for i=1, count do
    local c = container.transform:GetChild(i-1)
    if c.gameObject.name ~= "text" and c.gameObject.name ~= "line" then
      unity.destroy(c.gameObject)
    end
  end

  m.clearDbgGO(bt.tree)
end

m.clearDbgGO = function(node)
  if node.dbgInfo then
    node.dbgInfo = nil
  end

  if node.nodes then
    for k,v in pairs(node.nodes) do
       m.clearDbgGO(v)
    end
  elseif node.node then
    m.clearDbgGO(node.node)
  end
end


m.resetAllLineColor = function(node)
  m.changeLineColor(node, false)

  if node.nodes then
    for k,v in pairs(node.nodes) do
       m.resetAllLineColor(v)
    end
  elseif node.node then
    m.resetAllLineColor(node.node)
  end
end


m.changeLineColor = function(node, running)
  if not node.dbgInfo then
    return
  end

  if node.isBranch and node.actualTask then
    local txtNode = node.dbgInfo.txtNode
    local txtMesh = txtNode.transform:getComponent(UnityEngine.TextMesh)
    local txt = node.nodeName
    if node.agent_method then
      txt = tostring(AIAgent.mnhs[node.agent_method])
    end
    txtMesh.text = txt .. tostring(node.actualTask)
  end
  m._changeLineColor(node, node.dbgInfo.lineNode, running)
end

m._changeLineColor = function(node, lineNode, running)
  if not lineNode then
    return
  end

  local r = lineNode:GetComponent(unity.LineRenderer)
  local color = Color(1, 0, 0, 1)
  if running then
    color = Color(0, 1, 0, 1)
  end
  r:SetColors(color, color)
end

m.render = function(container, n, parentNode)
  local txtOri = container.transform:find("text")
  local txtNode = GameObject.Instantiate(txtOri.gameObject)
  local txtMesh = txtNode.transform:getComponent(UnityEngine.TextMesh)
  local txt = n.nodeName
  if n.agent_method then
    txt = tostring(AIAgent.mnhs[n.agent_method])
  end

  txtMesh.text = txt--..tostring(n.uid)--n.nodeName
  --logd(">>>>txtMesh.text:"..txtMesh.text.." uid:"..tostring(n.uid))
  local uy = 2.5
  local ux = 10
  local startX = -65
  local x = n.level * ux + startX
  local counts = m.levelCounts[n.level]
  local rgn = counts * uy
  local begin = rgn/2
  local y = begin - (n.index-1) * uy
  local z = 0

  --logd(">>x:"..x.." y:"..y.." z:"..z)

  txtNode.transform:setParent(container.transform, false)
  txtNode.transform.localPosition = Vector3(x, y, z)

  local lineNode = nil
  if parentNode then
    local offsetX = 0
    local offsetY = -1

    local tp = parentNode.dbgInfo.txtNode
    local pp = tp.transform.localPosition

    local lineOri = container.transform:find("line")

    lineNode =  GameObject.Instantiate(lineOri.gameObject)
    lineNode.transform:setParent(container.transform, false)
    local lineRender = lineNode:getComponent(unity.LineRenderer)

    lineRender:SetPosition(0, Vector3(pp[1] + offsetX, pp[2] + offsetY, 0.5))
    lineRender:SetPosition(1, Vector3(x + offsetX, y + offsetY, 0.5))
  end

  n.dbgInfo = {txtNode = txtNode, lineNode = lineNode}

  if n.nodes then
    --logd("...nodes")
    for k,v in pairs(n.nodes) do
      m.render(container, v, n)
    end
  elseif n.node then
    --logd("...node")
    m.render(container, n.node, n)
  end

end

m.logPath = function(node)
  m.strPath = ''
  m._logPath(node)
  logd("[ai path] %s", tostring(m.strPath))
end

m._logPath = function(node)
  m.strPath = m.strPath .. " >> " .. node.classname
  if node.classname == 'AISubTreeNode' then
    m.strPath = m.strPath .. "[".. node.subTreeFile .."]"
  end
  if node.control then
    m._logPath(node.control)
  end
end