------------------------------------------------------------------------------
local CollectionService 		= game:GetService("CollectionService")
local Switch 					= require(game.ServerScriptService.Switch)
local CentralResourceTable		= require(game.ServerScriptService.CentralizedResourceTable)
local Decrypter					= require(game.ServerScriptService.ResourceSpawnerDecoder)
local ResourceHit				= game.ServerStorage:WaitForChild("ResourceHit")
local InventoryEvent			= game.ServerStorage:WaitForChild("InventoryEvent")
local activeResourceNodes		= {}
local activePinResourceSpawners	= {}
local PlaySound 				= game.ServerStorage:WaitForChild("PlaySound")
------------------------------------------------------------------------------ ResourceSpawnerSection
-- spawners can have this syntax [Reference][spawnLimit] 
-- Spawners must have 2 letters in their name or else this wone work.
-- I.E: [PtFl15] which would spawn pink trees and flowers with a limit of 15 for the whole thing
-- I.E: [Pt01] would spawn a single pink tree which at that point you might as well have used a pinpoint spawner

for i, v in pairs(workspace.Spawners:GetDescendants()) do
	if v:IsA("Part") then
		v.Transparency = 1
	end
end

function randomizeOption(nameLength,Spawner)
	if nameLength > 4 then 
		local start = math.random(1,(nameLength-2))
		if start==nameLength-2 then
			start-=1
		elseif  start%2 == 0  then
			start+=1
		end
		local upper = start+1 
		return string.sub(Spawner.Name,start,upper)
	end
	return string.sub(Spawner.Name,1,#Spawner.Name-2) 
end

function pinpointSpawnOnAdded(object)
	--local nodeLimit = tonumber(string.sub(object.Name, #object.Name-1,#object.Name)) not needed here
	local nameLength = #object.Name
	local objectToSpawn = randomizeOption(nameLength,object)
	pinpointSpawnOnAddedNoDecryption(Decrypter[objectToSpawn],object)	
end

function pinpointSpawnOnAddedNoDecryption(decryptedObj,object)	
	object.Transparency = 1
	local finalPosition = object.Position
	local finalRotation = object.Orientation
	local Node = game.ServerStorage.ResourceNodes[decryptedObj]:Clone()
	if CentralResourceTable[decryptedObj].RotationAxi then 
		finalRotation *= Vector3.new(math.random(1,90)/10,finalPosition.Y,math.random(1,90)/10)
	end
	if Node:FindFirstChild("ClickDetector") then 
		Node.ClickDetector.MouseClick:Connect(function(player)
			--Node.ClickDetector.MouseClick:Disconnect()
			local lootTable = CentralResourceTable[Node.Name]
			PlaySound:Fire(CentralResourceTable[Node.Name].Sounds[1],Node)
			LootExecute(lootTable,Node,player)
		end)
	end	

	Node:PivotTo(CFrame.new(finalPosition))
	Node.Parent= object
end

function pinpointSpawnOnRemoved()
	-- doubt this will ever really happen unless i for some reason add in terrain destruction which i sincerely doubt will ever happen cause 
	-- that's a whole lot of work that I don't want to be doing yk?
end

function LootExecute(lootTable,Node,player)
	for i, v in pairs(lootTable.Items)  do
		local resourceValue = math.min(math.random(v.MinAmount,v.MaxAmount),Node.RemainingResource.Value) 
		v.Item.Stacks = resourceValue
		Node.RemainingResource.Value -= resourceValue
		if Node.RemainingResource.Value >= 0 then 
			--print("Remaining resources:", Node.RemainingResource.Value)
			-- note to self: add the whole removing the node thing later and have it so you can change whether or not the resource actively regenerates over time
			--print(v.Item)
			local chance = math.random(1,10)/10
			--print(chance, chance <= v.Chance)
			if chance <= v.Chance then 
				InventoryEvent:Fire(v.Item,player)
			end
			if Node.RemainingResource.Value == 0 then
				local onZero =  require(Node.OnZero)
				onZero.OnZero()
			end
		end
	end
end

for i, v in pairs(CollectionService:GetTagged("PinpointNodeSpawn")) do
	table.insert(activePinResourceSpawners,v)
	pinpointSpawnOnAdded(v)
end
-- these aren't needed because I sincerely doubt that you'll ever be adding or removing resource points unless you do so for a boss fight or something. 
-- yeah i guess at the end of a boss fight you could make a bunch of things spawn...
local PinSpawnSignal = CollectionService:GetInstanceAddedSignal("PinpointNodeSpawn")
local PinSpawnRemove = CollectionService:GetInstanceRemovedSignal("PinpointNodeSpawn")

PinSpawnSignal:Connect(pinpointSpawnOnAdded)
PinSpawnRemove:Connect(pinpointSpawnOnRemoved)
------------------------------------------------------------------------------ ResourceNode section
ResourceHit.Event:Connect(function(Node,player,ToolType)
	--print(Node.Name, "has been hit by:",player.Name)
	local lootTable = CentralResourceTable[Node.Name]
	--print(lootTable)
	--print(ToolType, lootTable.ToolRequired)
	if ToolType == lootTable.ToolRequired then
		PlaySound:Fire(CentralResourceTable[Node.Name].Sounds,Node) -- make this play after you're done with the animation rather than the start of the animation
		-- you can do this using the tag system in the animation controller/moon animation suite
		LootExecute(lootTable,Node,player)
	end
end)

function resourceNodeOnAdded(Node) 
	--print("ResourceNode Here!", Node.Name) 
	local location 	= Instance.new("NumberValue")
	location.Name 	= "ArrayLocation"
	location.Value	= #activeResourceNodes
	location.Parent	= Node
	local Remaining = Instance.new("NumberValue")
	Remaining.Name 	= "RemainingResource"
	Remaining.Value	= CentralResourceTable[Node.Name].NodeTier * 5--math.random(3,5)
	Remaining.Parent= Node
	table.insert(activeResourceNodes,Node)
end

function resourceNodeOnRemoved(Node) 
	table.remove(activeResourceNodes,Node.ArrayLocation.Value)
	--Node:Destroy() -- this could cause problems depending on what the node itself does so ima just leave it out for now
end

local NodeAddedSignal = CollectionService:GetInstanceAddedSignal("ResourceNode")
local NodeRemovedSignal = CollectionService:GetInstanceRemovedSignal("ResourceNode")

for i, v in pairs(CollectionService:GetTagged("ResourceNode")) do
	resourceNodeOnAdded(v)
end

NodeAddedSignal:Connect(resourceNodeOnAdded)
NodeRemovedSignal:Connect(resourceNodeOnRemoved)
------------------------------------------------------------------------------
while true do 
	for i, Spawner in pairs(activePinResourceSpawners) do
		if #Spawner:GetChildren() == 0 then 
			spawn(function()
				local nameLength = #Spawner.Name
				local objectToSpawn = string.sub(Spawner.Name,1,#Spawner.Name-2) 

				objectToSpawn = randomizeOption(nameLength,Spawner)

				local decryptedObj 	= Decrypter[objectToSpawn]
				local finalObject 	= CentralResourceTable[decryptedObj]
				task.wait(finalObject.RespawnTime)
				pinpointSpawnOnAddedNoDecryption(decryptedObj,Spawner) -- a little optimization here would be to make a different function that doesn't do the decryption nonsense but that's for later.
			end)
		end
	end

	for i, Node in pairs(activeResourceNodes) do 
		pcall(function()
			Node.RemainingResource.Value = math.clamp(CentralResourceTable[Node.Name].ResourceOverride or Node.RemainingResource.Value + CentralResourceTable[Node.Name].NodeTier, 0, CentralResourceTable[Node.Name].NodeTier * 5)
		end)
	end
	task.wait(10)
end

------------------------------------------------------------------------------