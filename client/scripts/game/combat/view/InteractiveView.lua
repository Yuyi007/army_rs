View("InteractiveView", "prefab/ui/room/interactive_ui", function(self)
	-- self:initButtons()
	self.animType = "level2"
end)

local m = InteractiveView
local btns = { "Deal", "DisGrab", "Play", "Pass" }

function m:init()
	self:initBtn()
end

function m:exit()
	-- body
end

-- function m:initButtons()
-- 	for i = 1,#btns do
-- 		local btn = btns[i]
-- 		self["onBtn"..btn] = function(v)
-- 			self:updateButton(btn)
-- 		end
-- 	end	
-- end

function m:initBtn()
	self.btnDeal:setVisible(true)
	self.btnGrab:setVisible(false)
	self.btnDisGrab:setVisible(false)
	self.btnPlay:setVisible(false)
	self.btnPass:setVisible(false)
end

function m:hideBtn()
	self.btnDeal:setVisible(false)
	self.btnGrab:setVisible(false)
	self.btnDisGrab:setVisible(false)
	self.btnPlay:setVisible(false)
	self.btnPass:setVisible(false)
end


-- function m:updateButton(btn)
	
-- end

--显示抢地主
function m:showGrabAndDisGrab()
	self.btnDeal:setVisible(false)
	self.btnGrab:setVisible(true)
	self.btnDisGrab:setVisible(true)
	self.btnPlay:setVisible(false)
	self.btnPass:setVisible(false)
end

--显示出牌按钮
function m:showDealAndPass()
	self.btnDeal:setVisible(false)
	self.btnGrab:setVisible(false)
	self.btnDisGrab:setVisible(false)
	self.btnPlay:setVisible(true)
	self.btnPass:setVisible(true)
end

function m:showDeal()
	self.btnDeal:setVisible(true)
	self.btnGrab:setVisible(false)
	self.btnDisGrab:setVisible(false)
	self.btnPlay:setVisible(false)
	self.btnPass:setVisible(false)
end

--开始发牌
function m:onBtnDeal()
	cc:deal()
	ui:pop()
end

--抢地主
function m:onBtnGrab()
	cc:addDZIndex()
	ui:pop()
end

--不抢地主
function m:onBtnDisGrab()
	cc:loseDZ()
	ui:pop()
end

--出牌
function m:onBtnPlay()
  cc:canPlay()
end

--过/不出
function m:onBtnPass()
	cc:playPass(cc.playerCtrl)
	ui:pop()
end


