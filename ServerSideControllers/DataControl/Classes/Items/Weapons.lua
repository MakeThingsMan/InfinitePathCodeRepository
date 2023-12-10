local DamageClass 	= require(game.ServerScriptService.CombatController.DamageClass)
local ItemClass		= require(script.Parent)
local Weapon = {}

function Weapon.new(name,appearance,weight,stacks,durability,damage,hitboxes,sfx,animations,maxSwings,endlag,weaponType,weaponRange,rank,value)
	
	local newWeapon = ItemClass.new(name,"Weapon",appearance,weight,1,stacks,rank,value)
	
	if not durability then 
		warn("This weapon has no durability", name)
	end
	
	if not damage then 
		warn("This weapon does no damage",name)
	end

	if not hitboxes then 
		warn("This weapon has no hitbox",name)
	end
	
	if not animations then 
		warn("This weapons has no animations",name)
	end
	
	if not maxSwings then 
		maxSwings = 4 
	end
	
	if not endlag then
		warn("this weapon has no endlag",name)
	end
	
	if not sfx  then
		warn("This weapon makes no sound",name)
	end
	
	if not weaponType then 
		warn("This weaon doesn't have a typing!", name)
	end
	
	if not weaponRange then 
		warn("This weapon doesn't have a range set to it!", name)
	end
	
	newWeapon.Damage 	= damage
	newWeapon.Hitboxes	= hitboxes
	newWeapon.Animations= animations
	newWeapon.Sfx		= sfx
	newWeapon.MaxSwings	= maxSwings
	newWeapon.Endlag	= endlag
	setmetatable(newWeapon,Weapon)
	print(newWeapon)
	return newWeapon
end

return Weapon
