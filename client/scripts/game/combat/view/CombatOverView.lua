View("CombatOverView", "prefab/ui/room/game_over_ui", function(self, winidentity, myIdentity)
  self.winIdent = winidentity
  self.myOdent = myIdentity
end)

local m = CombatOverView

function m:init()
	sm:muteMusic(true)
  
	logd(">>>>curIdent:%s",tostring(self.winIdent))
	if self.winIdent == 0 then
    self.display:setSprite('nongming_win')
	else
    self.display:setSprite('dizhu_win')
	end

	if self.winIdent == self.myOdent then
		sm:playSound('Sound/win')
  else
  	sm:playSound('Sound/lose')
  end	

end



function m:exit()
	
end

function m:onBtnContinue()
	cc:exit()
	ui:pop()
	ui:goto(MainSceneView.new())
end
