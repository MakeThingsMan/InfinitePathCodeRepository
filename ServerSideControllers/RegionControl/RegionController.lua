-- note to later self
--if you eventually end up having performance issues because you're looping through all the regions to figure out where the player is you can 
--mitigate the damage done by splitting up the map into for quads and figuring out what regions are in those quads
--this will reduce the amount of regions you gotta look through

local players  = game:GetService("Players")

local getPlayersInRegion = game.ServerStorage.GetPlayersInRegion

local Region = require(script.Parent.RegionsModule)
--local AtmoChange = game.ReplicatedStorage.ClientAnimations.AtmoChange
local twinsAtmo = {0.6,.542, Color3.new(0.231373, 0.101961, 0.290196),Color3.new(0, 0, 0),-1,6}

-------------------------------------------------------------------------------------------------------------------- Create Regions
local R2 = Region.new("Platform of Colossi",twinsAtmo,1,1)
local R1 = Region.new("TestArea",twinsAtmo,1,2)

R2:DefineDimensions(Vector3.new(-100.152, 0.5, 688.962),Vector3.new(-284.748, 50.664, 860.35))
R1:DefineDimensions(R2.Vector1/2,R2.Vector2/2,R2.Center-Vector3.new(0,R2.Vector2.Y/2 -R2.Vector2.Y/4 ,0))
regions = {}



script.Parent:WaitForChild("DataController")
-------------------------------------------------------------------------------------------------------------------- Helper Functions
function addToRegions(region)
	regions[region.Name] = region
end

addToRegions(R1)
addToRegions(R2)
-------------------------------------------------------------------------------------------------------------------- Visualize Regions
for i, v in pairs(regions) do
	v:Visualize()
end


function CheckInBounds(player,v)
	if player == nil then return false end
	local position = player.Character.HumanoidRootPart.Position
	local newThing = position - v.Center
	return math.abs(newThing.X) <= v.Width/2 and math.abs(newThing.Y) <= v.Height/2 and math.abs(newThing.Z) <= v.Depth/2 
end

function CheckInBoundsHierarchy(player)
	local within = {}
	for i,v in pairs(regions) do 
		if CheckInBounds(player,v) then 
			table.insert(within,v)
		end
	end
	local surmost = within[1]
	for i, v in pairs(within) do
		if v.Hierarchy > surmost.Hierarchy then 
			surmost = v 
		end
	end
	return surmost
end

getPlayersInRegion.OnInvoke = function(regionName)
	return regions[regionName].PlayersInRegion
end
-------------------------------------------------------------------------------------------------------------------- 
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAppearanceLoaded:Wait()
	local humanoid = player.Character:WaitForChild("Humanoid")
	while humanoid.Health > 0 do 
		local foundRegion = CheckInBoundsHierarchy(player)
		if foundRegion then 
			foundRegion:AddPlayer(player)
		end 
		task.wait()
	end
end)

--while true do 
--	task.wait(3)
--	for i, v in pairs(regions) do
--		print("Players in", v.Name, ":", table.concat(v.PlayersInRegion," "))
--	end
--end