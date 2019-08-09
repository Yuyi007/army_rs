ViewScene('MainSceneView', 'scenes/game/test', function(self)
end)

local m = MainSceneView
-- local ActionRecord = Game.ActionRecord

function m:initSceneNode()
  local function func(taskNode)
    self:__goto()
    
    sm:playMusic("Sound/main_bgm")
    sm:mute(false)

    taskNode:finish()
  end
  return LoadRoutineNode.new({name="initScene", func = func})
 end

function m:getLoadTree()
	self.__preloaded  = true
	local loadAsset   = LoadingHelper.makeMainSceneTree(self)
	local sceneNode = self:initSceneNode() 
	return LoadBranchNode.new {name = "root", parallel_count = 1, nodes = {loadAsset, sceneNode}}
end

function m:init()
   -- logd(">>>>>>initUI")
  -- self:initCC()
  self:initUI()

end



function m:initCC()
  cc = CombatController.new(nil)
  cc:init()
end


function m:initUI()
	local view = ViewFactory.make('MainRoomView')
  -- self.gameView = CharacterView.new(nil)
  -- local view = CombatOverView.new(1,1)
	ui:setBaseView(view)
end