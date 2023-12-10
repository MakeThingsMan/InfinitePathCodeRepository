local BloodlinesClass			= require(game.ServerScriptService.AchievementController.BloodlinesClass)

local module = {}

function module.ReincarnateStats(new,old)
	if old.Bloodlines.Obtained.Count > 0 then -- if you have obtained a bloodline
		for i, v in pairs(old.Bloodlines.Obtained) do 
			if i ~= "Count" and v.Awakened and not v.Applied then 
				new = BloodlinesClass[v.Effect](old,v.Name:sub(12,#v.Name))
				new.Bloodlines.Obtained[v.Name].Applied = true 
			end
		end
	end
	
	for i, stat in pairs(new.AugmentingStats) do 
		print(old.AugmentingStats[i], i , stat)
		new.AugmentingStats[i] += math.floor(math.sqrt(old.AugmentingStats[i]))
	end
	new.Qi.Max 			+=	math.floor(math.sqrt(old.Qi.Max))
	new.Qi.Regen 		+=  math.floor(math.sqrt(old.Qi.Regen)) 
	new.Reincarnations 	+= 1
	
	return new
end

return module
