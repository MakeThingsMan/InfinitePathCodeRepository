local stEvent 				= game.ServerStorage:WaitForChild("BaseStateEvent")
local stFunction			= game.ServerStorage:WaitForChild("BaseStateFunction")
local sS 					= game.ServerStorage:WaitForChild("SendStats")
local tS					= game.ServerStorage:WaitForChild("TakeStats")
local augStats 				= game.ServerStorage:WaitForChild("AugStats")
local removeBuff 			= game.ServerStorage:WaitForChild("RemoveBuff")
local disableBuff		 	= game.ServerStorage:WaitForChild("DisableBuff")
local nullifyBuff			= game.ServerStorage:WaitForChild("NullifyBuff")
local BuffClass 			= require(script.BuffClass)
script.Parent:WaitForChild("DataController")

----------------------------------------------------------------------------------------------------------------
stEvent.Event:Connect(function(buff, player) --used to declare the buffs
	local playerStats = sS:Invoke(player)
	if not playerStats.States.Buffs[buff.Name] then 
		print(playerStats.States.Buffs[buff.Name] )
		print(buff)
		playerStats.States.Buffs[buff.Name] = buff 
	end
	if playerStats.States.Buffs[buff.Name].Stacks < playerStats.States.Buffs[buff.Name].MaxStacks then 
		playerStats.States.Buffs[buff.Name].Stacks += 1 --lets the buffs stack if they're less than their maxStacks
		if buff.Special ~= -1 then 
			playerStats.States.SpStates[buff.Special[1]] = buff.Special[2] -- sets the special state in the form: {"Target", Value}
		end
		if buff.Tickrate ~= -1 then 
			local stacks = playerStats.States.Buffs[buff.Name].Stacks
			if buff.Finality and playerStats.States.Buffs[buff.Name].Stacks > 1 then
				BuffClass.Disable(buff,playerStats)
				playerStats.States.Buffs[buff.Name] = buff
				playerStats.States.Buffs[buff.Name].Stacks = stacks
			elseif not buff.Finality and playerStats.States.Buffs[buff.Name].Stacks > 1 then
				BuffClass.Remove(buff,playerStats)
				playerStats.States.Buffs[buff.Name] = buff
				playerStats.States.Buffs[buff.Name].Stacks = stacks
			end
			playerStats = BuffClass.TickApply(buff,playerStats)
			return
		else 
			playerStats = BuffClass.Apply(buff,playerStats)
		end
	else 
		warn("You're at max stacks for this buff, you really don't need no more")
	end
	print(playerStats, "from the buffs end")
	tS:Fire(playerStats,script.Name)
end)

nullifyBuff.OnInvoke = function(buff,pStats)
	pStats = BuffClass.Nullify(buff,pStats)
	return pStats
end

removeBuff.OnInvoke = function(buff,pStats)
	pStats = BuffClass.Remove(buff,pStats)
	return pStats
end

disableBuff.OnInvoke = function(buff,pStats)
	pStats = BuffClass.Disable(buff,pStats)
	return pStats
end

stFunction.OnInvoke = function(pStats) -- used to recalculate the buffs 
	for i, v in pairs(pStats.States.Buffs) do
		pStats = BuffClass.Apply(v,pStats)
	end
	return pStats
end

----------------------------------------------------------------------------------------------------------------