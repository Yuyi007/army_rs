View("CheatCodeView", "prefab/ui/others/cheat_code_ui", function(self)
end)

local m = CheatCodeView

function m:init()
	self.helpNotes = {
		help = [[/help eg:/help:code    		 Showing u how to use [code] command.]],
		give = [[/give eg:/give:tid:count    Showing u how to send item to player.
																				 count will set to 1 if not given]],
	}
end

function m:onBtnClose()
	ui:remove(self)
end

function m:onBtnSend()
	local txt = self.cheatInput:getString()
	local arr = self:parseCode(txt)
	local code = arr[1]
	
	local func = self["do_"..code]
	if func and type(func) == "function" then
		func(self, unpack(arr))
	end
end

function m:parseCode(txt)
	local command = txt:match('^/(.+)')
	if not command then
    FloatingTextFactory.makeFramedTwo {text = loc("error code",3), 
    color = ColorUtil.red }
    return
	end
  return command:split(':')
end

--/help:code
function m:do_help(code)
	local str = ""
	if code then
		str = str .. self.helpNotes[code]
	else
		for i,v in pairs(self.helpNotes) do 
			str = str..v
		end
	end
	self.txtNote:setString(str)
end

--/give:tid:count
function m:do_give(code, tid, count)
	local args = {code = code, tid = tid, count = count}
	md:rpcCheatGame(args, function(msg)
			self.txtNote:setString(inspect(msg.bonuses))
			logd("current credits:%s", tostring(md.chief.credits))
      TreasureUtil.showTreasure(ui.baseView.gNum, ui.baseView.dNum, ui.baseView.cNum)
		end)
end

