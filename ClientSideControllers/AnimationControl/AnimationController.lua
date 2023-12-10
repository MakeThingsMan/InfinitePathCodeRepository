local Players 					= game:GetService("Players")
local UIS						= game:GetService("UserInputService")
local TweenService				= game:GetService("TweenService")
local TempDamage 				= game.ReplicatedStorage:WaitForChild("HitboxHandler")
local SetToolForAnimation 		= game.ReplicatedStorage:WaitForChild("SetToolForAnimation")
local EquipItem					= game.ReplicatedStorage:WaitForChild("EquipItem")
local CDR						= game.ReplicatedStorage:WaitForChild("CDR")
local StateChange				= game.ReplicatedStorage:WaitForChild("StateChange")
local Sps						= game.ReplicatedStorage:WaitForChild("SendPlayerStats")
local StoppedAttacking			= game.ReplicatedStorage:WaitForChild("StoppedAttacking")
local Dodge 					= game.ReplicatedStorage:WaitForChild("Dodge")
local UpdateStunValue			= game.ReplicatedStorage:WaitForChild("UpdateStunValue")
local controls 					= require(game.Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
local player					= Players.LocalPlayer
local Character 				= player.Character or player.CharacterAdded:Wait()
local Humanoid 					= Character:WaitForChild("Humanoid")
local Animator					= Humanoid.Animator
----------------------------------------------------------------------------------------------------
local currentTool		= nil
local animations 		= nil
local loadedAnimations 	= {}
local toolType			= nil
local slot 				= nil
local connection 		= nil
local swing 			= 1
local lastSwing 		= nil
local debounce 			= false
local dodgeDebounce		= false
local lastTool			= nil
local done 				= nil -- this is needed apparently
local stunned 			= false
local currentHealth		= Humanoid.Health


--	--["Equip"]  = "rbxassetid://13694695271",
--	["Equip"]  = "rbxassetid://13762661559",
--	--["Idle"]   = "rbxassetid://13727000400",
--	--["Walk"] = "rbxassetid://13754423075",
--	["Block"] = "rbxassetid://13762164890",
--	["Walk"] = "rbxassetid://13761706773",
--	["Idle"]   = "rbxassetid://13736996065",
--	["Recovery"]= "rbxassetid://13727440027",
--	["Swing1"] ="rbxassetid://13714032283",
--	["Swing2"] ="rbxassetid://13726205270",
--	["Swing3"] = "rbxassetid://13726179942"

local defaultAnimations = {
	["HeadEquip"] 	= "rbxassetid://13820930670",
	["BodyEquip"]	= "rbxassetid://13903143357",
	["Walk"] 		= "rbxassetid://14122126726",
	["Run"] 		= "rbxassetid://14122145335",
	["Equip"] 		= "rbxassetid://14122174213",
	["Block"] 		= "rbxassetid://14122151349",
	["Idle1"] 		= "rbxassetid://14122158454",
	["Idle2"] 		= "rbxassetid://14122166155",
	["Hit1"]		= "rbxassetid://14430050423",
	["Hit2"]		= "rbxassetid://14430054014",
	["Hit3"]		= "rbxassetid://14430057390",
	["DodgeBack"]	= "rbxassetid://14474444970",
	["DodgeForward"]= "rbxassetid://14475061360",
	["DodgeRight"]	= "rbxassetid://14475186279", -- named left
	["DodgeLeft"]	= "rbxassetid://14475166469", -- named right
	["GuardBreak"]	= "rbxassetid://14744317013"
	--["Walk"] = "rbxassetid:14122126726",
}


----------------------------------------------------------------------------------------------------
function finder(animations,lookfor,opposite)
	local found = false
	local oppositeFound = false
	for i, v in pairs(Animator:GetPlayingAnimationTracks()) do
		--print(v.Name,v.Name == lookfor,v.Name == opposite)
		if v.Name == lookfor then
			found = true
			break
		end 
		if v.Name == opposite then 
			oppositeFound = true
			break
		end
	end
	if not found then
		delay(task.wait(),function()
			if math.round(Character.HumanoidRootPart.Velocity.Magnitude) == 0 then
				animations[opposite]:Stop()
				animations[lookfor]:Play()
			end
		end)
	end 
	if oppositeFound and math.round(Character.HumanoidRootPart.Velocity.Magnitude) >= 0  then  -- not found part is unnecessary
		animations[opposite]:Stop()
		animations[lookfor]:Play()
	end	
end

----------------------------------------------------------------------------------------------------

CDR.OnClientEvent:Connect(function()
	print("Did the thing")
	for i, v in pairs(defaultAnimations) do 
		local x = Instance.new("Animation")
		x.AnimationId =  v
		x.Name 		  =  i
		loadedAnimations[i] = Animator:LoadAnimation(x)
	end
	print(loadedAnimations)
end)

SetToolForAnimation.Event:Connect(function(Id,Tool,ToolType,Slot) -- currently only works for weapons
	----------------------------------------------------------------------------------------------------
	if Id == player.UserId then -- make sure that the one that it's being sent to is the correct person
		print("Matching")
		currentTool = Tool
		lastTool = currentTool
		animations = animations 
		toolType = ToolType
		slot = Slot
		print(Tool)
	end
	----------------------------------------------------------------------------------------------------
	local animations = {
		["Equip"]  	= "",
		["Idle"]   	= "",
		["Walk"] 	= "",
		["Run"] 	= "",
		["Block"] 	= "",
		["Recovery"]= "",
		["Swing1"] 	= "",
		["Swing2"] 	= "",
		["Swing3"] 	= ""}	-- get the animations of the curerntly equipped tool
	if slot.Animations then
		for i, v in pairs (animations) do 
			if v == "" then 
				animations[i] = loadedAnimations[i]
			end
		end
		
		for i, v in pairs(slot.Animations) do 
			local x = Instance.new("Animation")
			x.AnimationId =  v
			x.Name 		  =  i
			animations[i] =  Animator:LoadAnimation(x)
		end
	end
	----------------------------------------------------------------------------------------------------
	connection = currentTool.Equipped:Connect(function() -- play the idle animation for the weapon here 
		--VisualizeHitbox:FireServer(slot.Hitboxes,Character.HumanoidRootPart) -- shows where the hitbox should be 
		animations.Equip:Play()
		loadedAnimations.Block = animations["Block"]
		
		
		animations.Equip.Stopped:Connect(function()
			if  math.round(Character.HumanoidRootPart.Velocity.Magnitude) == 0  then 
				animations.Idle:Play()
				animations.Idle.Looped = true
			else
				animations.Walk:Play()
				animations.Walk.Looped = true
				Humanoid.WalkSpeed = 12 -- remove this 
			end	
		end)

		local run = Humanoid.Running:Connect(function()
			if stunned then return end
			local found = false
			for i, v in pairs(Animator:GetPlayingAnimationTracks()) do
				if v.Name == "Walk" then 
					found = true
					break
				end
			end
			if not found then 
				animations.Idle:Stop()
				animations.Walk:Play()
				Humanoid.WalkSpeed = 12 -- and remove this 
				animations.Walk.Looped = true
			end
		end)

		local swing = currentTool.Activated:Connect(function()
			if stunned then return end
			if not debounce then
				debounce = true
				lastSwing = swing
				animations.Idle:Stop()
				animations["Swing"..swing]:Play()
				local damage = animations["Swing"..swing]:GetMarkerReachedSignal("Damage"):Connect(function()
					print("how many times does this thing fire...")
					TempDamage:FireServer(slot.Hitboxes.Box,slot) -- make sure you change this to be server sided passing in the hitbox
				end)
				task.wait(animations["Swing"..swing].Length) --or this is where you'd put getting hit
				if swing < slot.MaxSwings then
					swing+=1
				else 
					swing=1
					if animations.Recovery ~= nil then  -- not everything needs to have a recovery so this will take care of that issue
						animations.Recovery:Play()
					end
					task.wait(slot.Endlag)
					StoppedAttacking:FireServer()
				end
				damage:Disconnect()
				debounce = false
				task.wait(1)
				if lastSwing == swing-1 then 
					print("You didn't swing in time")
					animations.Idle:Play()
					animations.Idle.Looped = true
					swing = 1
					StoppedAttacking:FireServer()
					debounce = true 
					task.wait(slot.Endlag)
					debounce = false
				end
			end
		end)

		done = currentTool.Unequipped:Connect(function()
			local x = Instance.new("Animation")
			x.AnimationId = defaultAnimations.Block
			x.Name = "Block"
			loadedAnimations.Block = Animator:LoadAnimation(x)
			for i,v in pairs(animations) do 
				v:Stop()
			end
			currentTool = nil
			lastTool = -1
			connection:Disconnect()
			run:Disconnect()
			swing:Disconnect()
			done:Disconnect()
		end)

		while lastTool == currentTool do
			local standingStill = math.round(Character.HumanoidRootPart.Velocity.Magnitude) == 0 
			if not standingStill then 
				finder(animations,"Walk","Idle")	
			else
				finder(animations,"Idle","Walk")	
			end
			task.wait(.05)
		end	
	end)
end)

local keyboardInput = UIS.InputBegan:Connect(function(inputObject,gameProcessedEvent)
	if gameProcessedEvent then return end 
	if stunned then return end
	local Data = {}
	if inputObject.KeyCode == Enum.KeyCode.F then
		local pStats = Sps:InvokeServer(player)
		if pStats.Block.Cooldown == 0 then 
			print("You pressed F")
			loadedAnimations.Block:Play()
			Data.Player = player
			StateChange:FireServer("Blocking",true)
			loadedAnimations.Block:GetMarkerReachedSignal("Pause"):Connect(function()
				print("Got to the pause")
				controls:Disable()
				loadedAnimations.Block:AdjustSpeed(0)
			end)
			task.wait(loadedAnimations.Block.Length)
		end
	elseif inputObject.KeyCode == Enum.KeyCode.Q and dodgeDebounce == false then
		local direction = Vector3.new(0,0,0)
		local dodgeDirection = ""
		dodgeDebounce = true 
		--print("You pressed Q")
		if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then 
			if UIS:IsKeyDown(Enum.KeyCode.W) then 
				direction += Character.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0,0,-17))
				dodgeDirection = "DodgeForward"
			elseif UIS:IsKeyDown(Enum.KeyCode.S) then
				direction = Character.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0,0,12))
				dodgeDirection = "DodgeBack"
			end
			if UIS:IsKeyDown(Enum.KeyCode.A) then
				direction += Character.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(-12,0,0))
				--print("direction for left is:", direction)
				if dodgeDirection ~= "DodgeForward" and dodgeDirection ~= "DodgeBack" then
					dodgeDirection = "DodgeLeft"
				end
			end
			if UIS:IsKeyDown(Enum.KeyCode.D) then
				direction += Character.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(12,0,0))
				--print("direction for right is:", direction)
				if dodgeDirection ~= "DodgeForward" and dodgeDirection ~= "DodgeBack" then
					dodgeDirection = "DodgeRight"
				end
			end

			if dodgeDirection == "" then 
				direction = Character.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0,0,12))
				dodgeDirection = "DodgeBack"
			end
		else
			local camera = workspace.CurrentCamera
			if camera.CFrame:VectorToObjectSpace(Character.Humanoid.MoveDirection).Unit:Dot(camera.CFrame.Position) <= 0 then
				if UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.D) then 
					direction += Character.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0,0,-17))
					dodgeDirection = "DodgeForward"
				else
					direction = Character.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0,0,12))
					dodgeDirection = "DodgeBack"
				end
			else
				if UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.D) then 
					direction += Character.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0,0,-17))
					dodgeDirection = "DodgeForward"
				else
					direction = Character.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0,0,12))
					dodgeDirection = "DodgeBack"
				end
			end 
		end
		
		local pos1 = Character.HumanoidRootPart.Position

		loadedAnimations[dodgeDirection]:Play()
		Humanoid.JumpHeight = 0 -- this is to stop the player from being able to jump after triggering the dodge
		local dodgeStart = loadedAnimations[dodgeDirection]:GetMarkerReachedSignal("Dodge"):Connect(function()
			--print("it's getting in here")
			local startTime = loadedAnimations[dodgeDirection]:GetTimeOfKeyframe("DodgeStart")
			local endTime	= loadedAnimations[dodgeDirection]:GetTimeOfKeyframe("DodgeEnd")
			local totalTime = endTime-startTime
			--local tweenInfo		= TweenInfo.new(totalTime,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut)
			--local propetyTable	= {CFrame = primaryPart.CFrame:ToWorldSpace(CFrame.new(direction))}
			--local tween = TweenService:Create(primaryPart,tweenInfo,propetyTable)
			--tween:Play()
			Dodge:FireServer(direction,totalTime,dodgeDirection)
		end)
		task.wait(loadedAnimations[dodgeDirection].Length) -- the 4 is the multip
		Humanoid.JumpHeight = 7.2
		local pos2 = Character.HumanoidRootPart.Position
		--print((pos2-pos1).Magnitude, "The distance you traveled")
		dodgeStart:Disconnect()
		task.wait(2+loadedAnimations[dodgeDirection].Length/5)
		dodgeDebounce = false
	end
end)

local keyboardInputEnd = UIS.InputEnded:Connect(function(inputObject,gameProcessedEvent)
	if gameProcessedEvent then return end 

	if inputObject.KeyCode == Enum.KeyCode.F then
		local pStats = Sps:InvokeServer(player)
		if pStats.States.SpStates.Blocking  then 
			loadedAnimations.Block:Stop()
			controls:Enable()
			StateChange:FireServer("Blocking",false)
		end
	end
end)

Humanoid.HealthChanged:Connect(function(health)
	local change = currentHealth - health
	if change > 1 then 
		print("I BEEN HIT!")
		local x = math.random(1,3)
		
		for i, v in pairs(Animator:GetPlayingAnimationTracks()) do
			v:Stop()
		end
		
		local pStats = Sps:InvokeServer(player)
		local anim = "Hit"..x
		if pStats.States.SpStates.GuardBroken then 
			anim = "GuardBreak"
		end
		loadedAnimations[anim].Priority = Enum.AnimationPriority.Action4
		loadedAnimations[anim]:Play()
		task.wait(loadedAnimations[anim].Length)
		loadedAnimations[anim]:Stop()
		
		--print("The humanoid's health", (currentHealth > health and "decreased by" or "increased by"), change)
		currentHealth = health
	end
end)

EquipItem.OnClientEvent:Connect(function(slot) -- this isn't really ever used but it's there just in case I need it bruh
	--print(loadedAnimations,slot)
	--loadedAnimations[slot.."Equip"]:Play()
end)

UpdateStunValue.OnClientEvent:Connect(function(value)
	stunned = value
end)