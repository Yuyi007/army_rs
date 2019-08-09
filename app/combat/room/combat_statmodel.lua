
local total_data = {}
class("CombatStatModel", function(self, room)
  self.initialized = false
  self.room = room

  self.framedata = {}
  self.framebegintick = {}
  self.framepcnt = {}

  self.playerdata = {}
  self.offline_players = {}
  total_data = {}
  self.playercnt = 0

  self.staResolve = nil

  self.stalst = {}
  self.cntlst = {}

  self.cultObj = CombatStatItem.new(self.room)
end)

local m = CombatStatModel

function m:init()
  if self.initialized then return end
  -- print "room stat init"

  local members = self.room:members()
  self.playercnt = 0
  for ind, side in pairs(members) do 
    for _, seat in pairs(side) do 
      if seat ~= -1 then
        self.playercnt = self.playercnt + 1

        --local sdata = CombatStatItem.new(self.room)

        self.playerdata[seat.pid] = {}

        self.playerdata[seat.pid].side0 = {}
        self.playerdata[seat.pid].side0.mvp = ""
        self.playerdata[seat.pid].side0.pstats = {}

        self.playerdata[seat.pid].side1 = {}
        self.playerdata[seat.pid].side1.mvp = ""
        self.playerdata[seat.pid].side1.pstats = {}

        self.playerdata[seat.pid].totaldata = {}
        self.playerdata[seat.pid].totaldata.token = ""  
        self.playerdata[seat.pid].totaldata.mtype = -1
        self.playerdata[seat.pid].totaldata.ctype = -1
        self.playerdata[seat.pid].totaldata.winner = -1
        self.playerdata[seat.pid].totaldata.duration = 0
        self.playerdata[seat.pid].totaldata.begintime = 0
        self.playerdata[seat.pid].totaldata.enter_type = 0
      end
    end
  end

  for ind, side in pairs(members) do 
    for _, seat in pairs(side) do 
      if seat ~= -1 then
        for k,v in pairs(self.playerdata) do
          self.cultObj:init_players(self.playerdata, k, ind-1, seat)
        end
      end
    end
  end

  -- print ("init playerdata", inspect(self.playerdata))

  self.hCheckFrameData = Scheduler.schedule(500, function()
    local dellst = {}

    for k,v in pairs(self.framebegintick) do
      if skynet.now() - v >= 500 then
        table.insert(dellst, k)
        -- print ("timeout frame", k,v, inspect(self.framedata[k]))


        for m,n in pairs(self.playerdata) do
          if self.framedata[k][m] == nil then
            self:killoff_cheatplayer(m)
            print("killoff_cheatplayer", m)
          end
        end

        for p,detail in pairs(self.framedata[k]) do
          if self.playerdata[p] then
            self.cultObj:set_playerdata(self.playerdata, p, detail) 
          end
        end
      end
    end

    for _,v in pairs(dellst) do
      self.framedata[v] = nil
      self.framebegintick[v] = nil
    end
  end)


  --print("initplayers", inspect(self.playerdata))
  
  self.initialized = true
end

function m:re_enter(pid, player)
  if self.playerdata[pid] == nil and self.offline_players[pid] then
    self.playerdata[pid] = self.offline_players[pid] 

    self.playercnt = self.playercnt + 1
    self.offline_players[pid]  = nil
  end
end

function m:player_offline(pid)
  if self.playerdata[pid] then
    self.offline_players[pid] = self.playerdata[pid]

    self.playerdata[pid] = nil
    total_data[pid] = nil
    self.playercnt = self.playercnt - 1
  end
end 

function m:compare_stat(stat1, stat2)
  -- print("2compare_stat", inspect(stat1), inspect(stat2))
  for k,v in pairs(stat1) do
    if stat2[k] == nil then return false end

    if type(v) == "table" then
      if type(stat2[k]) ~= "table" then return false end

      -- print("2compare table", inspect(stat1[k]), inspect(stat2[k]))
      for m,n in pairs(v) do
        if stat2[k][m] ~= stat1[k][m] then  return false end
      end
    else
      if stat2[k] ~= stat1[k] then return false end
    end
  end

  return true
end

function m:compare_frameData(stat1, stat2)
  -- print("compare_stat", inspect(stat1), inspect(stat2))
  for k,v in pairs(stat1) do
    if stat2[k] == nil then return false end

    -- print("compare table", inspect(stat1[k]), inspect(stat2[k]))
    for m,n in pairs(v) do
      if stat2[k][m] ~= stat1[k][m] then  return false end
    end
  end

  print("compare_frameData ok")
  return true
end

function m:resolve_combatstat()
  if staResolve == nil then 
    self.stalst = {}
    self.cntlst = {}

    print("cur total_data", inspect(total_data))

    for k,v in pairs(self.playerdata) do
      print("get stat", self.playerdata, k, inspect(self.playerdata[k]))
      local csd = self.cultObj:getCombatStat(self.playerdata, k, self.room, total_data)
      self.stalst[k] = csd

      staResolve = csd
    end

    local cnt = 1
    local pcnt = 0
    local max_cnt = 0
    local min_cnt = 100
    for k,v in pairs(self.stalst) do
      pcnt = pcnt + 1
      cnt = 1

      for m,n in pairs(self.stalst) do
        if k ~= m then
          if self:compare_stat(v, n) then
            cnt = cnt + 1
          end
        end
      end

      self.cntlst[k] = cnt

      if cnt > max_cnt then max_cnt = cnt end
      if cnt < min_cnt then min_cnt = cnt end
    end

    for k,v in pairs(self.cntlst) do
      if v < max_cnt then -- kick off cheat player
        
      else
        staResolve = self.stalst[k]
      end
    end
  end

  -- print("combat stat list", inspect(self.stalst))
  -- print("ok stat list", inspect(staResolve))

  return staResolve
end

function m:modify_playerdata(pid, data)
  --print ("modify_playerdata, playerdata", pid, inspect(data), inspect(self.playerdata))
  if self.playerdata[pid] then 
    --self.cultObj:set_playerdata(self.playerdata, pid, data.detail) 
    --if true then return end

    if self.framedata[data.frame] == nil then
      self.framedata[data.frame] = {}
      self.framebegintick[data.frame] = skynet.now()
      if self.framepcnt[data.frame] == nil then
        self.framepcnt[data.frame] = 0
      end      
    end
    self.framepcnt[data.frame] = self.framepcnt[data.frame] + 1

    self.framedata[data.frame][pid] = data.detail

    -- print("player cnt", self.framepcnt[data.frame], self.playercnt)
    if self.framepcnt[data.frame] == self.playercnt then
      local cnt = 1
      local pcnt = 0
      local max_cnt = 0
      local min_cnt = 100
      local frmcntLst = {}

      for k,v in pairs(self.framedata[data.frame]) do
        pcnt = pcnt + 1
        cnt = 1

        for m,n in pairs(self.framedata[data.frame]) do
          if k ~= m then
            if self:compare_frameData(v, n) then
              cnt = cnt + 1
            end
          end
        end

        frmcntLst[k] = cnt

        if cnt > max_cnt then max_cnt = cnt end
        if cnt < min_cnt then min_cnt = cnt end
      end

      for k,v in pairs(frmcntLst) do
        if v < max_cnt then -- kick off cheat player
          self:killoff_cheatplayer(k)
          print("kick off ",k)
        else
          self.cultObj:set_playerdata(self.playerdata, k, data.detail) 
          -- print("set playerdata", k, inspect(data.detail))
        end
      end

      self.framedata[data.frame] = nil
      self.framebegintick[data.frame] = nil
      self.framepcnt[data.frame] = nil
    end
  end
end

function m:modify_totaldata(pid, action)
  -- print("modify_totaldata", pid)

  total_data[pid] = {}
  total_data[pid] = action
  
  --print ("modify_totaldata, playerdata", pid, inspect(data), inspect(self.playerdata))
  if self.playerdata[pid] then 
    -- print("write_totaldata", pid, inspect(action.data.detail))
    self.cultObj:set_totaldata(self.playerdata, pid, action.data.detail) 
  end

  -- print("curdata", inspect(self.playerdata), inspect(total_data))

  local acnt = 0
  for k,v in pairs(total_data) do
    acnt = acnt + 1
  end
  if acnt == self.playercnt then
    self.room:get_combatStat()
    for k,v in pairs(total_data) do
      self.room:sendClientMsg_byid(k, 2, v)
    end
  end
end

function m:killoff_cheatplayer(pid)
  if true then return end
  
  local msg = {}
  msg.__mt__ = 2
  msg.cmd = "player_kickoff"
  msg.data = {}
  msg.data.error = 1
  msg.sender = 0

  self.room:sendClientMsg_byid(pid, 2, msg)

  --save to redis
  local playerCheatInfo = RedisHelper.hget("{player_cheat_info}", pid)
  if playerCheatInfo then
    playerCheatInfo = cjson.decode(playerCheatInfo)
  else
    playerCheatInfo = {}
  end
  playerCheatInfo[room_token] = {}
  playerCheatInfo[room_token].roominfo = self.room.roominfo
  playerCheatInfo = cjson.encode(playerCheatInfo)
  RedisHelper.hset("{player_cheat_info}", pid, playerCheatInfo)

  self.playerdata[pid] = nil
  total_data[pid] = nil
  self.playercnt = self.playercnt - 1
end