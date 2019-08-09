class("Dispatcher", function(self) end)
Dispatcher.handlers = {}
local m = Dispatcher.handlers
m[1] = require "app/combat/handlers/enter_room" 		--gate
m[2] = require "app/combat/handlers/control_action" 	--room
m[3] = require "app/combat/handlers/game_action"		--room
m[4] = require "app/combat/handlers/game_action_ack"	--room



