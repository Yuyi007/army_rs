require 'game/lib/bt/bt'
require 'game/common/ai/AIDebug'
require 'game/common/ai/AIMonitor'
require 'game/common/ai/AIPriority'
require 'game/common/ai/AISequence'
require 'game/common/ai/AIRandomSelector'
require 'game/common/ai/AIWeightSelector'
require 'game/common/ai/AITaskNode'
require 'game/common/ai/AIParallel'
require 'game/common/ai/AIConditionSelector'
require 'game/common/ai/AILoop'
require 'game/common/ai/AILogic'
require 'game/common/ai/AIInverter'
require 'game/common/ai/AIReturnFail'
require 'game/common/ai/AIReturnSuccess'
require 'game/common/ai/AIUntilFail'
require 'game/common/ai/AIUntilSuccess'
require 'game/common/ai/AISubTreeNode'
require 'game/common/ai/AIRandomSequence'
require 'game/common/ai/AILoopUntil'
require 'game/common/ai/AIPersistWhile'
require 'game/common/ai/AICountLimit'
require 'game/common/ai/AIReturnRunning'
require 'game/common/ai/NodeDecorator'

declare('BTF', {})
BTF.clses = {
  priority          = AIPriority,
  sequence          = AISequence,
  parallel          = AIParallel,
  randomselector    = AIRandomSelector,
  weightselector    = AIWeightSelector,
  conditionselector = AIConditionSelector,
  loop              = AILoop,
  logic             = AILogic,
  monitor           = AIMonitor,
  task              = AITaskNode,
  inverter          = AIInverter,
  retfail           = AIReturnFail,
  retsuccess        = AIReturnSuccess,
  utlfail           = AIUntilFail,
  utlsuccess        = AIUntilSuccess,
  subtree           = AISubTreeNode,
  randomsequence    = AIRandomSequence,
  loopuntil         = AILoopUntil,
  persistwhile      = AIPersistWhile,
  countlimit        = AICountLimit,
  retrunning        = AIReturnRunning,
}

BTF.alias = {
  priority          = "优先",
  sequence          = "顺序",
  parallel          = "并行",
  randomselector    = "随机",
  weightselector    = "权重",
  conditionselector = "条件",
  loop              = "循环",
  logic             = "逻辑",
  monitor           = "监控",
  task              = "任务",
  inverter          = "取反",
  retfail           = "失败",
  retsuccess        = "成功",
  utlfail           = "等失败",
  utlsuccess        = "等成功",
  subtree           = "子树",
  randomsequence    = "随机序列",
  loopuntil         = "循环直到",
  persistwhile      = "持续时间",
  countlimit        = "持续次数",
  retrunning        = "运行中",
}


BTF.gen = function(cfg)
  local t = BT:new()
  t.tree = BTF.create(cfg)

  return t
end

BTF.create = function(cfg)
  local t = cfg['kind']
  local cls = BTF.clses[t]
  --logd(">>>>>>t:"..tostring(t))
  if cls then
    local node = cls.new()
    --logd(">>>>type(node.init):"..type(node.init))
    if node.init and type(node.init) == "function" then
      node:init(cfg)
    end

    if cfg['nodes'] then
      BTF.createChildren(node, cfg)
    end

    if cfg['node'] then
      BTF.createChild(node, cfg)
    end

    if cfg['subtree'] then
      BTF.createSubTree(node, cfg)
    end

    if cfg['weight'] then
      node['weight'] = cfg['weight']
    end

    if aidbg.debug then
      node.nodeName = BTF.alias[t]
    end

    return node
  end
  return nil
end

BTF.createChildren = function(node, cfg)
  node.nodes = {}
  local children = cfg["nodes"]
  for i=1,#children do
    local ccfg = children[i]
    if ccfg then
      local n = BTF.create(ccfg)
      if n then
        node.nodes[i] = n
      end
    end
  end
end

BTF.createChild = function(node, cfg)
  local ccfg = cfg["node"]
  if ccfg then
    local n = BTF.create(ccfg)
    if n then
      node.node = n
    end
  end
end

BTF.createSubTree = function(node, cfgArg)
  local scfg = cfgArg["subtree"]
  if scfg then
    local aiCfg = cfg:loadAIConfig(scfg)
    if aiCfg then
      local n = BTF.create(aiCfg)
      node.node = n
      node.subTreeFile = scfg
    end
  end
end






