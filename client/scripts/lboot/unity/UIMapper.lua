class('UIMapper')

local m = UIMapper
local unity = unity
local WEAK_VAL = {__mode='v'}
local WEAK_KEY = {__mode='k'}
local EMPTY = {}

if not rawget(_G, 'UIMapperData') then
  logd('init UIMapperData')
  rawset(_G, 'UIMapperData', {
    buttonCaches = setmetatable({}, WEAK_KEY),
    viewNodeCompCache = setmetatable({}, WEAK_KEY),
    viewNodesCache = setmetatable({}, WEAK_KEY),
  })
end

m.buttonCaches = UIMapperData.buttonCaches or setmetatable({}, WEAK_KEY)
m.viewNodeCompCache = UIMapperData.viewNodeCompCache or setmetatable({}, WEAK_KEY)
m.viewNodesCache = UIMapperData.viewNodesCache or setmetatable({}, WEAK_KEY)

function m.clear()
  if m.buttonCaches then
    for k, v in pairs(m.buttonCaches) do
      for k1, v1 in pairs(v) do
        if type(v1) == 'table' then
          table.clear(v1.nodes)
          table.clear(v1.paths)
          table.clear(v1)
        end
      end

      table.clear(v)
    end

    table.clear(m.buttonCaches)
  end

  if m.viewNodeCompCache then
    table.clear(m.viewNodeCompCache)
  end

  if m.viewNodesCache then
    for k, v in pairs(m.viewNodesCache) do
      table.clear(v)
      m.viewNodesCache[k] = nil
    end
  end
end

function m.getInitBindingNodes(bundleFile, refRoot, rootGo, view)
  local classData = m.buttonCaches[rootGo]
  if not classData then
    classData = {}
    m.buttonCaches[rootGo] = classData
  end

  -- different class might map to the same prefab
  -- their initial bindings are different
  -- like ApplyJobSuccessView and ApplyJobFailView
  local classname = view.class.classname
  local buttonsData = classData[classname]

  if buttonsData then
    return buttonsData.nodes, buttonsData.paths
  end

  local buttonsData = {nodes = {}, paths = {}}

  local nodes = buttonsData.nodes
  local paths = buttonsData.paths

  local uimapper = cfg.uimapper[bundleFile:lower()] or EMPTY
  local rootmapper = uimapper[refRoot] or EMPTY

  local buttons = rootmapper['__buttons__'] or EMPTY
  for varbutton, varcallback in pairs(buttons) do
    local btnCallback = false
    if type(varcallback) == 'string' then
      btnCallback = rawget(view, varcallback) or view.class[varcallback]
    else
      btnCallback = true
    end

    if btnCallback then
      local varpath = rootmapper[varbutton]
      local node = rootGo:find(varpath)
      if node then
        local index = #nodes + 1
        nodes[index] = node
        paths[index] = varbutton
      end
    end
  end

  classData[classname] = buttonsData

  return nodes, paths
end

function m.markBinded(comp)
  m.viewNodeCompCache[comp] = true
end

function m.hasBinded(comp)
  return not not m.viewNodeCompCache[comp]
end

function m.bindViewNode(view, nodeGo, varname)
  local rootGo = view.gameObject
  local cache = m.viewNodesCache[rootGo]
  if not cache then
    cache = {}
    m.viewNodesCache[rootGo] = cache
  end

  local viewNode = cache[varname]

  -- if the viewnode doesnt exist or viewNode exists but is used by another view
  -- create a new viewNode
  if not viewNode or (viewNode.view and viewNode.view ~= view) then
    viewNode = ViewNode.new(nodeGo, varname, view)
    cache[varname] = viewNode
  elseif viewNode.view == nil then
    viewNode:reopenInit(nodeGo, varname, view)
  end

  view._nodes[varname] = viewNode
  view[varname] = viewNode

  return viewNode
end


