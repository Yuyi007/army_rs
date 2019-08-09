-- messages.lua

class('MessageHandler', function (self)
end)

local m = MessageHandler
local unity = unity

m.lastHandleMessage = m.lastHandleMessage or nil
m.lastHandleConnected = m.lastHandleConnected or nil
m.lastHandleClosing = m.lastHandleClosing or nil
m.lastHandleClosed = m.lastHandleClosed or nil
m.lastHandleDestroy = m.lastHandleDestroy or nil

function m.init()
  -- logd("[message] msg init")
  local message = mp:signal('message')
  if not message:added(m.handleMessage) then
    -- logd("[message] reg handle message %s", tostring(m.handleMessage))
    message:add(m.handleMessage)
    m.lastHandleMessage = m.handleMessage
  end

  local message = mp:signal('post_message')
  if not message:added(m.handlePostMessage) then
    message:add(m.handlePostMessage)
    m.lastHandlePostMessage = m.handlePostMessage
  end

  local connected = mp:signal('connected')
  if not connected:added(m.handleConnected) then
    connected:add(m.handleConnected)
    m.lastHandleConnected = m.handleConnected
  end

  local closing = mp:signal('closing')
  if not closing:added(m.handleClosing) then
    closing:add(m.handleClosing)
    m.lastHandleClosing = m.handleClosing
  end

  local closed = mp:signal('closed')
  if not closed:added(m.handleClosed) then
    closed:add(m.handleClosed)
    m.lastHandleClosed = m.handleClosed
  end

  local error = mp:signal('error')
  if not error:added(m.handleClosed) then
    error:add(m.handleClosed)
    m.lastHandleClosed = m.handleClosed
  end

  local timeout = mp:signal('timeout')
  if not timeout:added(m.handleClosed) then
    timeout:add(m.handleClosed)
    m.lastHandleClosed = m.handleClosed
  end

  local destroy = mp:signal('destroy')
  if not destroy:added(m.handleDestroy) then
    destroy:add(m.handleDestroy)
    m.lastHandleDestroy = m.handleDestroy
  end

  if mp:isConnected() then
    m.startKeepAlive()
  end
end

function m.handleDestroy()
  m.stopKeepAlive()

  mp:signal('message'):remove(m.handleMessage)
  mp:signal('post_message'):remove(m.handlePostMessage)
  mp:signal('connected'):remove(m.handleConnected)
  mp:signal('closing'):remove(m.handleClosing)
  mp:signal('closed'):remove(m.handleClosed)
  mp:signal('error'):remove(m.handleClosed)
  mp:signal('timeout'):remove(m.handleClosed)
  mp:signal('destroy'):remove(m.handleDestroy)
end

function m.onClassReloaded(_clz)
  local mp = rawget(_G, 'mp')
  if not mp then return end

  if m.lastHandleMessage then mp:signal('message'):remove(m.lastHandleMessage) end
  if m.lastHandlePostMessage then mp:signal('post_message'):remove(m.lastHandlePostMessage) end
  if m.lastHandleConnected then mp:signal('connected'):remove(m.lastHandleConnected) end
  if m.lastHandleClosing then mp:signal('closing'):remove(m.lastHandleClosing) end
  if m.lastHandleClosed then mp:signal('closed'):remove(m.lastHandleClosed) end
  if m.lastHandleDestroy then mp:signal('destroy'):remove(m.lastHandleDestroy) end

  m.init()
end

function m.handleConnected()
  m.startKeepAlive()
end

function m.handleClosing()
  m.stopKeepAlive()
end

function m.handleClosed()
  m.stopKeepAlive()
end

function m.stopKeepAlive()
  logd('mp[%d]: stop keep alive', mp.id)
  if m.handleKeepAlive then
    scheduler.unschedule(m.handleKeepAlive)
    m.handleKeepAlive = nil
  end
end

function m.startKeepAlive()
  m.stopKeepAlive()

  logd('mp[%d]: start keep alive', mp.id)
  -- send keepalive (wechat value: 2 mins, we can be a lot easier)
  m.handleKeepAlive = scheduler.schedule(function ()
    logd('mp[%d]: keep alive', mp.id)
    md:rpcKeepAlive(function () end)
  end, 3 * 60)
end

-- handle messages here
function m.handleMessage(n, t, msg)
  unity.beginSample('handleMessage')
  -- logd("[message] msg n:%s t:%s msg:%s", tostring(n), tostring(t), inspect(msg))
  if type(msg) ~= 'table' then
    unity.endSample()
    return
  end
  
  if n == 0 then
    m.handleBroadcastMessage(t, msg)
    unity.endSample()
    return
  end

  ------------------------------------------------
  -- The following handles only return messages --
  ------------------------------------------------

  if msg.md_ver then
    -- logd('model version=%s', tostring(msg.md_ver))
    md.version = msg.md_ver
  end

  ServerTime.update(msg.server_time)
  if msg.success == false then
    if m.handleRequestErrors(msg) then
      loge('handleMessage early return because there are request errors')
      unity.endSample()
      return
    end
  end

  if (t > 153 and t ~= 1000) then
    unity.beginSample('preproc')
    md:signal('preproc'):fire(msg)
    unity.endSample()
  end

  unity.endSample()
end

function m.handlePostMessage(n, t, msg)
  unity.beginSample('handlePostMessage')

  unity.endSample()
end

function m.handleBroadcastMessage(t, msg)
  unity.beginSample('handleBroadcastMessage')
  if t == 1003 then
    if msg.multi_login then
      logd('handleBroadcastMessage: multi_login received')
      md:forgetLogin()
      m.handleRequestErrors({reason = 'multi_login'})
    elseif msg.gm_edit then
      m.handleGmEdit(msg)
    elseif msg.type then
      md:signal('new_mail'):fire(msg)
    end
  elseif t == 1005 then
    logd("combat_room_msg:%s", inspect(msg))
    md:signal('combat_room_msg'):fire(msg)
  elseif t == 1006 then
    if md:pid() ~= msg.pid then

      if msg.new_message_senders then
        md.new_message_senders = msg.new_message_senders
      end
      md:signal('chat'):fire(msg)
      if msg.chat_msg then
        --md:pushToPrivateMesssags(msg.pid, msg.chat_msg)
        --md:updatePrivateChatMessage(msg.chat_msg)
        local chatMessage = msg.chat_msg
        if chatMessage.pid ~= md:pid() and chatMessage.pid:match('^npc') == nil then
          local text = chatMessage.text
          if text == 'str_contacts_13' then
            text = loc(text, chatMessage.pname)
          end
          Util.pushPrivateChatChannel(chatMessage.pname, text)
        end
        md:signal("new_message"):fire(msg)
      else
        md:signal('new_message'):fire()
      end
      if msg.recent_contacts then
        md.recent_contacts = msg.recent_contacts
      end
      if msg.following_pids then
        md.following_pids = msg.following_pids
      end
    end
  elseif t == 1007 then
    if md:pid() ~= msg.pid then
      md:signal('follow'):fire(msg)
    end
  elseif t == 1008 then
    if md:pid() == msg.pid then
      md.mailCount = msg.size
      md.unReadMailNum = md.unReadMailNum + 1
      --to do notify mail received
    end
  elseif t == 1009 then
    -- 
    -- local list = string.split(msg.cid, "_", 1)
    -- local cid = list[1]
    local tag = msg.chat['tag']
    
    if tag == "TEAM" then
      -- local content = loc(msg.text, unpack(msg.args))
      md:signal('team_5X5'):fire(msg)
    elseif tag == "WORLD" then
      md:signal('channel_chat'):fire(msg)
    end
  elseif t == 1010 then 
      local content = loc(msg.text, unpack(msg.args))
      Util.pushSystemMessage(loc("str_ui_msg"), content, msg)
      --md:signal('system_notice_message'):fire(msg)  
  elseif t == 1011 then
    logd('channel queuing received %s', peek(msg))
    md:signal('channel_queuing'):fire(msg)
  elseif t == 1911 then
    logd('upload_log time=%s', tostring(os.date('%c', ServerTime.time())))
    logd('upload_log message received %s', peek(msg))
    logd('upload_log message.mode: %s', peek(msg.mode))
    DebugUtil.sendLogsToServer(msg)
  elseif t == 1012 then 
    md:signal('addteam'):fire(msg)
  elseif t == 1013 then
    logd("broadCast tems message %s", inspect(msg))
    md:signal('sync_team_msg'):fire(msg)
  elseif t == 1014 then
    local message = msg.chat
    md:signal('friend_chat'):fire(msg)
  elseif t == 1015 then
    md:signal('friend_request'):fire(msg)
  end

  unity.endSample()
end

local FATAL_ERROR_REASON_TEXTS = {
  handler_exception = 'server_error_exception',
  exception = 'server_error_exception',
  dead_process = 'server_error_unknown',
  no_process = 'server_error_unknown',
  handler_error = 'server_error_backend',
  no_data_server = 'server_error_backend',
  not_logged_in = 'server_error_not_logged_in',
  invalid_session = 'server_error_invalid_session',
  invalid_zone = 'server_error_unknown',
  multi_login = 'server_error_multi_login',
  no_such_room = 'server_error_no_such_room',
  join_room_exit = 'server_error_busy',
  server_invalidated = 'server_error_invalidated',
  server_busy = 'server_error_busy',
  timeout = 'server_error_timeout',
  verification_error = 'server_error_verification',
}

local NORMAL_ERROR_REASON_TEXTS = {
  -- maintainance = 'server_error_maintainance',
  gm_deny = 'server_error_gm_deny',
  zone_error = 'server_error_unknown',
  gate_error = 'server_error_unknown',
}

function m.handleRequestErrors(msg)
  local reason = msg.reason

  if reason == 'no_such_user' or
    reason == 'queue_rank' then
    -----------------------------------------------------------------
    -- these are not errors: do nothing
    --
  elseif reason == 'maintainance' then
    returnToLogin(function ()
      ui:push(MaintainanceNoticeView.new(msg))
    end)
  elseif FATAL_ERROR_REASON_TEXTS[reason] then
    -----------------------------------------------------------------
    -- these are fatal errors: force player to return to login screen
    local reasonText = loc(FATAL_ERROR_REASON_TEXTS[reason])
    returnToLogin(function ()
      FloatingTextFactory.makeFramed{text=reasonText}
    end)
    return true
  elseif NORMAL_ERROR_REASON_TEXTS[reason] then
    -----------------------------------------------------------------
    -- these are normal errors: show error reason, player can stay in scene
    local reasonText = loc(NORMAL_ERROR_REASON_TEXTS[reason])
    FloatingTextFactory.makeFramed{text=reasonText}
  else
    -----------------------------------------------------------------
    -- general handler verification fail: player can stay in scene
    if game.debug > 0 and game.mode == 'development' then 
 
      -- logd(">>>>>>>>reason111:%s",tostring(reason))
      -- in development, show fail reason to developers
      -- if reason ~= nil and string.len(reason) > 0 then
        FloatingTextFactory.makeFramed{text = 'str_'..tostring(reason), color = ColorUtil.red} --'[DEV ONLY]'..
      -- end
    else
      -- logd(">>>>>>>>reason222:%s",tostring(reason))
      -- local reasonText = loc(FATAL_ERROR_REASON_TEXTS['verification_error'])
      FloatingTextFactory.makeFramed{text = 'str_'..tostring(reason), color = ColorUtil.red}
    end
  end
end

function m.handleGmEdit(msg)
  logd('handleGmEdit: msg=%s', peek(msg))

  if game.mode == 'development' and game.debug > 0 then
    FloatingTextFactory.makeFramed{ text='Reloading game data...' }
    md:rpcGetGameData(function (msg)
      FloatingTextFactory.makeFramed{ text='Game data reloaded' }
    end)
  else
    -- reloading game data can cause glitches
    -- do not do it in production mode
  end
end


---------------------------------------------------------
--
-- MsgEndpoint batch messages
--
---------------------------------------------------------

-- override mp method to provide batch
function MsgEndpoint:onPacketWillBeSent(packet)
  local n = packet.number

  self:signal(n):clear()
  if type(packet.onComplete) == 'function' then
    -- logd('mp[%d]: signal added n=%d t=%d', self.id, n, packet.type)
    if packet.msg.batchNum then
      logd('mp[%d] batch signal added n=%d t=%d', self.id, n, packet.type)
      self:signal(n):add(packet.onComplete)
    else
      self:signal(n):addOnce(packet.onComplete)
    end
    packet.onComplete = nil
  end
end

-- override mp method to provide batch
function MsgEndpoint:onResponseMessageReceived(n, t, msg)
  -- logd('mp[%d]: response received: number=%d msg=%s', self.id, n, tostring(msg))
  -- logd("check mp process_list:"..tostring(msg.process_list))
  if msg.process_list then
    for i, v in ipairs(msg.process_list) do
      logd('mp[%d] batch response n=%d t=%d i=%d', self.id, n, t, i)
      self:addBatchQueue(n, t, v)
    end
  else
    self:signal(n):fire(msg, n, t)
    self:deleteSignal(n)
  end
end

function MsgEndpoint:addBatchQueue(n, t, msg)
  if not self.batchQueues[""..n] then
    self.batchQueues[""..n] = {{msg_type = t, msg_num = n, msg = msg}}
  else
    table.insert(self.batchQueues[""..n], {msg_type = t, msg_num = n, msg = msg})
  end
  if not self.queueHandler then
    self.queueHandler = scheduler.scheduleWithUpdate(function(deltaTime)
      self:checkBatchQueue()
    end, 0.5)
  end
end

-- each 0.5 second
function MsgEndpoint:checkBatchQueue()
  -- logd("check batch queue")
  local isQueueClear  = true
  for k,v in pairs(self.batchQueues) do
      local n = tonumber(k)
      local data = table.remove(v, 1)
      if data then
        -- logd("check data:"..tostring(k)..","..tostring(data.msg_type))
        self:signal(n):fire(data.msg, n, data.msg_type)
      end
      if #v > 0 then
        isQueueClear = false
      else
        self:signal(n):clear()
        self:deleteSignal(n)
        self.batchQueues[k] = nil
      end
  end

  if isQueueClear then
    logd("clear queue data")
    scheduler.unschedule(self.queueHandler)
    self.queueHandler = nil
  end
end

