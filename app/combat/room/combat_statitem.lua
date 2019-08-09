--[[
    {
  begintime = 1550132195,
  ctype = 4,
  duration = 480,
  enter_type = 0,
  mtype = 1,
  token = "test token",
  winner = 0,

  stats = {
    {
      side = 0,
      mvp = "1_10000029_i1",      
      pstats = { {
          assist = 5,
          cs = 0,
          death = 3,
          dmg = 10000,
          fmbl = 0,
          goal = 3,
          heal = 0,
          hsqj = 0,
          icon = 8,
          icon_frame = 1,
          kill = 5,
          mvp_score = 10.1,
          name = "tohka17",
          pid = "1_10000029_i1",
          series_kill = 5,
          tdmg = 10000,
          team = 0,
          tid = "car001",
          txws = 0,
          wjbc = 0,
          wl = 1,
          zzbs = 0
        }, ... }
    },
    {
      side = 1,
      mvp = "1_10000076_i1",
      pstats = { {
          assist = 1,
          cs = 0,
          death = 2,
          dmg = 0,
          fmbl = 0,
          goal = 2,
          heal = 0,
          hsqj = 0,
          icon = 4,
          icon_frame = 2,
          kill = 3,
          mvp_score = 6.9,
          name = "test02",
          pid = "1_10000075_i1",
          series_kill = 3,
          tdmg = 0,
          team = 0,
          tid = "car001",
          txws = 0,
          wjbc = 0,
          wl = 6,
          zzbs = 0
        },...}      
    }
  }
}
]]
class("CombatStatItem", function(self, room)
  self.initialized = false

  self.room = room

  self.totaldata = {}

  self.token = ""  
  self.mtype = -1
  self.ctype = -1
  self.winner = -1
  self.duration = 0
  self.begintime = 0
  self.enter_type = 0

  self.side0 = {}
  self.side0.mvp = ""
  self.side0.pstats = {}

  self.side1 = {}
  self.side1.mvp = ""
  self.side1.pstats = {}
end)

local m = CombatStatItem

function m:getCombatStat(playerdata, pid, room, total_data)
  local resData = {}

  print("getCombatStat", pid, inspect(total_data[pid].data.detail))

  resData.token = total_data[pid].data.detail.token
  resData.mtype = total_data[pid].data.detail.mtype
  resData.ctype = total_data[pid].data.detail.ctype
  resData.winner = total_data[pid].data.detail.winner
  resData.duration = total_data[pid].data.detail.duration
  resData.begintime = total_data[pid].data.detail.begintime
  resData.enter_type = total_data[pid].data.detail.enter_type
  resData.stats = {}

  if total_data[pid].data.detail.side0_mvp then playerdata[pid].side0.mvp = total_data[pid].data.detail.side0_mvp end
  if total_data[pid].data.detail.side1_mvp then playerdata[pid].side1.mvp = total_data[pid].data.detail.side1_mvp end
  if total_data[pid].data.detail.mvp_scores then
    for p,v in pairs(total_data[pid].data.detail.mvp_scores) do

      if playerdata[pid].side0.pstats[p] then
        playerdata[pid].side0.pstats[p].mvp_score = v

      elseif playerdata[pid].side1.pstats[p] then
        playerdata[pid].side1.pstats[p].mvp_score = v

      end
    end
  end
  if total_data[pid].data.detail.player_data then
    self:set_playerdata(playerdata, pid, total_data[pid].data.detail.player_data)
  end

  local s0 = {}
  s0.side = 0
  s0.mvp = playerdata[pid].side0.mvp
  s0.pstats = {}

  local s1 = {}
  s1.side = 1
  s1.mvp = playerdata[pid].side1.mvp
  s1.pstats = {}

  local members = room:members()
  for ind, side in pairs(members) do 
    for _, seat in pairs(side) do 
      if seat ~= -1 then
        if seat.pid then
          if ind == 1 then
            table.insert(s0.pstats, playerdata[pid].side0.pstats[seat.pid])
          else
            table.insert(s1.pstats, playerdata[pid].side1.pstats[seat.pid])
          end
        end
      -- else
      --   if ind == 1 then
      --     table.insert(s0.pstats, -1)
      --   else
      --     table.insert(s1.pstats, -1)
      --   end
      end
    end
  end

  table.insert(resData.stats, s0)
  table.insert(resData.stats, s1)

  return resData
end

function m:init_players(playerdata, pid, sideindex, seat)
  -- print("init_players", pid, sideindex, inspect(seat))
  local tb = {}
  tb.assist = 0
  tb.cs = 0
  tb.death = 0
  tb.dmg = 0
  tb.fmbl = 0
  tb.goal = 0
  tb.heal = 0
  tb.hsqj = 0
  tb.icon = 0
  tb.icon_frame = 0
  tb.kill = 0
  tb.mvp_score = 0
  tb.name = seat.name
  tb.pid = seat.pid
  tb.series_kill = 0
  tb.tdmg = 0
  tb.team = 0
  tb.tid = seat.tid
  tb.txws = 0
  tb.wjbc = 0
  tb.wl = 0
  tb.zzbs = 0

  if sideindex == 0 then
    playerdata[pid].side0.pstats[seat.pid] = tb
  elseif sideindex == 1 then
    playerdata[pid].side1.pstats[seat.pid] = tb
  end
end

function m:set_playerdata(playerdata, pid, data)
  -- print("set_playerdata", pid, inspect(data), inspect(playerdata[pid].side0), inspect(playerdata[pid].side1))

  for p, v in pairs(data) do
    for m,n in pairs(v) do

      if playerdata[pid].side0.pstats[p]  then
        playerdata[pid].side0.pstats[p][m] = n

      elseif playerdata[pid].side1.pstats[p] then
        playerdata[pid].side1.pstats[p][m] = n

      end

      print('set value')
    end
  end
end

function m:set_totaldata(playerdata, pid, data) 
  -- print("set_totaldata", self, pid, inspect(data))
 --[[ if data.begintime then 
    self.begintime = data.begintime 
    print(self, self.begintime)
  end
  if data.ctype then self.ctype = data.ctype end
  if data.duration then self.duration = data.duration end
  if data.enter_type then self.enter_type = data.enter_type end
  if data.mtype then self.mtype = data.mtype end
  if data.token then self.token = data.token end
  if data.winner then self.winner = data.winner end--]]

  --playerdata[pid].totaldata = data
  for k,v in pairs(data) do
    playerdata[pid].totaldata[k] = v
  end

  if data.side0_mvp then playerdata[pid].side0.mvp = data.side0_mvp end
  if data.side1_mvp then playerdata[pid].side1.mvp = data.side1_mvp end

  if data.mvp_scores then
    for p,v in pairs(data.mvp_scores) do

      if playerdata[pid].side0.pstats[p] then
        playerdata[pid].side0.pstats[p].mvp_score = v

      elseif playerdata[pid].side1.pstats[p] then
        playerdata[pid].side1.pstats[p].mvp_score = v

      end
    end
  end

  if data.player_data then
    self:set_playerdata(playerdata, pid, data.player_data)
  end

end


