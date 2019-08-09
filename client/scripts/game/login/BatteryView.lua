View('BatteryView', 'prefab/ui/common/battery', function(self)
end)

local m = BatteryView

function m:init()
  self:reopenInit()
end

function m:reopenInit()
end

function m:reopenExit()
  if self.hBattery then
    scheduler.unschedule(self.hBattery)
    self.hBattery = nil
  end
  if self.hNet then
    scheduler.unschedule(self.hNet)
    self.hNet = nil
  end
end

function m:exit()
  if self.hBattery then
    scheduler.unschedule(self.hBattery)
    self.hBattery = nil
  end
  if self.hNet then
    scheduler.unschedule(self.hNet)
    self.hNet = nil
  end
  ui:pop()
end

function m:show()
  self:updateBattery()
  self:updateNet()
end

function m:updateBattery()
  if self.hBattery then return end
  self:setBatteryValue()
  self.hBattery = scheduler.schedule(function ()
    self:setBatteryValue()
  end, 1)
end

function m:updateNet()
  if self.hNet then return end
  self:setNetValue()
  self.hNet = scheduler.schedule(function ()
    self:setNetValue()
  end, 3)
end

function m:setBatteryValue()
  local battery = OsCommon.getSysBatteryLevel()
  self.battery_electricityBg_electricity.image:set_fillAmount(battery)
  self.battery_value:setString(tostring(battery * 100) .. "%")
  if UnityEngine.SystemInfo.batteryStatus == 1 or UnityEngine.SystemInfo.batteryStatus == 4 then
    self.battery_electricityBg_electricity:setColor(unity.hexToColorWithAlpha("FFFFFFFF"))
    self.battery_value:setColor(unity.hexToColorWithAlpha("24B93DFF"))
    self.battery_charge:setVisible(true)
  else
    self.battery_charge:setVisible(false)
    if battery < 0.2 then
      self.battery_electricityBg_electricity:setColor(unity.hexToColorWithAlpha("FF0000FF"))
      self.battery_value:setColor(unity.hexToColorWithAlpha("FF0000FF"))
    else
      self.battery_electricityBg_electricity:setColor(unity.hexToColorWithAlpha("FFFFFFFF"))
      self.battery_value:setColor(unity.hexToColorWithAlpha("24B93DFF"))
    end
  end
end

function m:setNetValue()
  local net = OsCommon.isLocalWifiAvailable()
  if net == true then
    self.net:setString("WiFi")
  elseif net == false then
    self.net:setString("4G")
  elseif net == nil then
    self.net:setString("")
  end
end