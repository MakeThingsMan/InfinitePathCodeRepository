--[[
Note to self on v4: NEVER LET THE CURRENT COMBAT STATE BE "" IF YOU ARE IN COMBAT 
IT WILL ALLOW THE COMBAT CONTROLLER TO OCCUR MORE THAN ONCE AND BLOW THE UP
Patrolling is extremely efficient you just need to not be printing something 20 times a second yk?
]]
-- possible states: {"Patrolling","Targetting","Fighting","Attacking","Blocking","Dodging","Idle","Stunned","Stationary"}
------------------------------------- V4 ----------------------------------------- V4 ---------------------------------------
local pfs 							= game:GetService("PathfindingService")
local Players 						= game:GetService("Players")
local NpcHitboxHandler				= game.ServerStorage:WaitForChild("NpcHitboxHandler")
local getPlayersInRegion 			= game.ServerStorage:WaitForChild("GetPlayersInRegion")
local summonVfx 					= game.ServerStorage:WaitForChild("SummonVfx")
local sendStats						= game.ServerStorage:WaitForChild("SendStats")
local summonWeldedVfx				= game.ServerStorage:WaitForChild("SummonWeldedVfx")
local destroyVfx					= game.ServerStorage:WaitForChild("DestroyVfx")
local npcDodge						= game.ServerStorage:WaitForChild("NpcDodge")
local NpcSkillUse					= game.ServerStorage:WaitForChild("NpcSkillUse")
local screenShake					= game.ReplicatedStorage:WaitForChild("ScreenShake")
local StunPlayer					= game.ReplicatedStorage:WaitForChild("StunPlayer")
local config						= require(script.Parent.NpcConfig)
local Switch						= require(game.ServerScriptService.Switch)
local optimizedPlayerTable			= require(game.ServerScriptService.DataController.PlayerTableUpdater)
local npc 							= script.Parent


script.Parent.NpcConfig.Name		= npc.Name.."Config"
script.Parent[npc.Name.."Config"].Parent = game.ServerScriptService.CurrentNpcConfigs

npc.PrimaryPart:SetNetworkOwner(nil)
local humanoid						= script.Parent:WaitForChild("NpcHumanoid")
local animator						= humanoid.Animator
local loadedAnimations				= {}


--------------------------------------------------------------------------------------- Movement Section
local trueTarget					= {
	Name = "",
	Distance = config.searchRadius*2
}
local currentPatrolNode 			= 1 
local patrolWaypoints				= config.assignedPatrolPath:GetChildren()
local lastPosition				 	= npc.HumanoidRootPart.Position

local pathParams 					= {
	["AgentHeight"] = config.characterHeight;
	["AgentRadius"] = 2;
	["AgentCanJump"] = true,
	--["WaypointSpacing"] = 5
}

local path = pfs:CreatePath(pathParams)

function FindPlayer()
	--print("Finding a target!")
	if trueTarget.Name ~= "" and Players[trueTarget.Name].Character.Humanoid.Health > 0 then -- If you already have a predetermined target 
		local distance =   npc.HumanoidRootPart.Position - Players[trueTarget.Name].Character.HumanoidRootPart.Position -- check if they're in bounds
		--print(distance.Magnitude, "Distance from the find player function")
		if distance.Magnitude <= config.maxRadius then 
			trueTarget.Distance = distance.Magnitude
			return trueTarget -- if they are in bounds then you return the target otherwise continue searching for the rest of the players in the zones you're allowed to search in 
		else 
			trueTarget.Name = ""
			trueTarget.Distance = config.searchRadius*3 -- make it out of range
		end
	end

	trueTarget = closestPlayer()
	--print(trueTarget.Distance)
	return trueTarget
end

function playersInArea(radius) 
	local inArea = {}
	for i, v in pairs(config.regions) do -- get the availabile players in the regions that you're allowed to check
		local targetablePlayersInRegion = getPlayersInRegion:Invoke(v)
		for i, v in pairs(targetablePlayersInRegion) do 
			local distance = (v.Character.HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude
			if distance <= radius then 
				table.insert(inArea,v) -- add the ones that are in bounds to the list of players 
			end
		end
	end
	return inArea
end

function closestPlayer()
	for i, v in pairs(config.regions) do -- get the availabile players in the regions that you're allowed to check
		local targetablePlayersInRegion = getPlayersInRegion:Invoke(v)
		--if targetablePlayersInRegion == nil then return end
		for i, v in pairs(targetablePlayersInRegion) do 
			local success, distance = CheckInBounds(v) -- check to see which ones are in bounds
			if success and distance < trueTarget.Distance and Players[v.Name].Character.Humanoid.Health > 0  then 
				trueTarget.Name = v.Name 
				trueTarget.Distance = distance
				--table.insert(targets,{v.Name,distance})  -- add the ones that are in bounds to the list of players 
			end
		end
	end
	return trueTarget
end

function closestPlayerByDistance()
	for i, v in pairs(config.regions) do -- get the availabile players in the regions that you're allowed to check
		local targetablePlayersInRegion = getPlayersInRegion:Invoke(v)
		--if targetablePlayersInRegion == nil then return end
		for i, v in pairs(targetablePlayersInRegion) do 
			local distance = (npc.HumanoidRootPart.Position  - v.Character.HumanoidRootPart.Position).Magnitude  -- check to see which ones are in bounds
			if distance < trueTarget.Distance then 
				trueTarget.Name = v.Name 
				trueTarget.Distance = distance
				--table.insert(targets,{v.Name,distance})  -- add the ones that are in bounds to the list of players 
			end
		end
	end
	return trueTarget
end

function IsLookingAtPlayer(player) -- fix this in the morning bruh
	-- this section looks to see if you are in front of the npc or not 
	-- the filter returns true if you're in front of the npc and false if you're not
	local test = player.Character.HumanoidRootPart.CFrame
	local otherTest = npc.HumanoidRootPart.CFrame:ToObjectSpace(test)

	--local x = otherTest.Position.X
	local y = otherTest.Position.Y
	local z = otherTest.Position.Z
	return z*-1>0 and -10<y and y<10 -- the times -1 is for my sanity dw about it.
end

function CheckInBounds(player) -- if the npc is going to be in an area with a bunch of things that could potentially obstruct it's view of the player then you should add the raycast
	local playerPosition						=  player.Character.HumanoidRootPart.Position
	local origin 								=  npc.HumanoidRootPart.Position 
	if not IsLookingAtPlayer(player) then return end
	local distance								= origin-playerPosition
	return distance.Magnitude <= config.searchRadius*.5 and math.abs(distance.Y) <= config.characterHeight, distance.Magnitude
end

function visualize()

	local SearchRadius 			= Instance.new("Part")
	local weld 					= Instance.new("Weld")
	SearchRadius.CanCollide 	= false
	SearchRadius.CanQuery		= false
	SearchRadius.CanTouch		= false
	SearchRadius.Anchored		= false
	SearchRadius.Transparency	= .8
	weld.Enabled				= false
	SearchRadius.Color			= Color3.new(0.705882, 0.117647, 1)
	SearchRadius.Position		= npc.HumanoidRootPart.Position
	SearchRadius.Shape 			= Enum.PartType.Cylinder
	SearchRadius.Size			= Vector3.new(config.characterHeight,config.searchRadius,config.searchRadius)
	weld.Part0					= SearchRadius
	weld.Part1					= npc.PrimaryPart
	weld.Parent					= npc.HumanoidRootPart
	SearchRadius.Parent			= workspace
	SearchRadius:SetNetworkOwner(nil)
	weld.Enabled		= true

	local Long 			= Instance.new("Part")
	local weld 			= Instance.new("Weld")
	Long.Transparency	= .8
	Long.CanCollide 	= false
	Long.CanQuery		= false
	Long.CanTouch		= false
	Long.Anchored		= false
	Long.Color			= Color3.new(1, 0.0470588, 0.270588)
	Long.Position		= npc.HumanoidRootPart.Position
	Long.Shape 			= Enum.PartType.Cylinder
	Long.Size			= Vector3.new(config.characterHeight,config.Range.Long,config.Range.Long)
	weld.Part0			= Long
	weld.Part1			= npc.PrimaryPart
	weld.Parent			= npc.HumanoidRootPart
	Long.Parent			= workspace
	Long:SetNetworkOwner(nil)

	local Medium 		= Instance.new("Part")
	local weld 			= Instance.new("Weld")
	Medium.Transparency	= .8
	Medium.CanCollide 	= false
	Medium.CanQuery		= false
	Medium.CanTouch		= false
	Medium.Anchored		= false
	Medium.Color		= Color3.new(1, 0.760784, 0.2)
	Medium.Position		= npc.HumanoidRootPart.Position
	Medium.Shape 		= Enum.PartType.Cylinder
	Medium.Size			= Vector3.new(config.characterHeight,config.Range.Medium,config.Range.Medium)
	weld.Part0			= Medium
	weld.Part1			= npc.PrimaryPart
	weld.Parent			= npc.HumanoidRootPart
	Medium.Parent		= workspace
	Medium:SetNetworkOwner(nil)

	local Short 		= Instance.new("Part")
	local weld 			= Instance.new("Weld")
	Short.Transparency	= .8
	Short.CanCollide 	= false
	Short.CanQuery		= false
	Short.CanTouch		= false
	Short.Anchored		= false
	Short.Color			= Color3.new(0.145098, 1, 0.529412)
	Short.Position		= npc.HumanoidRootPart.Position
	Short.Shape 		= Enum.PartType.Cylinder
	Short.Size			= Vector3.new(config.characterHeight,config.Range.Short,config.Range.Short)
	weld.Part0			= Short
	weld.Part1			= npc.PrimaryPart
	weld.Parent			= npc.HumanoidRootPart
	Short.Parent		= workspace
	Short:SetNetworkOwner(nil)
end

function isVfxPresent(vfxName,data)
	local success, failure = pcall(function()
		local found = workspace.TemporaryVFX[vfxName..npc.Name]
	end)
	return success
end

local waypoints
local nextWaypointIndex
local reachedConnection
local blockedConnection

local function followPath(destination,continuous)
	local start = tick()
	--print("We're in the follow path", config.currentState, config.currentCombatState)
	
	while config.currentCombatState == "Attacking" or config.currentCombatState == "Blocking" or config.currentCombatState == "Dodging" do --this is a failsafe in case you're attacking for too long. This shouldn't really ever fire but idk yet.
		task.wait()
		if tick() - start > 3 then 
			print("So could this one honestly")
			config.currentCombatState = "Fighting"
		end
	end

	while config.currentCombatState == "Stunned" do -- you wait to move if you're stunned instead of just returning.
		task.wait()
	end
	
	-- Compute the path
	local success, errorMessage = pcall(function()
		while jumping do task.wait(.1) end
		path:ComputeAsync(npc.HumanoidRootPart.Position, destination)
	end)
	
	if success and path.Status == Enum.PathStatus.Success then
		-- Get the path waypoints
		waypoints = path:GetWaypoints()

		-- Detect if path becomes blocked
		blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
			-- Check if the obstacle is further down the path
			if blockedWaypointIndex >= nextWaypointIndex then
				-- Stop detecting path blockage until path is re-computed
				--blockedConnection:Disconnect()
				blockedConnection = nil
				--pathBlocked = blockedWaypointIndex
				-- Call function to re-compute new path
				followPath(destination)
				return
			end
		end)

		--Detect when movement to next waypoint is complete
		if not reachedConnection then
			reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
				--print "Triggering the reached connection thing"
				if reached and nextWaypointIndex < #waypoints then
					-- Increase waypoint index and move to next waypoint
					nextWaypointIndex += 1
					moveToPoint(waypoints,nextWaypointIndex)
				else
					if continuous then 
						loadedAnimations.Walk:Stop()
					elseif not continuous and trueTarget ~= "" then
						--print("Ik its not this bruh")
						loadedAnimations.Run:Stop()
					end
					config.currentState = "Idle"
					reachedConnection:Disconnect()
					blockedConnection:Disconnect()
					reachedConnection = nil
					blockedConnection = nil
				end
			end)
		end

		-- Initially move to second waypoint (first waypoint is path start; skip it)
		nextWaypointIndex = 2
		moveToPoint(waypoints,nextWaypointIndex)
		if not continuous then 
			config.currentState = "Targetting"
		end		
	else
		warn("Path not computed!", errorMessage)
	end
	return 
end

function moveToPoint(waypoints,nextwaypointIndex)
	if waypoints[nextwaypointIndex].Action == Enum.PathWaypointAction.Jump then 
		humanoid.Jump = true
	end
	humanoid:MoveTo(waypoints[nextwaypointIndex].Position)
end

function patrolPath()
	config.currentState = "Patrolling"
	humanoid.WalkSpeed = 8
	loadedAnimations.Walk:Play()
	loadedAnimations.Walk.Looped = true
	followPath(patrolWaypoints[currentPatrolNode].Position + config.assignedPatrolPath.Position,true)
	currentPatrolNode+=1
	if currentPatrolNode > #patrolWaypoints then 
		currentPatrolNode = 1
	end
end

humanoid.StateChanged:Connect(function(old,new)
	if old == Enum.HumanoidStateType.Jumping then 
		jumping = true
	end
	if old == Enum.HumanoidStateType.Landed then 
		jumping = false
	end
end)

--------------------------------------------------------------------------------------- Movement Section End

--------------------------------------------------------------------------------------- Animation Section
function loadAnimations()
	for i, v in pairs(config.animations) do
		local x = Instance.new("Animation")
		x.AnimationId =  v
		x.Name 		  =  i
		loadedAnimations[i] = animator:LoadAnimation(x)
	end 
end

function isAnimationPlaying(AnimationToFind)
	--print(animator:GetPlayingAnimationTracks())
	for i, v in pairs(animator:GetPlayingAnimationTracks()) do
		if v.Name == AnimationToFind then 
			--print(v.Name, " is running!")
			return true 
		end
	end
	return false
end

loadAnimations()

--------------------------------------------------------------------------------------- Animation Section End

--------------------------------------------------------------------------------------- Combat Section

function swings()
	local swingDelay = .2
	for i=1, config.MaxSwings,1 do 
		local distance = (npc.HumanoidRootPart.Position - Players[trueTarget.Name].Character.HumanoidRootPart.Position).Magnitude
		--print(distance, "vs", trueTarget.Distance)
		if not config.debounce and distance <= config.Range.Short and config.currentCombatState ~= "Dodging" and config.currentCombatState ~= "Blocking" and not config.States.SpStates.Blocking then
			--print(trueTarget.Distance, "From the swinging thing things")	
			--print("Swinging!", config.swing)
			config.debounce = true 	
			config.currentCombatState = "Attacking"
			loadedAnimations.Idle:Stop()
			loadedAnimations["Swing"..config.swing]:Play()
			local damaging = loadedAnimations["Swing"..config.swing]:GetMarkerReachedSignal("Damage"):Connect(function()
				--print("We got into the damaging thing!")
				local hitbox = game.ServerStorage.PremadeHitboxes[config.Hitboxes["Swing"..config.swing]] 
				NpcHitboxHandler:Fire(npc,hitbox,config.Damage["Swing"..config.swing]) -- make sure you change this to be server sided passing in the hitbox
			end)
			task.wait(loadedAnimations["Swing"..config.swing].Length) --or this is where you'd put getting hit
			if config.swing < config.MaxSwings then
				config.swing+=1
				config.lastSwing = config.swing
			else 
				config.swing=1
				if loadedAnimations.Recovery ~= nil then  -- not everything needs to have a recovery so this will take care of that issue
					loadedAnimations.Recovery:Play()
				end
				task.wait(.1)
			end
			config.debounce = false
			damaging:Disconnect()
		else
			swingDelay = 0
			break
		end
	end
	config.swing = 1
	config.lastSwing = 0
	task.wait(swingDelay) -- give the player some time to counterattack and stuff
	--print("Done Swinging")
end

function combatChoice(input)
	local endResult = {}
	for _, data in pairs(input) do
		for c = 1, data[2], 1 do
			table.insert(endResult, data[1])
		end
	end
	local chosenIndex= math.random(1, #endResult)
	local chosen = endResult[chosenIndex]
	return chosen
end

local combatSwitch = Switch() -- Here you put any and all actions you want the AI to use at the 3 range types.

	:case("Test",function()
		config.currentCombatState = "Attacking"
		task.wait()
	end)

	:case("Skip",function()
		return
	end)

	:case("KhanRoar",function()
		if config.onCooldown.KhanRoar == 0 then 
		config.currentCombatState = "Attacking"
		config.currentState = "Stationary"
		loadedAnimations.KhanRoar:Play()
		local data = {}
		data.Player = npc
		summonVfx:Fire("KhanRoar",npc.HumanoidRootPart.Position,data,false)
		config.onCooldown.KhanRoar = 6	
		task.wait(.2)
		screenShake:FireClient(Players[trueTarget.Name],20)
		for i, v in pairs(playersInArea(config.Range.Medium)) do
			local pstats = sendStats:Invoke(v)
			if not pstats.States.SpStates.Dodging and not pstats.States.SpStates.Blocking then -- makes it blockable and dodgable without stunning the player.
				local Attack 	= config.Damage["KhanRoar"]
				Attack.Radial 	= true
				NpcHitboxHandler:Fire(npc,config.Range.Medium,Attack)
			end
		end
		task.wait(.9)
		screenShake:FireClient(Players[trueTarget.Name],100)
		config.currentState = ""
	end
	end)
	
	:case("Enchant",function()
		if config.onCooldown.Enchant == 0 then
		--print("Enchanting!")
		loadedAnimations.Run:Stop()
		loadedAnimations.Walk:Stop()
		config.onCooldown.Enchant += 40 -- make it last 20 seconds
		config.currentCombatState = "Attacking"
		config.currentState = "Stationary"
		loadedAnimations.Enchant.Priority = Enum.AnimationPriority.Action2
		loadedAnimations.Enchant:Play()
		loadedAnimations.Enchant:GetMarkerReachedSignal("Vfx"):Connect(function()
			--print("into the summon vfx function")
			NpcSkillUse:Fire(npc,"KhanLightningEnchant",npc.EliteArmor.Weapon.BladeBody.Position)
			npc.EliteArmor.Weapon.Edge.Color = Color3.new(0.854902, 0.52549, 0.478431)
			npc.EliteArmor.Weapon.BigGem.Color =  Color3.new(0.854902, 0.52549, 0.478431)
			npc.EliteArmor.Weapon.SmallGems.Color =  Color3.new(0.854902, 0.52549, 0.478431)
			npc.EliteArmor.Weapon.Edge.Material = Enum.Material.Neon
			local vfx = "KhanEnchant"
			local pos = npc.EliteArmor.Weapon.BladeBody.Position
			local data= {}
			data.Player = npc
			data.rawObject = npc.EliteArmor.Weapon.BladeBody
			data.EnchantPeriod = 20 -- in seconds
			summonVfx:Fire(vfx,pos,data,false,true) -- this does the enchanted verison of the vfx summon
			config.States.SpStates.Enchanted = true
			config.Damage.Swing1.Damage += 5
			config.Damage.Swing2.Damage += 5
			for i, v in pairs(playersInArea(config.Range.Long)) do
				local pstats = sendStats:Invoke(v)
				if not pstats.States.SpStates.Dodging then -- makes it dodgable without stunning the player.
					local Attack 	= config.Damage["Enchant"]
					Attack.Radial 	= true
					NpcHitboxHandler:Fire(npc,config.Range.Long+2,Attack)
				end
			end
		end)
		task.wait(loadedAnimations.Enchant.Length)
		config.currentState = ""
		end
	end)
	
	:case("Melee",function()
		swings()
	end)

	:default(function() --this is required.
		return
	end)

function fightActionController(playerDistance,choice)
	if playerDistance <= config.Range.Short then 
		--print("Player short range")
		choice = combatChoice(config.RangeTable.Short)
	elseif playerDistance <= config.Range.Medium and playerDistance > config.Range.Short then
		--print("Player medium range")
		choice = combatChoice(config.RangeTable.Med)
	elseif playerDistance <= config.Range.Long and playerDistance > config.Range.Medium then
		--print("Player long range")
		choice = combatChoice(config.RangeTable.Long)
		choice = "Skip" -- this is because this is a medium to short range npc, with no long range capabilities
	end
	return choice
end

function Block(Data)
	print("BLOCKED!")
	config.blockable = false
	config.currentState = "Stationary"
	config.currentCombatState = "Blocking"
	config.States.SpStates.Blocking = true 
	config.Block.Cooldown = 1 
	summonWeldedVfx:Fire("Block",npc.HumanoidRootPart,Data,false)
	loadedAnimations.Block.Priority = Enum.AnimationPriority.Action2
	loadedAnimations.Block:Play()
	loadedAnimations.Block:GetMarkerReachedSignal("Pause"):Connect(function()
		loadedAnimations.Block:AdjustSpeed(0)
		config.Block.Cooldown += 2.1
	end)
end

function Dodge(dodgePriority)
	config.dodgeable = false
	config.currentState = "Stationary"
	config.DodgeCooldown = 1
	local directionTable = {
		DodgeForward = npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0,0,-17)),
		DodgeBack	 = npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0,0,12)),
		DodgeRight	 = npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(12,0,0)),
		DodgeLeft 	 = npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(-12,0,0)),		
	}
	local cardinal = {npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0,0,-17)),npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(12,0,0)),npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0,0,12)),npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(-12,0,0))}
	local dodgeDirection
	local direction = Vector3.new(0,0,0)
	if dodgePriority ~= "" then 
		dodgeDirection = dodgePriority
	else
		local cardinalDirections = {0,0,0,0} -- starting from forward and ending on your left
		local otherCardinalThing = {"DodgeForward","DodgeRight","DodgeBack","DodgeLeft"}
		for i=1,4,1 do 
			local theta = 90*i
			local x = math.cos(theta)*10
			local z = math.sin(theta)*10
			task.spawn(function()
				local rayOrigin 							=  npc.HumanoidRootPart.Position
				local rayDirection 							=  npc.HumanoidRootPart.CFrame:PointToWorldSpace(Vector3.new(x,0,z))
				print(rayDirection)
				local raycastParams 						= RaycastParams.new()
				raycastParams.FilterDescendantsInstances 	= {script.Parent}
				raycastParams.FilterType					= Enum.RaycastFilterType.Exclude
				local raycastResult 						= workspace:Raycast(rayOrigin, rayDirection,raycastParams)
				print(raycastResult,i)
				if raycastResult == nil then 
					cardinalDirections[i] 					= true	 
					return
				end
				cardinalDirections[i] 						= false
			end)
		end
		local tally = 0
		for i, v in pairs(cardinalDirections) do
			if v then
				tally+=1
			end
		end	
		if tally == 0 then print("no room to dodge") config.currentState = "" return end 
		local x = math.random(1,tally)
		direction += cardinal[x]
		dodgeDirection = otherCardinalThing[x]
	end
	loadedAnimations[dodgeDirection]:Play()
	direction += directionTable[dodgeDirection]
	local dodgeStart = loadedAnimations[dodgeDirection]:GetMarkerReachedSignal("Dodge"):Connect(function()
		local currentPos = npc.HumanoidRootPart.Position -- remove this 
		config.currentCombatState = "Dodging"
		print("The npc is dodging bruh!")
		print(direction,dodgeDirection,"the vector and the dodge direction of the dodge")
		local startTime = loadedAnimations[dodgeDirection]:GetTimeOfKeyframe("DodgeStart")
		local endTime	= loadedAnimations[dodgeDirection]:GetTimeOfKeyframe("DodgeEnd")
		local totalTime = endTime-startTime
		npcDodge:Fire(npc,direction,totalTime,dodgeDirection,true)
		config.DodgeCooldown += 2.1
		task.wait(totalTime)
		print((currentPos - npc.HumanoidRootPart.Position).Magnitude, "how far the npc went when dodging") -- remove this 
		config.currentCombatState = "Idle" -- this could cause problems i'm pretty sure
		print("Idle after dodging")
	end)
	task.wait(loadedAnimations[dodgeDirection].Length)
	dodgeStart:Disconnect()
	config.currentState = ""
end

function combatControl()
	local target		= trueTarget.Name
	task.spawn(function() -- this section controlls attacking 
		while trueTarget.Name ~= "" and trueTarget.Distance <= config.searchRadius and Players[target].Character.Humanoid.Health > 0 do --handles the player actually being in range!
			if target ~= trueTarget.Name then return end

			while config.currentCombatState == "Stunned" or config.currentState == "Stationary"  do  -- while you're stunned you do nothing
				task.wait()
			end
			
			while config.currentCombatState == "Blocking" or config.currentCombatState == "Dodging" do 
				task.wait()
				--print("waiting for the blocking/dodging to end")
				if config.currentCombatState == "Idle" then 
					--print("Switching to fighting")
					config.currentCombatState = "Fighting"
					break
				end
			end 

			local choice
			local start = tick()
			while config.currentState == "Targetting" and trueTarget.Distance <= config.Range[config.preferedRange] do 
				task.wait()
				if tick() - start == 3 then 
					--print("this one could be the cause of some unforseen problems")
					config.currentState = ""
					config.currentCombatState = "Fighting"
				end
			end
			if config.currentState ~= "Stationary" then 
				if trueTarget.Distance > config.Range[config.preferedRange] and config.currentCombatState == "Fighting" then 
					local x = math.random(1,3)
					if x == 1 then 
						--print("Wants to fight")
						choice = fightActionController(trueTarget.Distance,choice)
						combatSwitch(choice)
						config.currentCombatState = "Fighting"
					else
						--print("Wants to move closer")
						config.currentCombatState = "Fighting"
					end
				else
					choice = fightActionController(trueTarget.Distance,choice)
					combatSwitch(choice)
					config.currentCombatState = "Fighting"
				end 
				config.currentState = ""
			end
			config.currentCombatState = config.currentCombatState
			task.wait(config.reactionTime/2)
		end
		--trueTarget.Name = "" this might cause issues so lets leave it at this for now 
		--print("I have no enemies!")
		config.currentCombatState = ""
		config.currentState = "Idle"
	end)

	task.spawn(function() -- this section controlls defending 
		local Data			= {}

		Data.Player	   		= npc
		Data.Name 			= "Block"..npc.Name
		Data.Destroy 		= -1 -- in this case it just waits for everything to be over
		Data.Lifetime		= .15 -- the amount of time before it gets removed by the debris service
		Data.Npc			= true

		while trueTarget.Name ~= "" do  -- doesn't have to check if the player is in range because the fighting section does that already
			--God bless this code bro wtf
			-- removing this turns usage down all the way to 0 lmfao
			task.wait(config.reactionTime/2)
			-- for normal npcs you can just have them lookup the player they're targetting's attack
			-- for bosses they need to take a tally of all the players in their range and respond accordingly to whatever attack they could throw at them.
			if target ~= trueTarget.Name then return end -- break out so you don't have to deal with errors stemming from not having an actual name from the target 

			local pStats = optimizedPlayerTable.Get(Players[trueTarget.Name]) --sendStats:Invoke(Players[trueTarget.Name]) -- that is a 1000x improvement in performance right there my boy!
			
			if pStats.States.SpStates.Attacking == true and config.currentCombatState ~= "Blocking" and config.Block.Cooldown == 0 and config.stunTimer == 0 and config.currentCombatState ~= "Stunned" then 
				--print("Getting ready to block or dodge")
				for i, v in pairs(animator:GetPlayingAnimationTracks()) do -- no idea if this section actually does anything ngl but hey theoretically it should...
					if v.Name == "Swing"..config.swing then
						--print(not v:GetMarkerReachedSignal("Damage"), "This should only be true when the thing blocks")
						if not v:GetMarkerReachedSignal("Damage") then 
							v:Stop()
						else
							while v.isPlaying do task.wait() end
							config.blockable = false
							config.dodgeable = false
							break
						end
					else 
						v:Stop()
					end
				end

				if config.blockable and config.Block.Cooldown == 0  and config.dodgeable and config.DodgeCooldown == 0 then
					--print("Thinking about blocking or dodging")
					local blockChance 	= 50
					local dodgeChance 	= 50
					local bluffChance	= 0
					local dodgePriority = ""
					local skillWeight 	= 30 
					local backstabWeight= 20
					local distance = (npc.HumanoidRootPart.Position - Players[trueTarget.Name].Character.HumanoidRootPart.Position).Magnitude 

					if pStats.States.SpStates.UsingLongSkill or pStats.States.SpStates.UsingMediumSkill or pStats.States.SpStates.UsingShortSkill then --if the player is using a skill then you want to dodge
						blockChance -= skillWeight
						dodgeChance += skillWeight
					elseif distance >= config.Range.Short then -- if the person isn't using skills but is attacking and isn't in melee range then you call the bluff and keep going.
						blockChance = 1
						dodgeChance = 1
						bluffChance = 98
					end

					if not IsLookingAtPlayer(Players[trueTarget.Name]) then --if the player you're targetting gets behind you then you want to dodge forward.
						dodgeChance+= backstabWeight
						blockChance-= backstabWeight
						dodgePriority = "DodgeForward"
					end

					local choices = {{"Block",blockChance},{"Dodge",dodgeChance},{"CallBluff",bluffChance}} 
					local choice = combatChoice(choices)

					if choice == "Block" and config.Block.Cooldown == 0 and config.blockable then 
						--print("Chose to block")
						task.wait(config.reactionTime) -- might have to remove this..
						Block(Data)
						task.wait(.1)
					elseif choice == "Dodge" and config.DodgeCooldown == 0 and config.dodgeable then
						--print("Chose to dodge")
						Dodge(dodgePriority)
						task.wait(.1) -- just so it doesn't try to block straight after 
					elseif choice == "CallBluff" and config.currentCombatState ~= "Attacking" then
						--print("Calling the bluff!")
						config.currentState = "Idle" -- this might be a problem idk the state that really lets you target still
						config.currentCombatState = "Fighting"
						task.wait(config.reactionTime)
					end
				elseif config.blockable and config.DodgeCooldown <= 1.5 and config.Block.Cooldown == 0 and config.currentState ~= "Stationary" then --if dodgeable is false and you didn't just dodge then you block this next hit
					--print("no choice but to block")
					task.wait(config.reactionTime) -- might have to remove this..
					Block(Data)
					task.wait(.1)
				elseif config.dodgeable and config.Block.Cooldown == 0 and config.currentState ~= "Stationary"  then
					--print("no choice but to dodge")
					Dodge(nil)
				end
			elseif config.currentCombatState == "Blocking" or config.States.SpStates.Blocking == true then
				--print("Blocking",config.Block.Current)
				if pStats.States.SpStates.Attacking == false then 
					--print("Removing the block!")
					config.States.SpStates.Blocking = false
					destroyVfx:Fire("Block",Data,false)
					loadedAnimations.Block:Stop()
					task.wait(.1)
					config.currentCombatState = "Idle"
					config.currentState = ""
					config.blockable = true
				end
			end
			if config.currentState == "Stationary" then 
				humanoid:MoveTo(npc.HumanoidRootPart.Position)
				--print("You're meant to not be moving there bud!")
			end -- you don't want to waste your time moving if you're meant to be stationary
		end
		
		if isVfxPresent("Block") then
			destroyVfx:Fire("Block",Data,false)
			loadedAnimations.Block:Stop()
		end
	end)

	task.spawn(function() -- this does the cooldown for skills and blocking
		--optimized fine
		local tickrate = .1
		while trueTarget.Name ~= "" do
			task.wait(tickrate)
			config.Block.Cooldown 	= math.clamp(config.Block.Cooldown-tickrate,0,3) 
			config.stunTimer 		= math.clamp(config.stunTimer-tickrate,0,3)
			config.DodgeCooldown 	= math.clamp(config.DodgeCooldown-tickrate,0,3)
			--print(config.stunTimer)
			for i,v in pairs(config.onCooldown) do
				config.onCooldown[i] = math.clamp(v - tickrate,0,math.huge)
			end
			if config.currentCombatState == "Stunned" and config.stunTimer == 0 then 
				config.currentCombatState = "Idle"
			end
			
			config.dodgeable = config.DodgeCooldown == 0 and config.dodgeable == false
			
			if config.Block.Cooldown == 0 and config.blockable == false then
				config.blockable = true
				config.Block.Current = config.Block.Max
			end
			if config.onCooldown.Enchant < 20 and config.States.SpStates.Enchanted then
				config.States.SpStates.Enchanted = false
				config.Damage.Swing1.Damage -= 5
				config.Damage.Swing2.Damage -= 5
				npc.EliteArmor.Weapon.Edge.Color 	= Color3.new(0.678431, 0.376471, 0.145098)
				npc.EliteArmor.Weapon.Edge.Material = Enum.Material.Metal
			end
		end
		
		if config.States.SpStates.Enchanted then 
			config.States.SpStates.Enchanted = false
			config.Damage.Swing1.Damage -= 5
			config.Damage.Swing2.Damage -= 5
			npc.EliteArmor.Weapon.Edge.Color 	= Color3.new(0.678431, 0.376471, 0.145098)
			npc.EliteArmor.Weapon.Edge.Material = Enum.Material.Metal
		end
	end)

	task.spawn(function() -- turns the npc in the direction of the player constantly which doesn't seem to be doing anything bruh....
		-- could do with some optimization with .5% usage
		local target = trueTarget.Name
		local alignOrientation 		= Instance.new("BodyGyro")
		alignOrientation.Parent 	= npc.HumanoidRootPart
		alignOrientation.CFrame		= Players[trueTarget.Name].Character.HumanoidRootPart.CFrame
		alignOrientation.MaxTorque	= Vector3.new(10000,10000,10000)
		alignOrientation.P			= 10000
		while trueTarget.Name ~= "" and trueTarget.Name ~= target do
			local playerPos	   = Players[trueTarget.Name].Character.HumanoidRootPart.CFrame.Position
			alignOrientation.CFrame = CFrame.new(npc.HumanoidRootPart.Position,playerPos)
			task.wait(.05)	
		end
		alignOrientation:Destroy()
	end)
end

local currentHealth = humanoid.Health

humanoid.HealthChanged:Connect(function(health)
	local change = currentHealth - health
	if change > 1 then 
		print("I BEEN HIT!")
		config.blockable = false -- let the npc know that it's not allowed to block this attack because it's been hit
		config.dodgeable = false

		if config.currentCombatState == "" then -- force the npc to go into combat and make sure that it's stunned to begin with
			print("Forcing the npc into combat")
			if trueTarget.Name == "" then 
				trueTarget = closestPlayerByDistance()
			end
			config.currentCombatState = "Stunned" --You need to know if you're stunned before going into the combat controller but cant put this before or after
			combatControl()
		else
			config.currentCombatState = "Stunned"
		end

		for i, v in pairs(animator:GetPlayingAnimationTracks()) do -- this may not be needed we'll see..
			v:Stop()
		end
		
		local x = math.random(1,3)

		local anim = "Hit"..x
		if config.States.SpStates.GuardBroken then 
			anim = "GuardBreak"
		end
		loadedAnimations[anim].Priority = Enum.AnimationPriority.Action4
		loadedAnimations[anim]:Play()
		task.wait(loadedAnimations[anim].Length)
		loadedAnimations[anim]:Stop()

		print("The humanoid's health", (currentHealth > health and "decreased by" or "increased by"), change)
		currentHealth = health
		config.stunTimer = .5 -- replace tomorrow with the stun number from the attack.
	end
end)
--------------------------------------------------------------------------------------- Combat Section End

--------------------------------------------------------------------------------------- Main Section
--visualize()

while humanoid.Health > 0 do -- this one simply moves towards the player that is the closest
	FindPlayer()
	--print(config.currentCombatState, "The read current combat state" , config.currentState, "The read current state")
	if config.currentCombatState == "" and trueTarget.Distance <= config.InitiateCombatRange and IsLookingAtPlayer(Players[trueTarget.Name]) then 
		config.currentCombatState = "Fighting"
		config.currentState = ""
		loadedAnimations.Run:Stop()
		loadedAnimations.Walk:Stop()
		--print("~~~~~~~~~~~~~~~Controlling combat~~~~~~~~~~~~~~~~~~~~~~~")
		combatControl()
		--print("~~~~~~~~~~~~~~~~Stopping combat~~~~~~~~~~~~~~~~~~~~~~~~")
	elseif trueTarget.Name ~= "" and (config.currentCombatState == "" or config.currentCombatState == "Fighting")   and config.currentState ~= "Stationary" then -- if you have targets and you aren't blocking
		if isAnimationPlaying("Run") == false and  config.currentState ~= "Targetting" then 
			print("Playing the run animation again!")
			humanoid.WalkSpeed = 16
			loadedAnimations.Run:Play()
			loadedAnimations.Run.Looped = true
		end
		--print("!!!!!!!!!!!!!!Targeting!!!!!!!!!!!!!!!!!!!!")
		local complete = followPath(Players[trueTarget.Name].Character.PrimaryPart.Position)
		task.wait(.3) --this limits the amount of times the controller actually recacluates the path.
	elseif config.currentState ~= "Patrolling" and config.currentState ~= "Targetting" and config.currentCombatState == "" and config.currentState ~= "Stationary" then 
		loadedAnimations.Run:Stop()
		if config.currentState == "Idle" then
			loadedAnimations.Idle:Play()
			loadedAnimations.Idle.Looped = true
			task.wait(math.random(5,30)/10)
			loadedAnimations.Idle:Stop()
		end
		patrolPath()	
	end 
	-- possible states: {"Patrolling","Targetting","Fighting","Attacking","Blocking","Dodging","Idle","Stunned","Stationary"}
	lastPosition = npc.HumanoidRootPart.Position
	config.currentMovementState = config.currentState
	task.wait(.05)
end

script.Enabled=false
--------------------------------------------------------------------------------------- Main Section End

--[[function rayVisualize(origin,destination,distance)
--	local ray 			= Instance.new("Part")
--	ray.Parent			= workspace
--	ray.Size			= Vector3.new(.5,.5,distance*2)
--	ray.Color			= Color3.new(0.603922, 0.447059, 1)
--	ray.CFrame			= CFrame.new(origin,destination)
--	ray.CanQuery		= false
--	ray.CanCollide		= false
--	ray.CanTouch		= false
--	ray.Anchored		= true
--	ray.Transparency	= .5
--	return ray
--end
--]]




--local playerPositionRelativeToOrigin 		=  playerPosition-rayOrigin
--local x =  playerPositionRelativeToOrigin:Dot(Vector3.new(1,0,0)) these here only works for things that are standing still...
--local y =  playerPositionRelativeToOrigin:Dot(Vector3.new(0,1,0))
--local z =  playerPositionRelativeToOrigin:Dot(Vector3.new(0,0,1))

--function checkIfStuck()
--	return npc.HumanoidRootPart.Position == lastPosition and (currentState == "Patrolling" or currentState == "Targetting")
--end

--visualize()

--local patrolCoroutine =  coroutine.create(patrolPath)

--task.spawn(function()
--	while humanoid.Health > 0 do 
--		if checkIfStuck() then 
--			task.wait(1)
--			if checkIfStuck() then
--				print("STUCK!")
--				currentState = "Stuck"
--				humanoid:MoveTo(npc.HumanoidRootPart.CFrame:ToObjectSpace(CFrame.new(Vector3.new(0,0,10))).Position)
--				humanoid.Jump = true
--				print("SOB SHOULD'VE JUMPED IF NOT THIS SH AZ")
--			end
--		end
--		task.wait(.1)
--	end
--end)




---------------------------------------------------------------------------------------

--function patrolPath() -- behaves like a zombie in a way could be useful if you could slow it down a bit
--	if not patroling then 
--		followPath(patrolWaypoints[currentPatrolNode].Position + assignedPatrolPath.Position)
--		patroling = humanoid.MoveToFinished:Connect(function()
--			currentPatrolNode+=1
--			if currentPatrolNode > #patrolWaypoints then 
--				currentPatrolNode = 1
--			end
--			patroling:Disconnect()
--			patroling = nil
--		end)
--	end
--end



------------------------------------- V4 ----------------------------------------- V4 ---------------------------------------

------------------------------------- V3 ----------------------------------------- V3 ---------------------------------------

--local pfs 							= game:GetService("PathfindingService")
--local Players 						= game:GetService("Players")
--local getPlayersInRegion 			= game.ServerStorage.GetPlayersInRegion
--local config						= require(script.Parent.NpcConfig)

--local npc 							= script.Parent
--local humanoid						= script.Parent:FindFirstChildWhichIsA("Humanoid") or script.Parent:WaitForChild("NpcHumanoid")

--local searchRadius					= 30
--local characterHeight				= 6 -- put this section into the config

--local pathParams 					= {["AgentHeight"] = characterHeight;
--	["AgentRadius"] = 5;
--	["AgentCanJump"] = true,}
--local path = pfs:CreatePath(pathParams)


--function FindPlayers()
--	local targets = nil
--	for i, v in pairs(config.regions) do
--		local targetablePlayersInRegion = getPlayersInRegion:Invoke(v)
--		if targetablePlayersInRegion == nil then return end
--		for i, v in pairs(targetablePlayersInRegion) do 
--			local success, distance = CheckInBounds(v)
--			if success then 
--				if targets == nil then targets = {} end
--				table.insert(targets,{v.Name,distance})  
--			end
--		end
--	end
--	return targets
--end

--function CheckInBounds(player)
--	local playerPosition						=  player.Character.HumanoidRootPart.Position
--	--local lookVector 							=  npc.HumanoidRootPart.CFrame.LookVector

--	local rayOrigin 							=  npc.HumanoidRootPart.Position
--	local rayDirection 							=  playerPosition
--	local raycastParams 						= RaycastParams.new()
--	raycastParams.FilterDescendantsInstances 	= {script.Parent}
--	raycastParams.FilterType					= Enum.RaycastFilterType.Exclude
--	local raycastResult 						= workspace:Raycast(rayOrigin, rayDirection,raycastParams)
--	if not raycastResult then return false end 
--	local distance								= raycastResult.Position-playerPosition
--	print("hit")
--	return math.abs(distance.X) <= searchRadius and math.abs(distance.Y) <= characterHeight and math.abs(distance.Z) <= searchRadius, distance.Magnitude
--end

--function getPath(destination)
--	path:ComputeAsync(npc.HumanoidRootPart.Position, destination)
--	print("Path Made")
--	return path
--end

--function visualize()

--	local cone 			= Instance.new("Part")
--	local weld 			= Instance.new("Weld")
--	cone.Parent			= workspace
--	cone.Transparency	= .7
--	cone.CanCollide 	= false
--	cone.CanQuery		= false
--	cone.CanTouch		= false
--	cone.Anchored		= false
--	cone.Color			= Color3.new(1, 0.447059, 0.054902)
--	cone.Position		= npc.HumanoidRootPart.Position
--	cone.Shape 			= Enum.PartType.Cylinder
--	cone.Size			= Vector3.new(characterHeight,searchRadius,searchRadius)
--	weld.Parent			= cone
--	weld.Part0			= cone
--	weld.Part1			= npc.HumanoidRootPart
--	cone.Orientation	= Vector3.new(0, 0, -90) 
--end

--local function walkTo(destination)
--	local success, fail = pcall(function()
--		path = getPath(destination.HumanoidRootPart.Position)
--	end)
--	if success and path.Status == Enum.PathStatus.Success then 
--		print("walking")
--		local waypoints = path:GetWaypoints()
--		for i, waypoint in pairs(waypoints) do
--			print(waypoint.Position)
--			humanoid:MoveTo(waypoint.Position)
--			if path.Blocked then 
--				--humanoid:MoveTo(waypoints[3].Position)
--				return
--			end
--		end
--	end
--end

--visualize()
--while humanoid.Health > 0 do -- this one simply moves towards the player that is the closest
--	local targets = FindPlayers()
--	if targets ~= nil then 
--		local TrueTarget = targets[1]
--		for i, v in pairs(targets) do 
--			if v[2] < TrueTarget[2] then 
--				TrueTarget = v
--			end
--		end
--		walkTo(Players[TrueTarget[1]].Character)
--		--task.wait(humanoid.MoveToFinished:Wait())
--	end  
--	task.wait()
--	targets = nil
--end

------------------------------------- V3 ----------------------------------------- V3 ---------------------------------------


------------------------------------- V1 ----------------------------------------- V1 ---------------------------------------

--[[]]
--local pfs 							= game:GetService("PathfindingService")
--local Players 						= game:GetService("Players")
--local Character 					= script.Parent
--local human							= script.Parent:WaitForChild("Humanoid")
--local destinationPosition 			= workspace.Endpoint.Position
--local pathParams 					= {["AgentHeight"] = 6;
--										["AgentRadius"] = 5;
--										["AgentCanJump"] = true,}
--local path = pfs:CreatePath(pathParams)

--local function findTarget()
--	local maxDistance = 600
--	local nearestTarget

--	for index, player in pairs(Players:GetPlayers()) do
--		if player.Character then
--			local target = player.Character
--			local distance = (Character.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude

--			if distance < maxDistance and target.Humanoid.Health > 0 then
--				nearestTarget = target
--				maxDistance = distance
--			end

--			if distance < 5 then
--				nearestTarget.Humanoid:TakeDamage(1000000000)
--			end
--		end
--	end
--	print("Target Found: ", nearestTarget)
--	return nearestTarget
--end




--local function getPath(destination)
--	path:ComputeAsync(script.Parent.HumanoidRootPart.Position, destination)
--	return path
--end

--local function walkTo(destination)
--	local success, fail = pcall(function()
--		path = getPath(destination.HumanoidRootPart.Position)
--	end)
--	if success and path.Status == Enum.PathStatus.Success then 
--		local waypoints = path:GetWaypoints()
--		for i, waypoint in pairs(waypoints) do
--			human:MoveTo(waypoint.Position)
--			--human.MoveToFinished:Wait()
--			if path.Blocked then 
--				human:MoveTo(waypoints[3].Position)
--				return
--			end
--		end
--	end
--end
--while wait() do 
--	walkTo(findTarget())
--end


--]]
------------------------------------- V1 ----------------------------------------- V1 ---------------------------------------

--[[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local pathfinding = game:GetService("PathfindingService")

script.Parent.HumanoidRootPart:SetNetworkOwner(nil)

local path = pathfinding:CreatePath({
	AgentHeight = 33;
	AgentRadius = 6;
	AgentCanJump = false;
})

local Character = script.Parent
local humanoid = Character:WaitForChild("Humanoid")

local waypoints
local nextWaypointIndex
local reachedConnection
local blockedConnection

local function findTarget()
	local maxDistance = 600
	local nearestTarget

	for index, player in pairs(Players:GetPlayers()) do
		if player.Character then
			local target = player.Character
			local distance = (Character.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude

			if distance < maxDistance and target.Humanoid.Health > 0 then
				nearestTarget = target
				maxDistance = distance
			end

			if distance < 5 then
				nearestTarget.Humanoid:TakeDamage(1000000000)
			end
		end
	end

	return nearestTarget
end

local function followPath(destination)

	local success, errorMessage = pcall(function()
		path:ComputeAsync(Character.HumanoidRootPart.Position, destination)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		waypoints = path:GetWaypoints()

		blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
			if blockedWaypointIndex >= nextWaypointIndex then
				blockedConnection:Disconnect()
				followPath(destination)
			end
		end)

		--[[if not reachedConnection then
			reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
				if reached and nextWaypointIndex < #waypoints then
					nextWaypointIndex += 1
					humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
					if waypoints[nextWaypointIndex].Action == Enum.PathWaypointAction.Jump then 
						humanoid.Jump= true
						reachedConnection:Disconnect()
						blockedConnection:Disconnect()
					end
				else
					reachedConnection:Disconnect()
					blockedConnection:Disconnect()
				end
			end)
		end

		nextWaypointIndex = 2
		humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
		if waypoints[nextWaypointIndex].Action == Enum.PathWaypointAction.Jump then 
			humanoid.Jump= true
			blockedConnection:Disconnect()
		end
	else
		humanoid:MoveTo(destination - (Character.HumanoidRootPart.CFrame.LookVector*10))
	end
end

while wait(.05) do
	local target = game.Workspace:WaitForChild("malebergromon1234567")
	if target then
		print(target.Name)
		followPath(target.HumanoidRootPart.Position)
	end
end
]]
------------------------------------- V2 ----------------------------------------- V2 ---------------------------------------

--local pfs 			= game:GetService("PathfindingService")
--local human 		= script.Parent:WaitForChild("NpcHumanoid")
--local Players 		= game:GetService("Players")
--local pathParams 	= {["AgentHeight"] = 33,["AgentRadius"] = 10.5,["AgentCanJump"] = true,}

--local waypoints
--local nextWaypointIndex
--local reachedConnection
--local blockedConnection

--script.Parent.HumanoidRootPart:SetNetworkOwner(nil)

--local path = pfs:CreatePath(pathParams)
--local function getPath(destination)
--	path:ComputeAsync(script.Parent.HumanoidRootPart.Position, destination)
--	return path
--end

--local function findTarget()
--	local maxDistance = 600
--	local nearestTarget

--	for index, player in pairs(Players:GetPlayers()) do
--		if player.Character then
--			local target = player.Character
--			local distance = (script.Parent.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude

--			if distance < maxDistance and target.Humanoid.Health > 0 then
--				nearestTarget = target
--				maxDistance = distance
--			end
--		end
--	end	
--	return nearestTarget
--end


--local function walkTo(destination)
--	local path = getPath(destination.HumanoidRootPart.position)
--	local newPos = destination.HumanoidRootPart.Position
--	local waypoints = path:GetWaypoints()	
--	nextWaypointIndex = 2
--	blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
--		if blockedWaypointIndex >= nextWaypointIndex then
--			blockedConnection:Disconnect()
--			walkTo(destination)
--		end
--	end)

--	if not reachedConnection then
--		reachedConnection = human.MoveToFinished:Connect(function(reached)
--			if reached and nextWaypointIndex < #waypoints then
--				nextWaypointIndex += 1
--				human:MoveTo(waypoints[nextWaypointIndex].Position)
--				if waypoints[nextWaypointIndex].Action == Enum.PathWaypointAction.Jump then 
--					human.Jump= true
--				end
--			else
--				reachedConnection:Disconnect()
--				blockedConnection:Disconnect()
--			end
--		end)
--	end
--		human:MoveTo(waypoints[nextWaypointIndex].Position)
--	if waypoints[nextWaypointIndex].Action == Enum.PathWaypointAction.Jump then 
--			human:ChangeState(Enum.HumanoidStateType.Jumping)
--		end
--		human.MoveToFinished:Wait()
--end
--wait(1)
--while wait() do 
--	print(nextWaypointIndex)
--	walkTo(findTarget())
--end


------------------------------------- V2 ----------------------------------------- V2 ---------------------------------------