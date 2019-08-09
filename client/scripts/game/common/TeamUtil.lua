class('TeamUtil')

local m = TeamUtil

function m.sendTeamInvitation(topid,frompid)
	  md:rpcSendAddTeam(topid,frompid,function(msg)
	  	 
	  end)
end