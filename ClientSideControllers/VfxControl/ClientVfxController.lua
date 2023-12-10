local Debris					= game:GetService("Debris")
local propagateVfx				= game.ReplicatedStorage:WaitForChild("PropagateVfx")
local propagateSkillVfx			= game.ReplicatedStorage:WaitForChild("PropagateSkillVfx")
local player 					= game.Players.LocalPlayer
local updateVfx 				= game.ReplicatedStorage:WaitForChild("UpdateVfx")
local activeVfx					= {}

propagateVfx.OnClientEvent:Connect(function(vfx,Cframe,data,summon)
	if summon then 
		createVfx(vfx,data,Cframe)
	else
		if data.Destroy then -- if there are performance issues in the future you can remove this 
			-- because this whole system works under the assumption that only things that are constant can work here
			-- don't forget to add the thing that lets you select which particles actually explode and which ones dont
			workspace.TemporaryVFX[vfx..data.Player.Name]:Destroy()
		else
			for i, v in pairs (workspace.TemporaryVFX[vfx..data.Player.Name]:GetDescendants()) do
				if v:IsA("ParticleEmitter") then
					v:Emit(v:GetAttribute("EmitCount"))
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
	end
end)

propagateSkillVfx.OnClientEvent:Connect(function(Module, data)
	local ModuleF = require(game.ReplicatedStorage.Modules.Templates.Abilities:FindFirstChild(Module)) or warn('Module does not exist in folder Templates!')
	ModuleF(data)
end)

updateVfx.OnClientEvent:Connect(function(vfxlist) -- this partially solves the problem of vfx not loading in when someone joins the game
	activeVfx = vfxlist
end) -- for integrity sake you can change this over to be a bindable function which would be better i think... Requires more thinking at a later date


function createVfx(vfx,data,Cframe)
	local vfx 	= game.ReplicatedStorage.VFX:FindFirstChild(vfx,true):Clone()
	vfx.Parent 	= workspace.TemporaryVFX
	vfx.Name 	= vfx.Name..data.Player.Name
	print(vfx.Name, "We made it over to the client side!")
	if vfx:IsA("Model") then vfx:PivotTo(Cframe) return vfx end
	vfx.Position	= Cframe.Position
	return vfx
end


while true do
	-- when you eventually do playtesting you could add a check to see how far away the player is to the vfx that is happening
	-- if they're too far away you just don't summon anything to begin with since idfk if roblox does stuff like backface culling 
	-- hell idek if they have lod down properly for particles so do that in case you end up with lag problems 
	if activeVfx == nil then repeat task.wait() until activeVfx ~= nil end
	for i, v in pairs(activeVfx) do
		local vfx = game.Workspace.TemporaryVFX:FindFirstChild(v.Name,true)
		--if vfx then --99% sure this isn't needed because if it doesn't have any decendants then the for loop just does nothing and skips past it
			for j, k in pairs(vfx:GetDescendants()) do
				if k:IsA("ParticleEmitter") and not k:GetAttribute("Updated") then 
					spawn(function()
						k:SetAttribute("Updated",true)
						task.wait(k:GetAttribute("Tickrate"))
						k:Emit(k:GetAttribute("EmitCount"))
						k:SetAttribute("Updated",false)
					end)
				end
			end
		--end
	end
	task.wait(.0167) -- runs at 60 fps pretty much -- could've just done task.wait(1/60) but that's cool too...
end

-- have big one time attacks be on the server side/within the range of certain idividuals. 
-- Assuming that they can't get near the location while the thing is being casted as is the case with boss areas and stuff.