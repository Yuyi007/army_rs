class("TeamInviteUtil",function(self) end)

local m = TeamInviteUtil

function m.init()
  m.inviteViewList = {}

  m.sigTeam = md:signal("sync_team_msg"):add(function(msg)
    -- logd('[TeamInviteUtil] sync_team_msg:%s', inspect(msg))

    -- invit 邀请，放在MainRoomView
    if msg.cmd == "sync_team" then
      if msg.data.op == "invit" then
        m.onRevTeamInvit(msg.data)
      end
    end
  end)
end

function m.exit()
  if m.sigTeam then
    md:signal("sync_team_msg"):remove(m.sigTeam)
    m.sigTeam = nil
  end
end

function m.onRevTeamInvit(data)
  -- logd("[TeamInviteUtil] onRevTeamInvit:%s", inspect(data))


  local viewCount = #m.inviteViewList
  
  if(viewCount >= 3) then
    logd('[TeamInviteUtil] invite view on max')
    return
  end

  local inviteView = InviteView.new(data, m)
  ui:push(inviteView, nil, false)
  table.insert(m.inviteViewList, inviteView)
end

function m.popInviteView(view)

  local count = #m.inviteViewList
  if view then
    for i = count , 1, -1 do
      if m.inviteViewList[i] == view then
        ui:popView(m.inviteViewList[i])
        table.remove(m.inviteViewList, i)
      end
    end
  else
    ui:popView(m.inviteViewList[count])
    table.remove(m.inviteViewList, m.inviteViewList[count])
  end
end


function m.popAllInviteView()
  for i = #m.inviteViewList, 1, -1 do
    ui:popView(m.inviteViewList[i])
    table.remove(m.inviteViewList, i)
  end

end