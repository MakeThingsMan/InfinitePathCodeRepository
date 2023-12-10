local Players					= game:GetService("Players")
local CollectionService			= game:GetService("CollectionService")
local damageClass  				= require(game.ServerScriptService.CombatController.DamageClass)
local HitboxClass			 	= require(game.ServerScriptService.CombatController.HitboxClass)
local ss 						= game.ServerStorage:WaitForChild("SendStats")
local ts 						= game.ServerStorage:WaitForChild("TakeStats")
local cEvent 					= game.ServerStorage:WaitForChild("CombatEvent")
local ResourceHit				= game.ServerStorage:WaitForChild("ResourceHit")
local NpcHitboxHandler			= game.ServerStorage:WaitForChild("NpcHitboxHandler")
local sendStats					= game.ServerStorage:WaitForChild("SendStats")

local cCE						= game.ReplicatedStorage:WaitForChild("ClientCombatEvent")
local stunPlayer				= game.ReplicatedStorage:WaitForChild("StunPlayer")
--local pcEvent  					= game.ReplicatedStorage:WaitForChild("PCombatEvent")
local HitboxHandler 			= game.ReplicatedStorage:WaitForChild("HitboxHandler")
local PositionHitbox			= game.ReplicatedStorage:WaitForChild("PositionHitbox")
local StoppedAttacking			= game.ReplicatedStorage:WaitForChild("StoppedAttacking")
local UpdateStunValue			= game.ReplicatedStorage:WaitForChild("UpdateStunValue")


local stunnedPlayers			= {}

script.Parent:WaitForChild("DataController")

function visualizeHitbox(hitbox,Hrp,radial)
	task.spawn(function()
		local visual 	= Instance.new("Part")
		
		if radial then 
			visual.Size	= Vector3.new(5,hitbox,hitbox)
			visual.Orientation	= Vector3.new(0,0,90) 
			visual.Shape= Enum.PartType.Cylinder
		else
			visual.Size = hitbox.Size
		end
		visual.CFrame 	= Hrp.CFrame:ToWorldSpace(CFrame.new(Vector3.new(0,-.5,-2)))  --hitbox.CFrame:ToWorldSpace(CFrame.new(Hrp.CFrame.Position+Vector3.new(0,0,1),Hrp.CFrame.LookVector))
		visual.Anchored = true
		visual.Color	= Color3.new(1, 0.333333, 0.109804)
		visual.Transparency = .8
		visual.CanCollide = false
		visual.CanQuery = false
		visual.CanTouch = false
		visual.Parent	= workspace
		task.wait(1)
		visual:Destroy()
	end)
end

function IsLookingAtPlayer(target,other)
	local playerPosition						=  target.HumanoidRootPart.Position

	local rayOrigin 							=  other.HumanoidRootPart.Position 
	-- this section looks to see if you are in front of the npc or not 

	local targetCFrame = target.HumanoidRootPart.CFrame
	local TargetCoordinates = other.HumanoidRootPart.CFrame:ToObjectSpace(targetCFrame)

	--local x = otherTest.Position.X
	local y = TargetCoordinates.Position.Y
	local z = TargetCoordinates.Position.Z
	return z*-1>0 and -10<y and y<10 -- the times -1 is for my sanity dw about it.
end

cEvent.Event:Connect(function(defender,Attack,aggressor)
	--[[
	Damage will just be a number.
	Proportion will be the proportion of the damage that is physical vs Qi based.
	eStack is the elements that compose the damage. Certain elements will do more damage to the player based off the element the players Qi is. 
	Armor pen is the amount of damage that will peirce through defense.
	]]
	local pStats = ss:Invoke(defender)
	local savedHealth = pStats.Health.Current
	if aggressor then
		Attack.InFrontOfDefender = IsLookingAtPlayer(defender.Character,aggressor)
	end
	pStats = damageClass.Apply(Attack,pStats)
	
	pStats.States.InCombat.Value = true
	pStats.States.InCombat.Duration += math.ceil((savedHealth-pStats.Health.Current)/10)
	pStats.States.SpStates.Stunned = true 
	cCE:FireClient(defender,"InCombat",true) -- turns on the players in combat gui
	stunPlayer:FireClient(defender,Attack.HitStun)
	UpdateStunValue:FireClient(defender,true)
	stunnedPlayers[defender.Name] = {} -- add the player to the stunned players list
	stunnedPlayers[defender.Name].Timer = Attack.HitStun
	stunnedPlayers[defender.Name].Handled = false
	ts:Fire(pStats,script.Name)
end)

StoppedAttacking.OnServerEvent:Connect(function(player)
	local pStats = sendStats:Invoke(player)
	print("That boy stopped attacking already!")
	pStats.States.SpStates.Attacking = false
	ts:Fire(pStats)
end)

HitboxHandler.OnServerEvent:Connect(function(player,Hitbox,slot)
	local HitboxParams = OverlapParams.new()
	HitboxParams.MaxParts = 10
	HitboxParams.RespectCanCollide = false
	HitboxParams.FilterDescendantsInstances = player.Character:GetDescendants()
	local pStats = sendStats:Invoke(player)
	pStats.States.SpStates.Attacking = true 
	ts:Fire(pStats,script.Name,"You're attacking")
	-- if having the player send the slot ends up being a problem you could just have the server send the saved stats and check the slot from there. 
	-- pretty much leaving the player to only send the slot that they want to calculate  
	local peopleHit 	= {}
	local resourcesHit	= {}
	local personHumanoid
	local hrp = player.Character.HumanoidRootPart
	visualizeHitbox(Hitbox,hrp)
	--local Touching = workspace:GetPartBoundsInBox(CFrame.new(hrp.Position+hrp.CFrame.LookVector * (Hitbox.Size.Z/2),hrp.CFrame.LookVector),Hitbox.Size,HitboxParams)--workspace:GetPartsInPart(Hitbox,params)
	local Touching = workspace:GetPartBoundsInBox(hrp.CFrame:ToWorldSpace(CFrame.new(Vector3.new(0,-.5,-2))),Hitbox.Size,HitboxParams)
	for i, v in pairs(Touching) do 
		local x = v.Parent:FindFirstChildWhichIsA("Humanoid") 
		if x then 
			personHumanoid = x
			if not table.find(peopleHit,personHumanoid) then
				table.insert(peopleHit,personHumanoid)
			end
		elseif CollectionService:HasTag(v.Parent,"ResourceNode") then
			if not table.find(resourcesHit,v.Parent) then
				table.insert(resourcesHit,v.Parent)
				ResourceHit:Fire(v.Parent,player,slot.ToolType)
			end 
	 	end
	end
	--print(peopleHit, " People hit")
	local Attack = slot.Damage
	for i, v in pairs(peopleHit) do 
		if v.Name == "NpcHumanoid" then 
			--print("We got in")
			local npcstats = require(game.ServerScriptService.CurrentNpcConfigs[v.Parent.Name.."Config"] )
			--print(npcstats,personHumanoid)
			--npcstats = npcstats.GiveData()
			Attack.InFrontOfDefender = IsLookingAtPlayer(v.Parent,player.Character)
			damageClass.Apply(Attack,npcstats,personHumanoid)
		else
			cEvent:Fire(Players[v.Parent.Name],Attack,player)
		end
	end
end)

NpcHitboxHandler.Event:Connect(function(npc,Hitbox,Attack)
	local HitboxParams = OverlapParams.new()
	HitboxParams.MaxParts = 10
	HitboxParams.RespectCanCollide = false
	HitboxParams.FilterDescendantsInstances = npc:GetDescendants()
	print("Hitboxing!",Attack.Name)
	local peopleHit 	= {}
	local personHumanoid
	local hrp = npc.HumanoidRootPart
	visualizeHitbox(Hitbox,hrp,Attack.Radial)
	
	local Touching 
	if Attack.Radial then -- this may cause problems in the future idk.
		Touching = workspace:GetPartBoundsInRadius(hrp.CFrame:ToWorldSpace(CFrame.new(Vector3.new(0,-.5,-2))).Position,Hitbox,HitboxParams)
	else
		Touching = workspace:GetPartBoundsInBox(hrp.CFrame:ToWorldSpace(CFrame.new(Vector3.new(0,-.5,-2))),Hitbox.Size,HitboxParams)--workspace:GetPartsInPart(Hitbox,params)
	end

	for i, v in pairs(Touching) do 
		local x =v.Parent:FindFirstChildWhichIsA("Humanoid") 
		if x then 
			personHumanoid = x
			if not table.find(peopleHit,personHumanoid) then
				table.insert(peopleHit,personHumanoid)
			end
		end
	end
	for i, v in pairs(peopleHit) do 
		if v.Name == "Humanoid" then 
			--print("We got in with the npc")
			cEvent:Fire(Players[v.Parent.Name],Attack,npc)
		else
			local npcstats = require(game.ServerScriptService.CurrentNpcConfigs[v.Parent.Name.."Config"])
			print(npcstats,personHumanoid)
			npcstats = npcstats.GiveData()
			Attack.InFrontOfDefender = IsLookingAtPlayer(v.Character,npc)
			damageClass.Apply(Attack,npcstats,personHumanoid)
		end
	end
end)

PositionHitbox.OnServerEvent:Connect(function(player,hitbox,part)
	HitboxClass.FindPosition(hitbox,part)
end)

while task.wait() do  -- resets the players stunned value
	for i, v in pairs(stunnedPlayers) do
		if v.Handled == false then 
			task.spawn(function()
				v.Handled = true
				task.wait(v.Timer)
				local pStats = sendStats:Invoke(Players[i])
				pStats.States.SpStates.Stunned = false
				UpdateStunValue:FireClient(Players[i],false)
				ts:Fire(pStats)
				pStats = nil -- this is here just cause idk if they havea proper garbage collector but it shouldn't need to be used. Just in case there's a memory leak cauese by this honestly.
				stunnedPlayers[i] = nil	
			end)
		end
	end
end

