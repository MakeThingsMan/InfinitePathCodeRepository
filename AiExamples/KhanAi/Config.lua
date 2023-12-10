local DamageClass		= require(game.ServerScriptService.CombatController.DamageClass)

local NpcConfig = {
	
	regions = {"Platform of Colossi","TestArea"},
	animations = {
		Idle 		= "rbxassetid://14342228081",
		Walk 		= "rbxassetid://14342321370",
		Run  		= "rbxassetid://14344281335",
		Swing1		= "rbxassetid://14345135760",
		Swing2		= "rbxassetid://14364132836",
		KhanRoar	= "rbxassetid://14364128390",
		Enchant		= "rbxassetid://14733889311",
		Block		= "rbxassetid://14425054362",
		Hit1		= "rbxassetid://14430050423",
		Hit2		= "rbxassetid://14430054014",
		Hit3		= "rbxassetid://14430057390",
		GuardBreak 	= "rbxassetid://14744317013",
		DodgeBack	= "rbxassetid://14474444970",
		DodgeForward= "rbxassetid://14475061360",
		DodgeRight	= "rbxassetid://14475186279", -- named left
		DodgeLeft	= "rbxassetid://14475166469", -- named right
	},
	Hitboxes = {
		Swing1 = "KhanWide1",
		Swing2 = "KhanWide1"},
	MaxSwings= 2,
	Damage = {
		KhanRoar = DamageClass.New("KhanRoar",5,1,{"Fire","Fire"},0,2,.8,true,true),
		Enchant = DamageClass.New("Enchant",25,1,{"Fire","Metal",2,.7,1,false,true}),
		Swing1 = DamageClass.New("Swing1",15,1,nil,3,0,.1,true,true),
		Swing2 = DamageClass.New("Swing2",12,1,nil,4,.1,.1,true,true)
	},
	Range = {
		Short = 6,
		Medium= 15,
		Long  = 25
	},
	preferedRange = "Short",
	RangeTable = { -- the attacks should be listed in order of least common to most common
		Short = {{"Melee", 80,},{"KhanRoar",10},{"Enchant",10}}, --A range of 1 - 12 studs --80 10 10
		Med = 	{{"KhanRoar",70},{"Enchant",30}}, -- A range of 12 - 30
		Long = 	{{"Enchant",100}}, -- 30 - 50
	},
	onCooldown = {
		KhanRoar  = 0, 
		Enchant = 0,
	},
	faction = "Khan",

	stunTimer = 0,
	DodgeCooldown = 0,
	jumping						= false,
 	InitiateCombatRange 		= 25, 		--Put this section into the config
	reactionTime				= .08, 		-- The amount of delay between the npc seeing that it's going to be attacked and it responding with something.
	swing 						= 1,
	lastSwing 					= 0,
	debounce 					= false,
	currentCombatState			= "",
	blockable 					= true,
	dodgeable					= true,
	searchRadius				= 75, 		 --Put this section into the config 
	maxRadius 					= 75*.5 + 5, -- searchRadius *.5 + 5
	characterHeight				= 6, 		 -- Put this section into the config
	currentState				= nil,
	assignedPatrolPath			= game.Workspace.PatrolPath1, -- the patrolpath that the npc will follow
	-- note to self: Make a reference table of who's friendly with eachother so the npc's
	-- know whether or not they deal damage to that specific faction
	
	---- stats section
		Race 		= "Human",
		Artifact 	= "N/A",
		Health = {
			Current = 200,
			Regen 	= 1.3,
			Max 	= 200,
		},
		Qi = {
			Element1 = {
				Element = "Fire",
				Tier	= 3
			},
			Element2 = {
				Element = "Fire",
				Tier	= 3
			},
	},
	Block = {
		Max = 130 ,
		Current = 130 ,
		Cooldown = 0 
	},
		States = {
			Buffs = {

			},
			SpStates = {
				RegenOff 			= false,
				Enchanted			= false,
				Dead				= false, 
				QiDeviation 		= false,
				Enlightening 		= false,
				Blocking			= false,
				GuardBroken			= false
		}, 
		},
		Defense = {
			Qi 			= 15,--15
			Physical	= 20,--20
		},
		AugmentingStats 	= {
			Strength 		= 1, 		-- FIGHT STUFF to increase
			Intelligence	= 1, 		-- read books/ meditation to increase
			Dexterity 		= 1, 		-- RUN to increase affects movement speed
			Vitality		= 1, 		-- GET HIT to increase	
		},
		Constitution = -1,
		Temperature = 0, 	-- value between -10 and 10
		MovementSpeed = 1,
	
}
return NpcConfig

