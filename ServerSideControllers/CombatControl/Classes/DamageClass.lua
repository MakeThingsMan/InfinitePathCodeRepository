local Damage = {}

Damage.__index = Damage

local damageTable = {
	["Fire"] 		={1.0,0.9,1.1,0.5,1.5,1.0,1.0,1.0},
	["Earth"] 		={1.5,1.0,0.9,1.1,0.5,1.0,1.0,1.0},
	["Metal"] 		={0.5,1.5,1.0,0.9,1.1,1.0,1.0,1.0},
	["Water"] 		={1.1,0.5,1.5,1.0,0.9,1.0,1.0,1.0},
	["Wood"] 		={0.9,1.1,0.5,1.5,1.0,1.0,1.0,1.0},
	["Light"] 		={1.0,1.0,1.0,1.0,1.0,1.0,1.2,1.0},
	["Dark"] 		={1.0,1.0,1.0,1.0,1.0,1.2,1.0,1.0},
	["Neutral"] 	={1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0}
}

local lookupTable = {
	["Fire"] 	= 1,
	["Earth"] 	= 2,
	["Metal"]	= 3,
	["Water"] 	= 4,
	["Wood"] 	= 5,
	["Light"] 	= 6,
	["Dark"] 	= 7,
	["Neutral"] = 8,
}

--[[	fire,earth,metal,water,wood,light,dark,neutral <--DEFENDER
fire	1.0	  .9	1.1	 .5	   1.5   1.0   1.0  1.0
earth	1.5	  1.0	0.9	 1.1   0.5   1.0   1.0  1.0
metal	0.5	  1.5	1.0	 .9	   1.1   1.0   1.0  1.0
water	1.1	  .5	1.5  1.0   0.9   1.0   1.0  1.0					
wood	.9	  1.1	.5	 1.5	1    1.0   1.0  1.0
light	1.0   1.0  1.0	 1.0   1.0   1.0   1.2  1.0
dark	1.0   1.0  1.0	 1.0   1.0   1.2   1.0  1.0
neutral	1.0   1.0  1.0	 1.0   1.0   1.0   1.0  1.0
^
ATTACKER
Read as: Attacker doing damage to the defender 
]]

function Damage.New(name,damage,proportion,eStack,armorPen,qiShred,hitStun,blockable,dodgable) --[[ make dps, like burst attacks, a sub class of this by 
putting in a value of how many hits there will be. The function that will distribute the damage. The delay between each hit. Concluding with the 
element that each attack will have. (This one will be very neiche but incredibly useful if I put it in right away.)
]]
	if not damage then 
		warn("You didn't assign",name," any damage!")
	end

	if not proportion then -- a proportion value of 1 will be 100% physical and a proportion value of 0 will be 100% Qi based.
		proportion = 1
	end

	if not eStack then 
		eStack = {"Neutral"}
	end
	
	if not qiShred then 
		qiShred = 0
	end
	--if not eProportion then 
	--	eProportion = {1}
	--end

	if not armorPen then
		armorPen = 0
	end

	if not hitStun then 
		hitStun = .25
	end
	
	if blockable == nil then 
		blockable = true 
	end
	
	if dodgable == nil then 
		dodgable = true
	end
	
	local newDamage = {}
	newDamage.Name					= name
	newDamage.Damage				= damage
	newDamage.Proportion 			= proportion
	newDamage.ElementStack			= eStack
--	newDamage.ElementalProportion	= eProportion
	newDamage.ArmorPen 				= armorPen
	newDamage.QiShred				= qiShred --no more than .5
	newDamage.HitStun	 			= hitStun
	newDamage.Blockable				= blockable
	newDamage.Dodgable				= dodgable
	newDamage.InFrontOfDefender		= false
	setmetatable(newDamage,Damage)
	return newDamage
end

function Damage:SelfApply(pStats)
	return Damage.Apply(self,pStats)
end

function Damage.Apply(Attack, pStats, humanoid)
	local damage 		= Attack.Damage
	local proportion 	= Attack.Proportion
	local elem1			= pStats.Qi.Element1.Element
	local elem2			= pStats.Qi.Element2.Element
	local elem1p		= pStats.Qi.Element1.Tier/(pStats.Qi.Element1.Tier + pStats.Qi.Element2.Tier)
	local elem2p		= pStats.Qi.Element2.Tier/(pStats.Qi.Element1.Tier + pStats.Qi.Element2.Tier)
	local lookup1		= lookupTable[elem1]
	local lookup2		= lookupTable[elem2]
	
	--print(Attack)
	--print(pStats)
	--print(damage, "Initial")
	damage = damage*(1-proportion)-(math.clamp(pStats.Defense.Qi*(1-proportion)-Attack.QiShred,0,math.huge)) + damage*(proportion)-(math.clamp(pStats.Defense.Physical*proportion-Attack.ArmorPen,0,math.huge) ) -- reduces the damage taken by the defense that you have
	--print(damage, "After defense is calculated")
	--print(damageTable[Attack.ElementStack[1]][lookup1],Attack.ElementStack[1],elem1, "lookup1")
	--print(damageTable[Attack.ElementStack[2]][lookup2],Attack.ElementStack[2],elem2, "lookup2")
	--print(Attack.ElementStack[1], damage, elem1p, elem2p, "stuffs")
	if Attack.ElementStack[2] ~= nil then
		damage = (damage*elem1p)*(damageTable[Attack.ElementStack[1]][lookup1]+Attack.QiShred) + (damage*elem2p)*(damageTable[Attack.ElementStack[2]][lookup2]+Attack.QiShred) --multiplies the damage by the elemental affinities change to support trielement+ stuff later
	else
		damage = damage*(damageTable[Attack.ElementStack[1]][lookup1]+Attack.QiShred)
	end
	
	damage = math.clamp(damage,1,math.huge)
	
	print(Attack.Name,damage, "Damage after doing the qi lookup calculations")
	
	if pStats.States.SpStates.Dodging == true then 
		if  Attack.Dodgable == true then 
			damage = 0 
		else
			pStats.States.SpStates.Dodging = false
		end 
	end
	
	if pStats.States.SpStates.Blocking == true and Attack.InFrontOfDefender then --  Attacking the block directly
		if Attack.Blockable == false then 
			print("That attack is unblockable!")
			pStats.States.SpStates.Blocking = false
			pStats.States.SpStates.GuardBroken = true
			pStats.Block.Cooldown = 3 -- set the cooldown to 3 seconds before you can block again might be too short we'll see...
			damage *= 1.05
		else
			pStats.Block.Current -= damage
			if pStats.Block.Current <= 0 then 
				pStats.States.SpStates.Blocking = false
				pStats.States.SpStates.GuardBroken = true
				pStats.Block.Cooldown = 3 -- set the cooldown to 3 seconds before you can block again might be too short we'll see...
				damage = math.abs(pStats.Block.Current) 
			else
				damage = 0 
			end
		end
	elseif Attack.InFrontOfDefender == nil then -- this just catches the case where you want to do trap damage for example.
		damage = damage
	elseif pStats.States.SpStates.Blocking == true and not Attack.InFrontOfDefender then -- Backstab
		pStats.States.SpStates.Blocking = false
		pStats.Block.Cooldown = 3
		damage *= 1.02
	end 
	--print(pStats.Health.Current, damage, elem1p, elem2p, "stuffs")
	if humanoid then 
		humanoid:TakeDamage(damage)
		pStats.stunTimer = Attack.HitStun
		return
	end
	pStats.Health.Current -= damage
	return pStats
end

return Damage
-- if you are a water cultivator with a fire skill you would do less damage. 
-- if you're a fire cultivator with a fire skill you would do more damage.
-- if you're a earth cultivator with a fire skill you would do less damage.



-- NOTE TO SELF: for parrying you just need to make a parry timing thing under the block section of the pstats then flip it on while 
-- parry window is open then turn it off while the parry window is closed then you can check here to see if the attack got parried.
-- you'll also need to add a section that asks whether or not the attack itself is parriable but that's for later me when I do parrying.