class('GmUtil')

GmUtil.range = false
GmUtil.getBallRange = false
GmUtil.battery = false
GmUtil.cheatGame = false

function GmUtil.changeRange(value)
  GmUtil.range = value
end

function GmUtil.changeGetBallRange(value)
  GmUtil.getBallRange = value
end

function GmUtil.changeBattery(value)
  GmUtil.battery = value
end

function GmUtil.changeCheatGame(value)
  GmUtil.cheatGame = value
end

function GmUtil.initAttr()
	GmUtil.range = false
	GmUtil.getBallRange = false
	GmUtil.battery = false
	GmUtil.cheatGame = false
end