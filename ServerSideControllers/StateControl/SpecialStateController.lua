local sS						= game.ServerStorage:WaitForChild("SendStats")
local tS 						= game.ServerStorage:WaitForChild("TakeStats")
local NDR 						= game.ServerStorage:WaitForChild("NewPlayerDataReady")
local DR 						= game.ServerStorage:WaitForChild("DataReady")
local rEvent					= game.ServerStorage:WaitForChild("RuntimeEvent")
local tEvent					= game.ServerStorage:WaitForChild("TribulationEvent")
local stEvent 					= game.ServerStorage:WaitForChild("BaseStateEvent")
local SC						= game.ReplicatedStorage:WaitForChild("StateChange")
local Players 					= game:GetService("Players")
local BuffClass					= require(script.Parent.StateController.BuffClass)
local DamageClass				= require(script.Parent.CombatController.DamageClass)
local Switch					= require(script.Parent.Switch)
local summonVfx 				= game.ServerStorage:WaitForChild("SummonVfx")
local summonWeldedVfx			= game.ServerStorage:WaitForChild("SummonWeldedVfx")
local destroyVfx				= game.ServerStorage:WaitForChild("DestroyVfx")

local vfxPos

local DelayTable = {
	["Fire"] = 3.7,
	["Water"]= 4.5
}


script.Parent:WaitForChild("DataController")

DR.Event:Connect(function()

end)	

NDR.Event:Connect(function(player)

end)

Players.PlayerAdded:Connect(function(player) -- checks to see if the player is out of lives each time they die
	player.CharacterAdded:Connect(function(character)
		character.Humanoid.Died:Connect(function()
			local pstats = sS:Invoke(player)
			pstats.States.SpStates.Dead = true
			pstats.Lives -= 1 	--remove a life from the player that died
			if pstats.Lives == 0 then 
				rEvent:Fire("Dead",player)
			end
			------------------------------------------------------------ Remove all buffs that aren't permanent from the players stats
			for i, v in pairs(pstats.States.Buffs) do 
				if v.Duration ~= -1 then
					pstats = BuffClass.Remove(v,pstats)
				end
			end	
			------------------------------------------------------------ Keep the fact that you've obtained the achievement there but remove the points you got and reset all of it to 0
			for i, v in pairs(pstats.Achievements.Feats) do 
				if v.Active then 
					v.Active = false 
					pstats.Achievements.Points -= v.Points
				end
			end
			-------------------------------------------------------- Reset all the stats of the player when they come back 
			pstats.Health.Current 	= pstats.Health.Max
			pstats.Qi.Current		= pstats.Qi.Max
			pstats.Temperature		= 0
			--------------------------------------------------------  Update the saved stats, wait a bit, then load the player in
			tS:Fire(pstats,script.Name)
			wait(4)
			pstats.States.SpStates.Dead = false
			player:LoadCharacter()
		end)
	end)
end)


local StateChangeSwitch = Switch()

:case("Cultivation",function(list)
	if list.tempStats.States.SpStates[list.key] ~= list.change then
		list.tempStats.States.SpStates[list.key]= list.change 
		local Data			= {}
		Data.Player	   		= list.player
		Data.Tickrate		= .5 -- for things that need to be constantly active for a set amount of time
		Data.Name 			= "Cultivation".."Basic"..list.player.Name
		Data.Destroy 		= false -- the specific animation that plays when the object is destroyed, in this case it fires all particles and waits
		if list.change == true then 
			summonVfx:Fire("Cultivation".."Basic",workspace[list.player.Name].UpperTorso.CFrame,Data,true)
		else
			destroyVfx:Fire("Cultivation".."Basic",Data,true)
		end
	end
	return list.tempStats
end)

:case("Blocking",function(list)
	if list.tempStats.States.SpStates[list.key] ~= list.change then
		list.tempStats.States.SpStates[list.key] = list.change 
		list.tempStats.Block.Current = list.tempStats.Block.Max -- reset the amount of block you have each time you put the block up
		local Data			= {}
		Data.Player	   		= list.player
		Data.Name 			= "Block"..list.player.Name
		Data.Destroy 		= -1 -- in this case it just waits for everything to be over
		Data.Lifetime		= .05 -- the amount of time before it gets removed by the debris service
		if list.change == true then 
			summonWeldedVfx:Fire("Block",workspace[list.player.Name].HumanoidRootPart,Data,false)
		else
			destroyVfx:Fire("Block",Data,false)
		end
	end
	return list.tempStats
end)

SC.OnServerEvent:Connect(function(player,key,change) --cultivating event
	-- for a sanity check you can check the players position. If the position is the same from both sends then you know they ain't cheating.
	local tempStats = sS:Invoke(player)
	print(tempStats)
	print(player,key,change)
	
	local list 		= {}
	list.tempStats 	= tempStats
	list.player 	= player
	list.change 	= change
	list.key		= key
	tempStats		= StateChangeSwitch(key,list)

	tS:Fire(tempStats,script.Name)	
end)


local elementSwitch2 = Switch()

:case(1,function(Tribulation)
	Tribulation.Element1 = "Fire"
	Tribulation.Element2 = "Metal"
	Tribulation.Name 	 = "Lightning"
	Tribulation.DamageCount = 4
end)
:case(2,function(Tribulation)
	Tribulation.Element1 = "Water"
	Tribulation.Element2 = "Earth"
	Tribulation.Name	 = "Ice"
	Tribulation.DamageCount = 4

end)
:case(3,function(Tribulation)
	Tribulation.Element1 = "Light"
	Tribulation.Element2 = "Light"
	Tribulation.Name	 = "Light"
	Tribulation.DamageCount = 4
end)
:case(4,function(Tribulation)
	Tribulation.Element1 = "Dark"
	Tribulation.Element2 = "Dark"
	Tribulation.Name	 = "Dark"
	Tribulation.DamageCount = 4
end)
:default(function(Tribulation)
	Tribulation.Element2 = nil
end)


local elementSwitch = Switch()

:case(1,function(list)
	list.Tribulation.Element1 = "Fire"
	list.Tribulation.Element2 = "Fire"
	list.Tribulation.Name	 = "Fire"
	list.Tribulation.DamageCount = 50
	list.Tribulation.Tickrate = .5
	list.Tribulation.QiShred	 = .35
	vfxPos = Vector3.new(list.player.Character.HumanoidRootPart.Position.X,list.player.Character.RightFoot.Position.Y,list.player.Character.HumanoidRootPart.Position.Z)
end)
:case(2,function(list)
	list.Tribulation.Element1 = "Water"
	list.Tribulation.Element2 = "Water"
	list.Tribulation.Name	 = "Water"
	list.Tribulation.DamageCount = 15
	list.Tribulation.QiShred	 = .01
	list.Tribulation.Debuff	 = BuffClass.new("HeartOfWater", {{"QiDefense","Multi",".7"},{"QiDefense","Add","-3"}},list.Tribulation.Tickrate*list.Tribulation.DamageCount+1,1)
	vfxPos = Vector3.new(list.player.Character.HumanoidRootPart.Position.X,list.player.Character.RightFoot.Position.Y+10.242,list.player.Character.HumanoidRootPart.Position.Z)
end)
:case(3,function(list)
	list.Tribulation.Element1 = "Earth"
	list.Tribulation.Element2 = "Earth"
	list.Tribulation.Name	 = "Earth"
	list.Tribulation.DamageCount = 10
	list.Tribulation.Proportion = .7
	list.Tribulation.Debuff	 = BuffClass.new("HeartOfEarth", {{"PhysicalDefense","Multi",".9"},{"PhysicalDefense","Add","-3"}},list.Tribulation.Tickrate*list.Tribulation.DamageCount+1,1)
end)
:case(4,function(list)
	list.Tribulation.Element1 = "Metal"
	list.Tribulation.Element2 = "Metal"
	list.Tribulation.Name	 = "Metal"
	list.Tribulation.DamageCount = 1
	list.Tribulation.Strength *= 1.03
	list.Tribulation.Proportion = .9
	list.Tribulation.Debuff	 = BuffClass.new("HeartOfMetal", {{"PhysicalDefense","Multi",".5"}},list.Tribulation.Tickrate*list.Tribulation.DamageCount+1,1)
end)
:case(5,function(list)
	list.Tribulation.Element1 = "Wood"
	list.Tribulation.Element2 = "Wood"
	list.Tribulation.Name     = "Wood"
	list.Tribulation.DamageCount = 25
	list.Tribulation.Tickrate = .5
	list.Tribulation.QiShred	 = .06
	list.Tribulation.Debuff	 = BuffClass.new("HeartOfNature", {{"RegenHealth","Multi",".4"}},list.Tribulation.Tickrate*list.Tribulation.DamageCount+1,1)
	--pStats.Health.Regen = pStats.Health.Regen/3
end)

tEvent.Event:Connect(function(pStats,player)
	local Tribulation = {}
	Tribulation.Tickrate = 1
	
	if pStats.Cultivation.State >= 1 then
		Tribulation.Strength = 110+ 7*math.pow(pStats.Cultivation.State+1,2)*math.log10(pStats.Cultivation.State+1)
	else
		Tribulation.Strength = 110
	end
	
	Tribulation.Proportion = 0
	
	local element =	 2--math.random(1,5)
	local element2 = nil--math.random(1,100)
	
	elementSwitch2(element2,Tribulation)
	
	if Tribulation.Element2 == nil then 
		local list = {}
		list.Tribulation = Tribulation
		list.player 	 = player
		
		elementSwitch(element,list)
	end
	
	Tribulation.ArmorPen = pStats.Cultivation.State+1
	--print(Tribulation.Element1,Tribulation.Element2)
	local x = DamageClass.New("Tribulation",Tribulation.Strength/Tribulation.DamageCount,Tribulation.Proportion,{Tribulation.Element1,Tribulation.Element2},Tribulation.ArmorPen,Tribulation.QiShred,1)
	--------------------------------------------------------------- Vfx parameter declaration
	
	local Data = {}
	Data.Duration 		= Tribulation.Tickrate * Tribulation.DamageCount + DelayTable[Tribulation.Name]
	Data.Player	   		= player
	Data.Name 			= Tribulation.Name
	Data.Destroy		= true	
	Data.DestroyDelay 	= 1
	summonVfx:Fire(Tribulation.Name.."Tribulation", vfxPos,Data,false)
	--------------------------------------------------------------- Vfx parameter declaration
	task.wait(DelayTable[Tribulation.Name])
	if Tribulation.Debuff then 
		stEvent:Fire(Tribulation.Debuff,player)
		pStats = sS:Invoke(player)
	end
	for i=1, Tribulation.DamageCount, 1 do 
		--print("------------------| STRIKE! |------------------")
		pStats = x:SelfApply(pStats)	
		tS:Fire(pStats,script.Name)
		task.wait(Tribulation.Tickrate)
		if Tribulation.DamageCount > 1 then 
			pStats = sS:Invoke(player)
		end
		if pStats.States.SpStates.Dead then  print("breaking out") break end
	end	
	pStats.States.SpStates.Tribulating = false
	destroyVfx:Fire(Tribulation.Name.."Tribulation",Data,false)
	if not pStats.States.SpStates.Dead then
		pStats.Cultivation.State += 1
		pStats.States.SpStates.Cultivating =false
		pStats.Cultivation.CBase = 0
		pStats.Cultivation.CBaseMax = math.ceil(100*math.sqrt(pStats.Cultivation.State+1)*math.pow(pStats.Cultivation.State+1,2))
		for i, v in pairs(pStats.AugmentingStats) do
			pStats.AugmentingStats[i] += 5*pStats.Cultivation.State
		end
	end
	tS:Fire(pStats,script.Name)	
end)

