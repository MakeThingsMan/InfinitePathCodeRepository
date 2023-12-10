local Players 					= game:GetService("Players")
local DebrisService				= game:GetService("Debris")
local Lighting 					= game:GetService("Lighting")
local DR 						= game.ServerStorage:WaitForChild("DataReady")
local NDR 						= game.ServerStorage:WaitForChild("NewPlayerDataReady")
local sendStats 				= game.ServerStorage:WaitForChild("SendStats")
local takeStats 				= game.ServerStorage:WaitForChild("TakeStats")
local rEvent					= game.ServerStorage:WaitForChild("RuntimeEvent")
local tEvent					= game.ServerStorage:WaitForChild("TribulationEvent")
local stFunction				= game.ServerStorage:WaitForChild("BaseStateFunction")
local CheckAchievements			= game.ServerStorage:WaitForChild("CheckAchievements")
local sREvent					= game.ServerStorage:WaitForChild("SpecialRuntimeEvent")
local augStats 					= game.ServerStorage:WaitForChild("AugStats")
local buffEvent					= game.ServerStorage:WaitForChild("BaseStateEvent")
local removeBuff 				= game.ServerStorage:WaitForChild("RemoveBuff")
local disableBuff				= game.ServerStorage:WaitForChild("DisableBuff")
local nullifyBuff				= game.ServerStorage:WaitForChild("NullifyBuff")
local inventoryEvent			= game.ServerStorage:WaitForChild("InventoryEvent")
local destroyVfx				= game.ServerStorage:WaitForChild("DestroyVfx")
local npcDodge					= game.ServerStorage:WaitForChild("NpcDodge")
local rearrangeInventory		= game.ReplicatedStorage:WaitForChild("RearrangeInventory")
local rearrangeHotbar			= game.ReplicatedStorage:WaitForChild("RearrangeHotbar")
local cCE						= game.ReplicatedStorage:WaitForChild("ClientCombatEvent")
local rCall						= game.ReplicatedStorage:WaitForChild("RuntimeCall")
local UpdateInv					= game.ReplicatedStorage:WaitForChild("UpdateInv")
local findInv					= game.ReplicatedStorage:WaitForChild("FindItem")
local EquipItem					= game.ReplicatedStorage:WaitForChild("EquipItem")
local UnequipItem				= game.ReplicatedStorage:WaitForChild("UnequipItem")
local ForcedUnequipTool			= game.ReplicatedStorage:WaitForChild("ForceUnequipTool")
local Dodge 					= game.ReplicatedStorage:WaitForChild("Dodge")
local TalentEffected 			= require(script.Parent.DataController["Talent Augments"])
local Switch 					= require(script.Parent.Switch)
local ItemClass					= require(script.Parent.DataController.ItemClass)

local timeTickrate 				= 10

--local rEventDebounce 			= false -- would need to be a table implementation rather than a bool implementation for this to work

script.Parent:WaitForChild("DataController")

local slotsDictionary = {
	Head 		= "Head",
	Body 		= "UpperTorso",
	LeftArm		= "LeftUpperArm",
	RightArm	= "RightUpperArm",
	LeftLeg		= "LeftUpperLeg",
	RightLeg	= "RightUpperLeg",
	Spirit		= "HumanoidRootPart",
	Artifact	= "HumanoidRootPart",
	Pet			= "HumanoidRootPart"
}

DR.Event:Connect(function(player)
	player.CharacterAppearanceLoaded:Connect(function()
		for i, v in pairs(player.Character:GetChildren()) do
			if v:IsA("Accessory") then 
				if v.AccessoryType ~= "Hair" or v.AccessoryType ~= "Hat" then 
					v:Destroy()
				end
			end
		end
	end)
end)

NDR.Event:Connect(function(player)
	player.CharacterAppearanceLoaded:Connect(function()
		for i, v in pairs(player.Character:GetChildren()) do
			if v:IsA("Accessory") then 
				--print(v,v.AccessoryType == Enum.AccessoryType.Hair,v.AccessoryType == Enum.AccessoryType.Hat )
				if v.AccessoryType ~= Enum.AccessoryType.Hair and v.AccessoryType ~= Enum.AccessoryType.Hat then 
					v:Destroy()
				end
			end
		end
	end)
end)

----------------------------------------------------------------------------------------------------------------
rCall.OnServerEvent:Connect(function(player,key) --helps the player events do their thing
	local pStats = sendStats:Invoke(player)
	if not pStats.States.SpStates.Dead then
		rEvent:Fire(key,player)
	end
end)
---------------------------------------------------------------------------------------------------------------- Inventory section
inventoryEvent.Event:Connect(function(Item,player)
	local pStats = sendStats:Invoke(player)

	local success = scrubHotbar(Item,pStats,player,1,false)

	if not success then
		success,Item = scrubHotbarEmpty(Item,pStats,player,1)
		pStats = assignLocations(pStats) -- because i couldn't for the life of me figure out why doing this within the recurssive statement above wasn't working this is now here
		print(pStats.Hotbar)
	end

	if not success then 
		success = scrubInventory(Item,pStats,player,1,1,false)
		if not success then 
			success = scrubInventoryEmpty(Item,pStats,player,1,1)
			assignInventoryLocations(pStats) -- because the other section didn't work with the locations this is now here as a failsafe, I didn't even test if it worked i  just assumed it didn't.
		end
	end

	if not success then
		warn("The player has no free inventory space") -- when you eventually get to making items visible to the players make the item drop back if it gets to this point
	end
end)

rearrangeInventory.OnServerEvent:Connect(function(player,givenInventory) -- make sure you only take the inventory section of the thing so if hackers try some fs they don't got it
	-- eventually add a check that looks at arranges the invetory and checks to see if you have the same AMOUNT of an object in your inventory as saved within the server.	
	-- someone could potentially change things that are within the inventory like the damage of an item locally and send it here so make sure you only rearrange the order of the inventory
	-- no values other than the location of the item can change over here
	local pstats = sendStats:Invoke(player)
	pstats.Inventory = givenInventory
	takeStats:Fire(pstats,script.Name,"Rearrange Inventory")
end)

rearrangeHotbar.OnServerEvent:Connect(function(player,givenHotbar)
	local pstats = sendStats:Invoke(player)
	pstats.Hotbar = givenHotbar
	takeStats:Fire(pstats,script.Name,"Rearrange Hotbar")
end)

ForcedUnequipTool.OnServerEvent:Connect(function(player)
	player.Character.Humanoid:UnequipTools()	
end)

findInv.OnServerInvoke = function(player,objToFind,name,lastToolEquipped,key)
	local found
	local character = player.Character
	local humanoid 	= character.Humanoid
	local pStats 	= sendStats:Invoke(player)
	found = game.ServerStorage.Items:FindFirstChild(objToFind.Appearance,true)
	if key == "EquipCycle" then 
		if found then 
			if character:FindFirstChild(found.Name..name) then
				--print("Unequipping")
				humanoid:UnequipTools()
				lastToolEquipped = nil
				pStats.EquippedItem = lastToolEquipped
				takeStats:Fire(pStats,script.Name,"Updating the equipped item")
				return lastToolEquipped
			end
			if player.Backpack:FindFirstChild(objToFind.Appearance..name) then
				humanoid:EquipTool(player.Backpack[objToFind.Appearance..name])
				lastToolEquipped = player.Backpack[objToFind.Appearance..name]
				pStats.EquippedItem = objToFind
				takeStats:Fire(pStats,script.Name,"Updating the equipped item")
				return lastToolEquipped
			end
			local created = found:Clone()
			created.Parent 	= game.ReplicatedStorage.TempItems
			created.Name 	= created.Name..name
			humanoid:EquipTool(created)
			created.Parent 	= character
			lastToolEquipped = created
			pStats.EquippedItem = objToFind
			takeStats:Fire(pStats,script.Name,"Updating the equipped item")
			return lastToolEquipped
		end
		humanoid:UnequipTools() -- this is here to unequip your tools because you are deemed to have a empty in your hand
		pStats.EquippedItem = nil
		takeStats:Fire(pStats,script.Name,"Updating the equipped item")
	elseif key == "Find" then
		local success, failure = pcall(function()
			found = player.Character[objToFind.Appearance..name]
		end) 
		return success
	end
end

EquipItem.OnServerEvent:Connect(function(player,slots,itemFromServer,accessorySlots)
	local invSlot
	local identifier 
	local pstats = sendStats:Invoke(player)
	print(pstats.Hotbar)
	for i, v in pairs(slots) do 
		if accessorySlots then 
			pstats.Equipment[slots[i]][accessorySlots[i]] = itemFromServer
		else
			pstats.Equipment[slots[i]] = itemFromServer
		end
	end
	--- this section makes sure the number of stacks that you have updates on the server so it all stays consistent.
	print(itemFromServer)
	if itemFromServer.InvLocation[2] then 
		invSlot =  pstats.Inventory[itemFromServer.InvLocation[1]][itemFromServer.InvLocation[2]] 
		invSlot.Stacks -= 1 
		if invSlot.Stacks == 0 then  pstats.Inventory[itemFromServer.InvLocation[1]][itemFromServer.InvLocation[2]]	= ItemClass.NewEmpty() end
	else
		invSlot =	pstats.Hotbar[itemFromServer.InvLocation[1]]
		invSlot.Stacks -= 1 
		if invSlot.Stacks == 0 then pstats.Hotbar[itemFromServer.InvLocation[1]]	= ItemClass.NewEmpty() end
	end
	takeStats:Fire(pstats,script.Name,"Update the number of stacks while equipping")

	--this makes you play the animations associated with equipping
	EquipItem:FireClient(player,slots[1])
	---- temp solution while my head hurts
	local weld 		= Instance.new("WeldConstraint")
	local item 		= game.ServerStorage:FindFirstChild(itemFromServer.Appearance,true).Handle:clone()
	item.Anchored	= true
	item.Position 	= player.Character[slotsDictionary[slots[1]]].Position 
	item.Rotation 	= player.Character[slotsDictionary[slots[1]]].Rotation
	item.Parent 	= player.Character 
	item.Name 		= itemFromServer.Name
	weld.Parent 	= item
	weld.Part0		= player.Character[slotsDictionary[slots[1]]]
	weld.Part1		= item
	item.Anchored	= false
	changeAccessoryTransparency(slots[1],player,1)
	--- this is where you gain your stats from equipping something
	local config = require(item.Config)
	--if config == nil then warn(item.Name, " Has no config and does literally nothing stats wise") 	UpdateInv:FireClient(player) return end
	for i, v in pairs(config) do 
		print(i,v)
		if i == "Buffs" then 
			for j,k in pairs(v) do 
				buffEvent:Fire(k,player)
			end	
		else
			sREvent:Fire(i,v,player)
		end
	end
	local con = item.Config
	con.Parent = game.ServerScriptService.TempConfigs
	con.Name = itemFromServer.Name..player.Name.."Config"
	pstats = sendStats:Invoke(player)
	-- this is where we deal with the auxillaries that are present in some things
	if config.Aux then 
		for i, v in pairs(config.Aux) do 
			local weld = Instance.new("Weld")
			weld.Parent = v[1]
			weld.Part0	= v[1]
			weld.Part1	= player.Character[v[2]]
			v[1].Position = player.Character[v[2]].Position
			v[1].Rotation = player.Character[v[2]].Rotation 
		end
	end
	takeStats:Fire(pstats,script.Name,"Equip Item Done")
	UpdateInv:FireClient(player)
end)

UnequipItem.OnServerEvent:Connect(function(player,slot)
	local pStats = sendStats:Invoke(player)
	local item = pStats.Equipment[slot]
	print(item)
	item.Stacks = 1
	inventoryEvent:Fire(item,player)
	local config = require(game.ServerScriptService.TempConfigs[item.Name..player.Name.."Config"])
	if config == nil then warn(item.Name, " Has no config and does literally nothing stats wise") return end
	for i, v in pairs(config) do 
		--print(i,v)
		if v == "Buffs" then 
			for j, k in pairs(v) do
				pStats = removeBuff:Invoke(k,pStats)
				takeStats:Fire(pStats)
			end
		end
		v*=-1
		sREvent:Fire(i,v,player)
	end
	game.ServerScriptService.TempConfigs[item.Name..player.Name.."Config"]:Destroy()

	player.Character:FindFirstChild(item.Name,true):Destroy()
	changeAccessoryTransparency(slot,player,0)
end)

function changeAccessoryTransparency(slot,player,value)
	if slot == "Head" then 
		for i, v in pairs(player.Character:GetChildren()) do
			if v:IsA("Accessory") and v.AccessoryType == Enum.AccessoryType.Hair or  v:IsA("Accessory") and v.AccessoryType == Enum.AccessoryType.Hat then 
					v.Handle.Transparency = value
			end
		end
	end
end

function scrubHotbar(Item,pStats,player,initial,scrubbed)
	for i=initial, #pStats.Hotbar,1 do 
		if pStats.Hotbar[i].Name == Item.Name and pStats.Hotbar[i].MaxStacks > pStats.Hotbar[i].Stacks then 
			pStats.Hotbar[i].Stacks += Item.Stacks
			if pStats.Hotbar[i].Stacks - pStats.Hotbar[i].MaxStacks > 0 then 
				local x = pStats.Hotbar[i].Stacks - pStats.Hotbar[i].MaxStacks
				pStats.Hotbar[i].Stacks -= x
				local Item2 = Item
				Item2.Stacks = x
				scrubHotbar(Item2,pStats,player,i,true)
			end
			takeStats:Fire(pStats,script.Name)
			UpdateInv:FireClient(player)
			return true 
		elseif pStats.Hotbar[i].Id == 0 and scrubbed then 
			pStats.Hotbar[i] = Item
			pStats.Hotbar[i].InvLocation = {i,nil}
			takeStats:Fire(pStats,script.Name)
			UpdateInv:FireClient(player)
			return true 
		end
	end
	return false
end

function scrubHotbarEmpty(Item,pStats,player,initial)
	for i=initial, #pStats.Hotbar do
		if pStats.Hotbar[i].Id == 0 and Item.Stacks <= Item.MaxStacks then 
			pStats.Hotbar[i] = Item
			takeStats:Fire(pStats,script.Name)
			UpdateInv:FireClient(player)
			return true
		elseif pStats.Hotbar[i].Id == 0 and Item.Stacks > Item.MaxStacks then
			Item.Stacks -= Item.MaxStacks 
			pStats.Hotbar[i] = Item
			takeStats:Fire(pStats,script.Name)
			UpdateInv:FireClient(player)
			local success = scrubHotbarEmpty(Item,pStats,player,i+1)
			return success, Item
		end
	end
	return false,Item
end

function assignLocations(pStats)
	for i=1, #pStats.Hotbar do 
		pStats.Hotbar[i].InvLocation = {i,nil}
	end
	return pStats
end

function scrubInventory(Item,pStats,player,initial,jInital,scrubbed)
	for i=initial, #pStats.Inventory,1 do
		for j=jInital, #pStats.Inventory[i],1 do 
			if pStats.Inventory[i][j].Name == Item.Name and pStats.Inventory[i][j].MaxStacks > pStats.Inventory[i][j].Stacks then 
				pStats.Inventory[i][j].Stacks += Item.Stacks
				if pStats.Inventory[i][j].Stacks - pStats.Inventory[i][j].MaxStacks > 0 then 
					local x = pStats.Inventory[i][j].Stacks - pStats.Inventory[i][j].MaxStacks
					pStats.Inventory[i][j].Stacks -= x
					local Item2 = Item
					Item2.Stacks = x
					scrubInventory(Item2,pStats,player,i,j,true)
				end
				takeStats:Fire(pStats,script.Name)
				UpdateInv:FireClient(player)
				return true 
			elseif pStats.Inventory[i][j].Id == 0 and scrubbed then 
				pStats.Inventory[i][j] = Item
				pStats.Inventory[i][j].InvLocation = {i,j}
				takeStats:Fire(pStats,script.Name)
				UpdateInv:FireClient(player)
				return true 
			end
		end
	end
	return false
end

function scrubInventoryEmpty(Item,pStats,player,initial,jinitial)
	for i=initial, #pStats.Inventory do
		for j =jinitial,#pStats.Inventory[i] do 
			if pStats.Inventory[i][j].Id == 0 and Item.Stacks <= Item.MaxStacks  then 
				pStats.Inventory[i][j] = Item
				pStats.Inventory[i][j].InvLocation = {i,j}
				takeStats:Fire(pStats,script.Name)
				UpdateInv:FireClient(player)
				return true 
			elseif pStats.Inventory[i][j].Id == 0 and Item.Stacks > Item.MaxStacks then
				Item.Stacks -= Item.MaxStacks 
				pStats.Inventory[i][j] = Item
				pStats.Inventory[i][j].InvLocation = {i,j}
				takeStats:Fire(pStats,script.Name)
				UpdateInv:FireClient(player)
				local success = scrubInventoryEmpty(Item,pStats,player,i,j)
				return success
			end
		end
	end
end

function assignInventoryLocations(pStats)
	for i, v in pairs(pStats.Inventory) do
		for j, k in pairs(pStats.Inventory[i]) do
			pStats.Inventory[i][j].InvLocation = {i,j}
		end
	end
	takeStats:Fire(pStats,script.Name)
end

---------------------------------------------------------------------------------------------------------------- Performance test

local rtSwitch = Switch() 

:case("Dead", function(list)
	local reason = "Player Died"
	list.player.CharacterAdded:Wait()
	task.wait(.1)
	list.player.Character:MoveTo(Vector3.new(10,10,10))
	return nil, reason
end)	

:case("Pulse",function(list)
	local pStats = sendStats:Invoke(list.player)
	local reason = "Pulse"
	local tickrate = .5	
	-------------------------------------------------------------------------------------------------------------------------------------------- Cultivating Section
	if pStats.States.SpStates.Cultivating then  																			
		local state = pStats.Cultivation.State 
		local speed = pStats.Cultivation.Speed
		pStats.Cultivation.CBase = math.clamp(pStats.Cultivation.CBase + speed*tickrate, 0, 100*math.sqrt(state+1) * ((state+1)*(state+1)))
	end
	-------------------------------------------------------------------------------------------------------------------------------------------- Tribulation Section
	if not pStats.States.SpStates.Tribulating then 																	
		if pStats.Cultivation.CBase == pStats.Cultivation.CBaseMax and not pStats.States.SpStates.TribulationPrep then 
			print("Triggering A")
			pStats.Cultivation.TribulationTimer = .5 -- set back to 100
			pStats.States.SpStates.TribulationPrep = true 
		elseif pStats.Cultivation.CBase == pStats.Cultivation.CBaseMax and pStats.States.SpStates.TribulationPrep and pStats.Cultivation.TribulationTimer <= 0  then
			print("Triggering B")
			pStats.States.SpStates.TribulationPrep = false
			pStats.States.SpStates.Tribulating = true 
			takeStats:Fire(pStats,script.Name)
			if pStats.States.SpStates.Cultivating then 
				destroyVfx:Fire("Cultivation".."Basic",{["Player"] = list.player},true)
			end
			tEvent:Fire(pStats,list.player)
			print("WE GOT PAST")
			pStats = sendStats:Invoke(list.player)
		elseif pStats.Cultivation.CBase == pStats.Cultivation.CBaseMax and pStats.States.SpStates.TribulationPrep  then
			print("Triggering 3")
			pStats.Cultivation.TribulationTimer -= tickrate -- .5 because you do this twice in one second
		end
	end
	-------------------------------------------------------------------------------------------------------------------------------------------- Buffs Section
	for i, v in pairs(pStats.States.Buffs) do --- buff Checks Run this over for the diabling and stuff cause that don't look right...
			if v.Duration > 0 then 
				v.Duration -= tickrate --.5 because we do this twice a second
			elseif v.Duration == -1 then 
				continue
			else
				if v.Finality then 
					print("Disabling", i, script.Name)
					pStats = disableBuff:Invoke(v,pStats) --Run this over for the diabling and stuff cause that don't look right...
				end
				print("Removing", i, script.Name)
				pStats = removeBuff:Invoke(v,pStats)
			end 
		end
	-------------------------------------------------------------------------------------------------------------------------------------------- Combat Section
	pStats.States.InCombat.Duration = math.clamp(pStats.States.InCombat.Duration - tickrate, 0, 360) -- the longest you can be in combat is a healthy 6 f'ing minutes --.5 because we do this twice a second
	if pStats.States.InCombat.Duration == 0 then 
		pStats.States.InCombat.Value = false
		cCE:FireClient(list.player,"InCombat",pStats.States.InCombat.Value) -- don't try to optimize this it's an if statement either way with the way you have it right now
	end

	pStats.Block.Cooldown = math.clamp(pStats.Block.Cooldown -tickrate,0,3) 
		
	if pStats.Block.Cooldown == 0 then
		pStats.Block.Current = pStats.Block.Max
	end
		
	-------------------------------------------------------------------------------------------------------------------------------------------- Qi Section 	
	pStats.Qi.Current = math.clamp(pStats.Qi.Current + pStats.Qi.Regen * tickrate, 0, pStats.Qi.Max)
	-------------------------------------------------------------------------------------------------------------------------------------------- Health Section		
	pStats.Health.Current = math.clamp(pStats.Health.Current + pStats.Health.Regen*tickrate,0,pStats.Health.Max) -- this is vital so that the combat controller works the .5 is because you fire every .5

	list.player.Character.Humanoid.Health = pStats.Health.Current
	return pStats,reason
end)
----------------------------------------------------------------------------------------------------------------
rEvent.Event:Connect(function(key,player) --For things that regenerate over a certain interval in seconds up until the player dies 
	local pStats,reason= rtSwitch(key,{
		["player"] = player,})
	if not pStats then return end
	--------------------------------------------------------------------------------------------------------------------------------------------
	pStats = CheckAchievements:Invoke(player,pStats)	-- Achievement Checks
	--------------------------------------------------------------------------------------------------------------------------------------------
	takeStats:Fire(pStats,script.Name,reason)
end)
---------------------------------------------------------------------------------------------------------------- Stat chnge section

local sREventSwitch = Switch()

:case("QiIncrement", function(list) --key, value1, player, value2
	if (list.value1 == 0) then 
		list.pStats.Qi.Current *= list.value1 -- reset qi here if the value is 0  
	else
		list.pStats.Qi.Current += list.value1-- Otherwise just add the value even if it's negative
	end 
	return list.pStats
end)
:case("QiDamage", function(list) --key, value1, player, value2
	if (list.value1 == 0) then 
		list.pStats.Damage.Qi*= list.value1 -- reset qi here if the value is 0  
	else
		list.pStats.Damage.Qi += list.value1-- Otherwise just add the value even if it's negative
	end 
	return list.pStats
end)
:case( "QiDefense",function(list)
	list.pStats.Defense.Qi += list.value1
	--list.pStats = augStats:Invoke(list.key,list.pStats,list.player) -- not necessary I don't think but we'll see
	return list.pStats
end)
:case( "PhysicalDefense",function(list)
	list.pStats.Defense.Physical += list.value1
	--list.pStats = augStats:Invoke(list.key,list.pStats,list.player) -- not necessary I don't think but we'll see
	return list.pStats
end)
:case("HealthIncrement", function(list) --key, value1, player, value2
	if (list.value1 == 0) then 
		list.pStats.Health.Current *= list.value1 -- reset qi here if the value is 0  
	else
		list.pStats.Health.Current += list.value1-- Otherwise just add the value even if it's negative
	end 
	return list.pStats
end)
:case("MaxHealthIncrement", function(list) --key, value1, player, value2
	if (list.value1 == 0) then 
		list.pStats.Health.Max *= list.value1 -- reset qi here if the value is 0  
	else
		list.pStats.Health.Max += list.value1-- Otherwise just add the value even if it's negative
	end 
	return list.pStats
end)
:case("CBaseIncrement", function(list) --key, value1, player, value2
	if (list.value1 == 0) then 
		list.pStats.Cultivation.CBase *= list.value1 -- reset qi here if the value is 0  
	else
		list.pStats.Cultivation.CBase += list.value1-- Otherwise just add the value even if it's negative
	end 
	return list.pStats
end)
:case("Path",function(list) -- might be depreicated sooner rather than later.
	list.pStats.Paths.Path[list.value2] = list.value1
	return list.pStats
end)
:case("Strength",function(list)
	list.pStats.AugmentingStats[list.key] += list.value1
	list.pStats = augStats:Invoke(list.key,list.pStats,list.player)
	return list.pStats
end)
:case( "Intelligence",function(list)
	list.pStats.AugmentingStats[list.key] += list.value1
	list.pStats = augStats:Invoke(list.key,list.pStats,list.player)
	return list.pStats
end)
:case( "Dexterity" ,function(list)
	list.pStats.AugmentingStats[list.key] += list.value1
	list.pStats = augStats:Invoke(list.key,list.pStats,list.player)
	return list.pStats
end)
:case("Vitality",function(list)
	list.pStats.AugmentingStats[list.key] += list.value1
	list.pStats = augStats:Invoke(list.key,list.pStats,list.player)
	return list.pStats
end)
:case( "Intelligence",function(list)
	list.pStats.AugmentingStats[list.key] += list.value1
	list.pStats = augStats:Invoke(list.key,list.pStats,list.player)
	return list.pStats
end)
:case("Temperature",function(list)
	list.pStats.Temperature = list.value1
	return list.pStats
end)

sREvent.Event:Connect(function(key, value1, player, value2) --Used for incrementing/decrementing/replacing stats for the player.
	local pStats = sendStats:Invoke(player)
	pStats = sREventSwitch(key,{
		["key"] = key,
		["pStats"] = pStats,
		["player"] = player,
		["value1"] = value1,
		["value2"] = value2,	
	})
	takeStats:Fire(pStats,script.Name,"Stat change")
end)

---------------------------------------------------------------------------------------------------------------- Aug stat change section
local augStatsSwitch = Switch()

:case("Strength",function(list)
	print("Scailing Physical Damage")
	local Strength = list.pStats.AugmentingStats.Strength
	list.pStats.Damage.Physical = 1 + (math.sqrt(Strength)*math.log10(Strength))
	return list.pStats
end)
:case("Intelligence",function(list)
	print("Scailing Qi Defense")
	local Intelligence = list.pStats.AugmentingStats.Intelligence
	list.pStats.Defense.Qi = 1 + (math.sqrt(Intelligence)*math.log10(Intelligence))
	return list.pStats
end)
:case("Dexterity",function(list)
	print("Scailing speed")
	local Dexterity = list.pStats.AugmentingStats.Dexterity
	if Dexterity < 40 then --softcap for dexterity is 40
		list.player.Character.Humanoid.WalkSpeed = 16 + math.floor(math.sqrt(Dexterity))
	else
		list.player.Character.Humanoid.WalkSpeed = 16 + math.floor(math.log10(Dexterity))
	end
	return list.pStats
end)
:case("Vitality",function(list)
	print("Scailing Health")
	local Vitality = list.pStats.AugmentingStats.Vitality
	list.pStats.Health.Max = 100+math.floor(3.95*(math.sqrt(Vitality)*5*math.log10(Vitality)))
	list.pStats.Health.Regen = 1+(.1*(math.sqrt(Vitality)*2*math.log10(Vitality)))
	list.player.Character.Humanoid.MaxHealth = list.pStats.Health.Max
	print(list.pStats)
	return list.pStats
end)

augStats.OnInvoke = function(key,pStats,player) -- you can add other things to these equations such as items and status effects later on. You can have this trigger the combat controller and have the calculations fod debuffs happen afterwards!
	
	for i, v in pairs(pStats.States.Buffs) do -- nullify the buffs that are already on you
		pStats = nullifyBuff:Invoke(v,pStats)
	end

	pStats = augStatsSwitch(key,{ -- update and increase the stat that was given 
		["pStats"] = pStats,
		["player"] = player,
	})
	--[[ NOTE TO SELF: You gotta recalculate literally all the stats before you apply the buff stuff because it will stack on top of itself incorrectly 
	if you don't keep this in mind.
	]]

	pStats = TalentEffected(pStats.Talent,pStats) -- recalculate the things  related to talent

	pStats = stFunction:Invoke(pStats) -- add the buffs back to the calculation
	return(pStats)
end
---------------------------------------------------------------------------------------------------------------- Combat section

local dodgeTable = { -- these values need some fine tuning but for now they're fine
	DodgeLeft = 2.3,
	DodgeRight = 2.3,
	DodgeForward = 2.3,
	DodgeBack = 2.8,
	Multiplier = 5
}

function dodgeFunction(creature,direction,dodgeTime,dodgeName,npc)
	local pStats
	local Character
	local velocity = dodgeTable[dodgeName]*dodgeTable.Multiplier *.85 * math.log10(dodgeTable.Multiplier)
	dodgeTime = dodgeTime/dodgeTable.Multiplier
	
	if npc then 
		Character = creature
		pStats = require(game.ServerScriptService.CurrentNpcConfigs[creature.Name.."Config"]) 
	else
		Character = creature.Character
		pStats = sendStats:Invoke(creature)
		pStats.States.SpStates.Dodging = true
		takeStats:Fire(pStats)
	end
	
	for i, v in pairs(Character:GetDescendants()) do
		if v:isA("MeshPart") then 
			v.Massless = true
		end
	end
	
	if Character.Humanoid:GetState() == Enum.HumanoidStateType.Freefall then 
		velocity *= .675
	end
	
	local primaryPart 	= Character.PrimaryPart
	local attatchment = Instance.new("Attachment")
	attatchment.Position  = Vector3.new(0,0,0)
	attatchment.Parent = Character.PrimaryPart
	
	local x = Instance.new("BodyVelocity")
	
	x.MaxForce 	= Vector3.new(10000,10000,10000)
	x.P 		= 2000
	x.Velocity	= direction*Vector3.new(velocity ,0,velocity) 
	x.Parent	= Character.HumanoidRootPart
	
	DebrisService:AddItem(attatchment,dodgeTime)
	DebrisService:AddItem(x,dodgeTime)
	
	task.wait(dodgeTime)
	
	if npc then 
		if pStats.States.SpStates.Dodging then -- this should be fine because even if you're hit by an undodgable attack you're still going to have the cooldown to serve as a buffer so this will always fire before they have a chance to dodge again.
			pStats.States.SpStates.Dodging = false
		end
	else
		pStats = sendStats:Invoke(creature)
		if pStats.States.SpStates.Dodging then -- this should be fine because even if you're hit by an undodgable attack you're still going to have the cooldown to serve as a buffer so this will always fire before they have a chance to dodge again.
			pStats.States.SpStates.Dodging = false
		end
		takeStats:Fire(pStats)
	end

	for i, v in pairs(Character:GetDescendants()) do
		if v:isA("MeshPart") then 
			v.Massless = false
		end
	end
end

npcDodge.Event:Connect(function(npc,direction,dodgeTime,dodgeName)
	print("Has been fired")
	dodgeFunction(npc,direction,dodgeTime,dodgeName,true)
end)

Dodge.OnServerEvent:Connect(function(player,direction,dodgeTime,dodgeName)
	dodgeFunction(player,direction,dodgeTime,dodgeName,false)
end)


-------------------------------------------------- Simple DayNightCycle
local tickrate = 60 -- 1 min = 1 hour
local startTime = 9 -- 9am

local minutesAfterMidnight = tickrate * 60
local waitTime = 60 / tickrate

while true do
	minutesAfterMidnight = minutesAfterMidnight + 1

	Lighting:SetMinutesAfterMidnight(minutesAfterMidnight)

	task.wait(waitTime)
end
