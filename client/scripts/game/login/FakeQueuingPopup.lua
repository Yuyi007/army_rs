-- Fake queuing by designers

ModalView('FakeQueuingPopup', 'prefab/ui/server/server_queue_pop', function(self, loginView, queueRank, options)
  self.loginView = loginView
  self.queueRank = queueRank
end, QueuingPopup)

local m = FakeQueuingPopup

function m:init()
  self:updateQueueRank()
  m.super.init(self)
  self:update()
end

function m:exit()
  m.super.exit(self)
end

function m:initQueuingUpdate()
  self.onQueuingMesssage = self:schedule(function ()
    if math.random(1, 100) > 85 then
      self.queueRank = self.queueRank - math.random(1, 4)
      self:updateQueueRank()
    end
    if self.queueRank <= 0 then
      md:rpcGetOpenZones(md.account.id, function ()
        self:close()
        self:onDequeue()
      end)
    end
  end, 1)
end

function m:exitQueuingUpdate()
  if self.onQueuingMesssage then
    self:unschedule(self.onQueuingMesssage)
    self.onQueuingMesssage = nil
  end
end

function m:cancelQueuing()
  logd('FakeQueuingPopup: cancelQueuing...')
  md:rpcGetOpenZones(md.account.id, function ()
    self:close()
  end)
end

function m:updateQueueRank()
  if self.queueRank and self.queueRank < 0 then
    return
  end

  self.queueTime = math.ceil(self.queueRank * self:getTimeFactor())
  logd('FakeQueuingPopup: updateQueueRank rank=%d time=%d', self.queueRank, self.queueTime)
end
