-- MsgEndpointView.lua

--[[
  View related part of the MsgEndpoint class
  This is to be overriden by game-specific implementations
  Please override this class in your game folder, not here
]]--

-- init this module
function MsgEndpoint:initView()
end

-- destroy this module
function MsgEndpoint:destroyView()
end

--------------------------------------------------------
-- display a view to indicate the game is in busy status (where no message should be sent)
function MsgEndpoint:showBusy()
  loge('override me: showBusy')
end

-- hide game busy view
function MsgEndpoint:hideBusy()
  loge('override me: hideBusy')
end

-- check if busy view is shown at the moment
function MsgEndpoint:isBusyShown()
  loge('override me: isBusyShown')
end

--------------------------------------------------------------------------
-- display a view for user to confirm to reconnect, or reconnect directly
function MsgEndpoint:showConfirmReconnect(onOk, onCancel)
  loge('override me: showConfirmReconnect')
end

-- hide game reconnect confirm view
function MsgEndpoint:hideConfirmReconnect()
  loge('override me: hideConfirmReconnect')
end

-- check if reconnect confirm view is shown at the moment
function MsgEndpoint:isConfirmReconnectShown()
  loge('override me: isConfirmReconnectShown')
end

--------------------------------------------------------
-- display a view to indicate the game is reconnecting
function MsgEndpoint:showReconnecting()
  logd('mp[%d]: game is now reconnecting', self.id)
end

-- hide game reconnecting view
function MsgEndpoint:hideReconnecting()
end

-- check if reconnect view is shown at the moment
function MsgEndpoint:isReconnectingShown()
end

--------------------------------------------------------
-- display a hint about network status, e.g. a Floating text
function MsgEndpoint:showHint(text)
end
