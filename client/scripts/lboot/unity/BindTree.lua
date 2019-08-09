
-- this is not used currently because
-- it does not bring too much perf boost than BundlePathCacher,
-- and needs to add subtree definition on every class with subviews
--
-- it uses less lua memory (1MB less at the login view after preload)
-- than BundlePathCacher, since it creates less view nodes

class('BindTree', function (self)
end)

local m = BindTree
local unity = unity

m.debug = nil

function m.initTree(treeDef, bindTree)
  bindTree['main'] = m.makeLeaf()

  for k, v in pairs(treeDef) do
    if v == true then
      bindTree[k] = m.makeLeaf()
    else
      bindTree[k] = {}
      m.initTree(v, bindTree[k])
    end
  end
end

function m.makeLeaf()
  return {'leaf', {}, {}}
end

function m.isLeaf(node)
  if node and #node == 3 and node[1] == 'leaf' then
    return true
  end
  return false
end

function m.findLeaf(bindTree, path)
  if not path then return bindTree['main'] end

  local leaf = bindTree
  for i = 1, #path do
    local v = leaf[path[i]]
    if v then
      leaf = v
      if i == #path then
        if m.isLeaf(leaf) then
          return leaf
        else
          return leaf['main']
        end
      end
    else
      return leaf['main']
    end
  end
end

function m.findBranch(bindTree, path)
  local node = bindTree
  for i = 1, #path do
    local v = node[path[i]]
    if v then
      node = v
      if i == #path then
        if m.isLeaf(node) then
          return node
        else
          return node['main']
        end
      end
    end
  end
end

-- get a tree of bindable nodes and paths from a subview tree definition
function m.populateTree(root, cls, view)
  unity.beginSample('BindTree.populateTree')

  local treeDef = cls.__subviews or {}
  local bindTree = {}
  local pathCache = {}
  local prefixCache = {}
  local rootId = root:GetInstanceID()
  local rootGo = root:get_gameObject()
  local comps = rootGo:GetComponentsInChildren(UnityEngine.Transform, true)
  local uoc = uoc

  m.initTree(treeDef, bindTree)

  if m.debug then
    logd('populateTree: cls=%s treeDef=%s', cls.classname, peek(treeDef))
    logd('populateTree: cls=%s init bindTree=%s', cls.classname, peek(bindTree))
  end

  for i = 1, #comps do
    local comp = comps[i]
    local name = comp:get_name()
    local varname, k = string.gsub(name, '^b_', '')

    if k == 1 and comp:GetInstanceID() ~= rootId then
      local prefix, path
      local parent = comp:get_parent()
      while parent do
        if prefixCache[parent] then
          if not prefix then
            prefix = prefixCache[parent]
          end
        else
          local p = pathCache[parent]
          if p and not path then
            path = {}
            for i = 1, #p do path[i] = p[i] end
            path[#path + 1] = varname
          end
        end
        if prefix and path then break end
        parent = parent:get_parent()
      end
      path = path or {varname}
      pathCache[comp] = path

      local parentNode = m.findLeaf(bindTree, prefix)
      if m.debug then
        logd('populateTree: cls=%s root=%s name=%s prefix=%s path=%s parentNode=%s',
          tostring(cls.classname), tostring(rootGo), name, peek(prefix), peek(path),
          (parentNode and peek(parentNode[3]) or 'nil'))
      end
      local bindableNodes = parentNode[2]
      local paths = parentNode[3]
      local go = comp:get_gameObject()
      bindableNodes[#bindableNodes + 1] = go
      paths[#paths + 1] = path

      local fullpath
      if not prefix then
        fullpath = path
      else
        fullpath = {}
        for i = 1, #prefix do fullpath[i] = prefix[i] end
        fullpath[#fullpath + 1] = varname
      end

      local thisNode = m.findBranch(bindTree, fullpath)
      if thisNode then
        local customCache = uoc:getCustomAttrCache(go)
        if m.debug then
          logd('populateTree: cache to go=%s id=%s varname=%s fullpath=%s thisNode=%s',
            tostring(go), go:GetInstanceID(), varname, peek(fullpath), peek(thisNode))
          assert(customCache.leafNode == nil, string.format('go=%s already have bindTree!', tostring(go)))
        end
        customCache.leafNode = thisNode
        prefixCache[comp] = fullpath
      end
    end
  end

  local customCache = uoc:getCustomAttrCache(rootGo)
  if m.debug then
    logd('populateTree: cache to rootGo=%s id=%s leafNode=%s',
        tostring(rootGo), rootGo:GetInstanceID(), peek(bindTree['main']))
    assert(customCache.leafNode == nil, string.format('rootGo=%s already have bindTree!', tostring(rootGo)))
  end
  customCache.leafNode = bindTree['main']

  -- maintain a reference because custom cache is weakly referenced
  view.bindTree = bindTree

  unity.endSample()
end

-- get all sub bindable nodes of a gameObject
function m.getBindableNodes(go, cls, view)
  unity.beginSample('BindTree.getBindableNodes')

  local customCache = uoc:getCustomAttrCache(go)
  if not customCache.leafNode then
    -- if m.debug then
    --   logd('getBindableNodes: need to populateTree go=%s id=%s cls=%s', tostring(go), go:GetInstanceID(), cls.classname)
    -- end

    m.populateTree(go, cls, view)

    if m.debug then
      assert(customCache.leafNode, 'leafNode must not be nil after populateTree!')
    end
  end

  local _tag, bindableNodes, paths = unpack(customCache.leafNode)
  local pathStrs = {}
  for i = 1, #paths do
    pathStrs[i] = table.concat(paths[i], '_')
  end

  if m.debug then
    logd('getBindableNodes: go=%s cls=%s pathStrs=%s', tostring(go), cls.classname, peek(pathStrs))
    logd('getBindableNodes: go=%s cls=%s trace=%s', tostring(go), cls.classname, debug.traceback())
  end

  unity.endSample()
  return bindableNodes, pathStrs
end

-- prevent bind the same gameObject multiple times
function m.ensureUniqueNode(go, varname, view)
  local customCache = uoc:getCustomAttrCache(go)
  local node = customCache.luaNode
  if node then
    loge('ensureUniqueNode: use __subviews to avoid multiple bind! prev=%s name=%s view=%s varname=%s go=%s',
      tostring(node), node.varname, view.class.classname, varname, tostring(go))
  end

  -- if m.debug then
  --   logd('ensureUniqueNode: bind go=%s varname=%s view=%s', tostring(go), varname, view.class.classname)
  -- end

  node = ViewNode.new(go, varname, view)
  customCache.luaNode = node
  return node
end
