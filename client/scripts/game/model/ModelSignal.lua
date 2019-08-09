
local funcs = {}

function funcs.city(msg)
  -- logd('funcs.city handles %s', peek(msg))

  if msg.city then
    md:replaceCity(msg.city)
  end

  if md.city then
    md.city.__cityMsg = msg
  end

  if msg.weather_changed then
    --FloatingTextFactory.makeNormal{text=loc("weather changed to %s !!", md.city:getCityWeather().cur_param.tid)}
    CityWeatherUtil.refreshCityWeather(md.city)
    md:triggerWeatherNews()
    md:rpcRefreshNpcs(function(msg)
      -- md:signal('refreshnpc'):fire()
    end)

    local city = md:getCity()
    local cw = city:getCityWeather()
    local wsrTid = cw.cur_param.shop_dtid
    -- logd("check wtid:%s", tostring(wsrTid))
    if wsrTid and cfg.weather_shop_replace[wsrTid] then
        local strMessage = cfg.weather_shop_replace[wsrTid].weather_notice
        local cfgMarquee = cfg.marquee["ntc1002"]
        -- logd("check message: %s", strMessage)
        if md:isFunUnlock("func3301") then
          Util.showMarquee(strMessage, cfgMarquee.loop_time, cfgMarquee.priority)
        end
    end

    md:signal("weather_changed"):fire()
  end

  if msg.time_state_changed then
    md:rpcRefreshNpcs(function(msg)
      -- md:signal('refreshnpc'):fire()
    end)
    -- logd("time_state_changed fire")
  end

end

function funcs.mysteryshop(msg)
  md.mystery_shop = md.mystery_shop or {}

  if msg.adds  then
    table.concatArrays(md.mystery_shop, msg.adds)
    md:signal("mysteryshop_change"):fire()
  end

  if msg.remove then
    for i,v in pairs(md.mystery_shop) do
      if v.npc == msg.remove then
        table.remove(md.mystery_shop, i)
        break
      end
    end
    md:signal("mysteryshop_change"):fire()
  end
end

function funcs.shadow_advance(msg)
  if not msg.changes then return end
  if not md.advance_shadows then return end
  local olds = {}
  for k, v in pairs(msg.changes) do
    olds[k] = md.advance_shadows[k]
    md.advance_shadows[k] = v
  end
  md:signal("shadow_advance_change"):fire(olds, msg.changes)
end

function funcs.booth_message(msg)
  md:signal("booth_goods_sold"):fire(msg)
end

function funcs.preproc(msg)
  md:preProcMsg(msg)
end

function funcs.team_5X5(msg)
  md:updateChats(msg.chat)
end

function  funcs.channel_chat(msg)
  md:updateChats(msg.chat)
end

function funcs.friend_chat(msg)
  md:updateFrdChats(msg.chat)
end

function funcs.hero_change(msg)
end

function funcs.skill_unlock_changed(msg)
end

function funcs.limit_event(msg)
  md.limit_events = msg.event_list
  --msg.opt: prepare, start, stop, finish
  md:signal("limit_event_" .. msg.opt):fire(msg)
end

local m = Model

function m:initSignals()
  self.signals = {}
  for k, func in pairs(funcs) do
    if not self:signal(k):added(func) then
      self:signal(k):add(func)
    end
  end
end

-- TODO use me
function m:exitSignals()
  for k, signal in pairs(self.signals) do
    signal:clear()
  end
end

-- do not clear signals in funcs
function m:resetSignals()
  for k, signal in pairs(self.signals) do
    if not funcs[k] then
      signal:clear()
    end
  end
end

function m:signal(...)
  local t = table.concat({...}, '_')
  if not self.signals[t] then
    self.signals[t] = Signal.new()
  end
  return self.signals[t]
end



