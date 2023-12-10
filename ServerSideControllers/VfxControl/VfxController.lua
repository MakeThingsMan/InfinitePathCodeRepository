local Debris					= game:GetService("Debris")
local summonVfx 				= game.ServerStorage:WaitForChild("SummonVfx")
local destroyVfx				= game.ServerStorage:WaitForChild("DestroyVfx")
local summonWeldedVfx			= game.ServerStorage:WaitForChild("SummonWeldedVfx")
local NpcSkillUse				= game.ServerStorage:WaitForChild("NpcSkillUse")
local propagateVfx				= game.ReplicatedStorage:WaitForChild("PropagateVfx")
local updateVfx 				= game.ReplicatedStorage:WaitForChild("UpdateVfx")
local clientSummonWeldedVfx		= game.ReplicatedStorage:WaitForChild("ClientSummonWeldedVfx")
local SkillUse					= game.ReplicatedStorage:WaitForChild("SkillUse")
local propagateSkillVfx			= game.ReplicatedStorage:WaitForChild("PropagateSkillVfx")
local activeVfx					= {}
script.Parent:WaitForChild("DataController")

-- assume that vfx that are here server sided. I.E the things with multiple layers added onto them using emit count and delay 
-- can only be stored in the server and therefore need to be stored in the server storage not replicated storage

local function summonHelper(vfx,position,data,propagate,weld,rawObject,area)
	if propagate then 
		propagateVfx:FireAllClients(vfx,position,data,true) -- send CFrames to the client for simplicity sake
		data.Position = position
		data.Name = vfx..data.Player.Name
		activeVfx[vfx..data.Player.Name] = data
		updateVfx:FireAllClients(activeVfx)
	else
		local vfx			 	= game.ServerStorage.VFX:FindFirstChild(vfx,true):Clone()
		
		if weld then -- This does welded object vfx
			local weld	= Instance.new("Weld")
			weld.Part0	= vfx
			weld.Part1 	= rawObject
			weld.Name 	= "VfxWeld"
			weld.Parent = rawObject
		elseif area  then -- this does enchants and other lingering vfx
			for i, v in pairs(vfx:GetChildren()) do
				v.Parent = rawObject
				Debris:AddItem(v,data.EnchantPeriod)
			end
			Debris:AddItem(vfx,data.EnchantPeriod)
		else -- this does standalone vfx
			vfx.Position = position
		end
		
		if vfx:FindFirstChild("Handler") then
			local HandlerScript 	= require(vfx.Handler.HandlerScript)
			HandlerScript.GiveData(data)
		end
		
		vfx.Parent = workspace.TemporaryVFX
		vfx.Name = vfx.Name..data.Player.Name
	end
end

local function IsLookingAtPoint(origin,otherPoint) -- this would be the optimization for the clients if there's too many vfx happening at one time you would simply render only the ones that the player is looking at.
	-- this section looks to see if you are in front of the npc or not 
	-- the filter returns true if you're in front of the npc and false if you're not
	local test = origin.CFrame
	local otherTest = otherPoint.CFrame:ToObjectSpace(test)

	--local x = otherTest.Position.X
	local y = otherTest.Position.Y
	local z = otherTest.Position.Z
	return z*-1>0 -- the times -1 is for my sanity dw about it.
end

summonVfx.Event:Connect(function(vfx,position,data,propagate,area)
	data.wait = 0
	data.Updated = false
	local rawObject
	if area then 
		rawObject = data.rawObject
	end
	summonHelper(vfx,position,data,propagate,nil,rawObject,area)
end)

clientSummonWeldedVfx.OnServerEvent:Connect(function(player,vfx,objectToWeldTo,data,propagate) -- this should pretty much never be used. Like EVER!
	summonWeldedVfx:Fire(vfx,objectToWeldTo,data,propagate)
end)

summonWeldedVfx.Event:Connect(function(vfx,objectToWeldTo,data,propagate)
	summonHelper(vfx,objectToWeldTo.CFrame,data,propagate,true,objectToWeldTo)
end)

destroyVfx.Event:Connect(function(vfx,data,propagate)
	print("Got into the delete vfx function")
	if propagate then 
		propagateVfx:FireAllClients(vfx,nil,data,false)
		activeVfx[vfx] = nil
		return 
	end
	if data.Destroy == true then
		wait(data.DestroyDelay)
		workspace.TemporaryVFX[vfx..data.Player.Name]:Destroy()
	elseif data.Destroy == -1  then
		print("Removing:", workspace.TemporaryVFX[vfx..data.Player.Name].Name, data.Lifetime) -- remove this
		Debris:AddItem(workspace.TemporaryVFX[vfx..data.Player.Name],data.Lifetime)
	else
		for i, v in pairs (workspace.TemporaryVFX[vfx..data.Player.Name]:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				v:Emit(v:GetAttribute("EmitCount")) -- add something to data that says that the thing will actually blow up when it's done.
			end
			if v:IsA("ParticleEmitter") or v:IsA("Beam") then
				spawn(function()
					for i = 60, 100,1 do
						v.Transparency = NumberSequence.new(i*.01) 
						task.wait()
					end
				end)
			end
		end
		Debris:AddItem(workspace.TemporaryVFX[vfx..data.Player.Name],1.5)
	end
	activeVfx[vfx] = nil
end)

SkillUse.OnServerEvent:Connect(function(Player,skillName,parameters,startPos,endPos) -- endPos might not be needed in the end but it's whatever right now.

	local Character = Player.Character
	local RootPart = Character.HumanoidRootPart
	local Humanoid = Character.Humanoid

	local Parameters = {parameters,Character.PrimaryPart.Position}
	local OriginPosition = Character.PrimaryPart.Position
	
	if skillName == 'KhanLightningEnchant' then
		local FinalPosition = Vector3.new(Parameters[1].X, 0, Parameters[1].Z)
		propagateSkillVfx:FireAllClients('KhanLightningEnchant', {FinalPosition,OriginPosition})
	end
end)

NpcSkillUse.Event:Connect(function(npc,skillName,parameters,startPos,endPos)
	local Character = npc
	local RootPart = Character.HumanoidRootPart
	local Humanoid = Character.NpcHumanoid

	local Parameters = {parameters}
	local OriginPosition = Character.PrimaryPart.Position

	if skillName == 'KhanLightningEnchant' then -- make a switch statement for this since all of these will be useable by both honestly.
		local FinalPosition = Vector3.new(Parameters[1].X, 0, Parameters[1].Z)
		propagateSkillVfx:FireAllClients('KhanLightningEnchant', {FinalPosition,OriginPosition})
	end
end)

while true do 
	updateVfx:FireAllClients(activeVfx)
	task.wait(.5)
end


--[[
 
 have tribulations be server sided while the rest of the effects like fireballs and stuff be activated when the person joins or when it's fired. Since
 projectiles will travel for a set distance they'll simply have their effects load in mid way.
 
 
 -- saving this because i like how it works 
 while true do 
	if activeVfx ~= nil then
		for i, v in pairs(activeVfx) do
			if not v.Updated then -- serves as a makeshift debounce because this is the only thing I could think of at the time of writing all of this
				print(v)
				for j, k in pairs(game.Workspace.TemporaryVFX:FindFirstChild(v,true):GetDescendants()) do
					if k:IsA("ParticleEmitter") then 
						k:Emit(k:GetAttribute("EmitCount"))
						task.wait(k:GetAttribute("Tickrate"))
					end
				end
				print("Update")
				v.Updated = true 
			else
				v.wait += .0167  
				if v.wait > v.Tickrate then 
					v.wait = 0 
					v.Updated = false
				end
			end

		end
	end
	task.wait(.0167) -- runs at 60 fps pretty much
end

 
 ]]