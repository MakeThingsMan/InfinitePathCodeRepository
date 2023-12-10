local Achievement = {}

Achievement.__index = Achievement

function Achievement.new(name, playerName, featDesc, points)
	
	if not name then 
		warn("There's going to be problems and you aint gonna like them")
	end
	
	if not playerName then 
		warn("You don't have",name, "set to a player name, was that intended?")
	end
	
	if not featDesc then 
		warn("You've made an achievement that has no description", name)
	end
	
	if not points then 
		warn("You've made an achievement that doesn't give any points to the player", name)
	end
	
	local newAchievement 			= {}
	newAchievement.Name				= name
	newAchievement.PlayerName 		= playerName
	newAchievement.FeatDescription	= featDesc --Create custom descriptions for each...
	newAchievement.Points			= points
	newAchievement.Active 			= false
	newAchievement.TimesAchieved	= 3 -- reset this back to 0
	setmetatable(newAchievement,Achievement)
	
	return newAchievement
end

return Achievement
