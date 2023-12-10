local playerStats = {	
	["Race"] 		= "N/A",
	["Class"] 		= "N/A",
	["Artifact"] 	= "N/A",
	["Health"] = {
		["Current"] = 100,
		["Regen"] 	= 10, --1
		["Max"] 	= 100,
	},
	["Qi"] = {
		["Current"] = 0,
		["Element1"] = {
			["Element"] = "Neutral",
			["Tier"]	= 1
		},
		["Element2"] = {
			["Element"] = "Neutral",
			["Tier"]	= 1
		},
		["Regen"] 		= 1,
		["Max"] 		= 100,
		["Unlocked"] 	= false
	},
	["Cultivation"] = {
		["Speed"] 		= nil,	
		["State"] 		= 0,
		["CBase"] 		= 0, -- as in cultivation base 
		["CBaseMax"] 	= 0,
		["TribulationTimer"] = 0,
	},
	["States"] = {
		["Buffs"] = {
			
			},
		["InCombat"] = {
			["Value"]	= false,
			["Duration"] = 0,
		},
		["Paths"] = { -- might change over to the scrolls system that was devised before 
			["Path1"] = -1,
			["Path2"] = -1,	
			},
		["SpStates"] = {
			["Cultivating"]			= false,
			["RegenOff"] 			= false,
			["Dead"] 				= false, 
			["QiDeviation"] 		= false,
			["Enlightening"] 		= false,
			["TribulationPrep"]  	= false,
			["Tribulating"]  		= false,
			["GuardBroken"]			= false,
			["Blocking"]			= false,
			["Stunned"]				= false,
			["Dodging"]				= false, -- you can guess what this means bruh you're not stupid
			["Attacking"]			= false, -- as in melee attacks
			["UsingShortSkill"]		= false, --->
			["UsingLongSkill"]		= false, --|these tell the ai out there what the player is doing so they can predict that they have to dodge or not.
			["UsingMediumSkill"]	= false, --->
			["TTSS"] 				= false, -- Talking to Sword Soul
			["TTID"] 				= false},-- Talking to Inner Demon
			}, 
	["Damage"] = {
		["Qi"] 					= 0,
		["Physical"] 			= 0,
		["CritChance"] 			= 0, 	-- PILLS to increase
	},
	["Defense"] = {
		["Qi"] 			= 1,
		["Physical"] 	= 1,
	},
	["AugmentingStats"] 	= {
		["Strength"] 		= 1, 		-- FIGHT STUFF to increase
		["Intelligence"] 	= 1, 	-- read books/ meditation to increase
		--["Charisma"] 		= 0, 	-- set on birth might not do
		["Dexterity"] 		= 1, 		-- RUN to increase affects movement speed
		["Vitality"]		= 1, 		-- GET HIT to increase	
	},
	["Achievements"] = {
		["Points"] = 0,
		["Feats"] = {},
	},
	["Bloodlines"] = {
		["Active"] = -1,
		["Obtained"] = {
		["Count"] =0,	
		},
	},
	["Inventory"] = {
		{0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0}},
	["Hotbar"] = {0,0,0,0,0,0,0,0},
	["Equipment"] = {
		["Head"]	= -1,	
		["Body"]	= -1,		
		["LeftArm"]	= -1,		
		["RightArm"]	= -1,		
		["LeftLeg"]	= -1,	
		["RightLeg"]	= -1,		
		["Accessories"]	={
			["A"] = -1,
			["B"] = -1,
			["C"] = -1,
		},		
		["Artifact"]	= -1,		
		["Pet"]	= -1,		
		["Spirit"]	= -1,		
	},
	["Block"] = {
		["Max"] = 100, -- note to self make this actually max out your current because somoene somewhere could make current block a million for all i know 
		["Current"] = 100,
		["Cooldown"] = 0
	}, -- The amount of damage your block can take.
	["Money"] = 0,
	["Constitution"] = -1,
	["Temperature"] = 0, 	-- value between -10 and 10
	["MovementSpeed"] = 1,
	["Lives"] = 1,  -- put back to 2 eventually
	["playerID"] = "N/a",
	["Reincarnations"] = 0,
	["EquippedItem"] = -1,
}
return playerStats