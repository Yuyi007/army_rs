class("FrameBroadcaster", function(self, room)
	self.initialized = false
	self.room = room
	self.actions = {} -- All actions

	self.sendStartFrames = {}
	self.sendStopFrames = {}
	self.batchSending = {}
	self.frameMsg = {} --Always use this table to send msg
end)

local m = FrameBroadcaster

function m:init()
	self:initPool()
	self.initialized = true
end

function m:initPool()
	local opts = {tag = "actionslist", initSize = 1000, maxSize = 15000}
	self.actionListPool = Pool.new(function () 
			return {}
		end, opts)
end

function m:getActionLst(frm)
	local lst = self.actions[frm]
	lst = lst or self.actionListPool:borrow()
	self.actions[frm] = lst
	return lst
end

local EMPTY_MSG = {}
local STATUS_ONLINE 	= 1
function m:broadcast(frm)

	local lst = self.actions[frm]
	if #lst == 0 then
		self.actionListPool:recycle(lst)
		self.actions[frm] = EMPTY_MSG
		lst = EMPTY_MSG
	end

	self.room:eachPlayer(function(player)
			local pid = player.pid
			-- print("broad cast to player:", player.pid, player.addr, player.port)
			self.sendStopFrames[pid] = frm

			if player.status == STATUS_ONLINE then
				local startFrame = self.sendStartFrames[pid] or 0
				local stopFrame = frm
				--Frame difference equal to 1 means client speedup finished
				-- if stopFrame - startFrame == 1 then
				if stopFrame - startFrame == 1 then
					if not self.batchSending[pid] then
						self.frameMsg[1] = frm --"curFrame"
						self.frameMsg[2] = lst --"actions"
						-- print("send frm idx:", frm)
						self.room:sendClientMsg(player, 3, self.frameMsg)
						self.sendStartFrames[pid] = frm
					else
						print("batch sending")
					end
				else
					print("startFrame:", startFrame, " stopFrame:", stopFrame)
				end
			end
		end)
end

function m:resetSendStatus(player)
	self.sendStartFrames[player.pid] = nil
end

function m:startBatchSend(player, startFrame)
	local pid = player.pid
	self.batchSending[pid] = true

	self.sendStartFrames[pid] = startFrame
	local stopFrame = self.sendStopFrames[pid] or 0

	self.batchMsg = self.batchMsg or {startFrame = 0, stopFrame = 0, frames = {}}
	--如果有ack确认机制的话这里需要特殊处理只有一个玩家的时候 服务器帧只比客户端逻辑帧大一帧
	-- if stopFrame - startFrame  <= 1 then
	-- 	table.clear(self.batchMsg["frames"])
	-- 	self.batchMsg["startFrame"] = startFrame
	-- 	self.batchMsg["stopFrame"] = stopFrame
	-- 	self.batchMsg["finished"] = true
	-- 	self.room:sendClientMsg(player, 4, self.batchMsg)
	-- else
		print("Begin batch: stopFrame:"..tostring(stopFrame).." startFrame:"..tostring(startFrame))
		while ((stopFrame - startFrame)  > 0) and 
					(player.status == STATUS_ONLINE) do --Maybe player offline while sending frame data
			local start = startFrame
			local stop = start + 10
			
			if stop >= stopFrame then
				stop = stopFrame
				self.batchMsg["finished"] = true
			else
				self.batchMsg["finished"] = false
			end

			table.clear(self.batchMsg["frames"])

			self.batchMsg["startFrame"] = start
			self.batchMsg["stopFrame"] = stop
			
			for i = start + 1, stop do 
				-- print("send frm idx[b]:", i)
				table.insert(self.batchMsg["frames"], self.actions[i])	
			end
			self.room:sendClientMsg(player, 4, self.batchMsg)

			startFrame = stop
			self.sendStartFrames[pid] = stop

			skynet.sleep(1)
			--Stop frame maybe changed as sleep lead to yield
			stopFrame = self.sendStopFrames[pid]
			print("Loop batch: stopFrame:"..tostring(stopFrame).." startFrame:"..tostring(startFrame))
		end
		self.batchSending[pid] = false
	-- end
end

function m:exit()
	self.actionListPool:clear()

	self.actions = nil
	self.sendStartFrames = nil
	self.sendStopFrames = nil	
	self.frameMsg = nil
end