local ItemClass		= require(game.ServerScriptService.DataController.ItemClass) 
local Nodes			= require(game.ServerScriptService.TableNodes)

local wood			= ItemClass.new("Wood","Resource",nil,1,15,1,1,1)
local bamboo		= ItemClass.new("Bamboo","Resource",nil,1,15,1,1,1)
local spiritCrystal = ItemClass.new("Spirit Crystal","Resource",nil,1,99,1,2,5)
local rock 			= ItemClass.new("Rock", "Resource",nil,1,30,1,1,1)
local purpleShroom	= ItemClass.new("PurpleShroom","Resource","PurpShroom",1,30,1,1,1)
local yellShroom	= ItemClass.new("YellShroom","Resource","YellShroom",1,30,1,1,1)

local Config = {
	-- In the format NodeName 	= {ToolRequired, NodeTier, {Sound1,Sound2,Sound3...} {{Item1,chance,minAmount,MaxAmount},{Item2,chance,minAmount,MaxAmount},{Item3,chance,minAmount,MaxAmount}...}}  
	-- NodeTiers tell you how much resource the node can hold and how fast it recharges. 
	-- With 5 being the fastest with the most and 1 being the slowest with the least.
	-- rotationAxi tells us if the object is allowed to rotate aorund the y axis 
	-- With things that are clickable set the amount taken to be the amount that is stored at all times. 
	-- Sounds: {"ID",Start,End}
	PinkTree	= {
		ToolRequired= "Axe",
		NodeTier 	= 5, 
		Sounds 		= {"rbxassetid://9120869140"},
		Items 		= {Nodes.New(wood,1,2,5)},
		RespawnTime = 30, -- in seconds
		RotationAxi = true,

	},
	StraightBamboo	= {
		ToolRequired= "Hand",
		NodeTier 	= 1, 
		Sounds 		= {"rbxassetid://6644702473"},
		Items 		= {Nodes.New(bamboo,1,2,2)},
		RespawnTime = 30, -- in seconds
		RotationAxi = true,
		ResourceOverride = 2
	},
	PurpShroom = {
		ToolRequired= "Hand",
		NodeTier 	= 1, 
		Sounds 		= {"rbxassetid://812371010",0,1},
		Items 		= {Nodes.New(purpleShroom,1,1,1)},
		RespawnTime = 30, -- in seconds
		RotationAxi = true,
		ResourceOverride = 1
	},
	YellShroom = {
		ToolRequired= "Hand",
		NodeTier 	= 1, 
		Sounds 		= {"rbxassetid://812371010",0,1},
		Items 		= {Nodes.New(yellShroom,1,1,1)},
		RespawnTime = 30, -- in seconds
		RotationAxi = true,
		ResourceOverride = 1
	},
	SpiritCrystal = {
		ToolRequired = "Pickaxe",
		NodeTier = 4, 
		Items = {Nodes.New(spiritCrystal,.7,1,9),Nodes.New(rock,1,1,5)}
	}
}
-- note to self you can have a "hand" toolrequired and you can set that one to be the nodes that you can click on and they regenerate after a set period of time
-- this fire flowers from rogue.

return Config
