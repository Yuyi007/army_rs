ModalView('BusyView', 'prefab/ui/common/loading_busy', function(self)
  self.backGroundColor = Color.new(0, 0, 0, 0)
  self.uiMask = ui:cullingMask('all')
end)

local m = BusyView

function m:init()
  -- self.app = GameObject.Find('/LBootApp')
  self.__initParent = 'none'
  self:reopenInit()
end

function m:reopenInit()
end

function m:reopenExit()
end

function m:exit()


end

function m:show()
  -- logd('processAfterComplete loading_busy show %s', debug.traceback())
  self.shown = true
  -- self.gameObject:setParent(self.app)
  -- self.gameObject:setVisible(true)
  -- self:setVisible(true)
end

function m:hide()
  self.shown = false
  -- logd('processAfterComplete loading_busy hide %s', debug.traceback())
  -- self:setVisible(false)
  -- self.gameObject:setVisible(false)
  self:destroy()
end
