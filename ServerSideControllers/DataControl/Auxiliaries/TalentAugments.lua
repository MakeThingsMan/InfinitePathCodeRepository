local function Augment(talent, basestats)
	local newStats = basestats
	newStats.Talent = talent
	if talent >= 14 then 
		newStats.Qi.Unlocked = true
	end
	
	newStats.Qi.Max = 100+math.floor(.5*talent*math.pi)
	newStats.Qi.Regen = 1 + math.floor(.15*talent)
	newStats.Cultivation.Speed =  math.ceil(math.sqrt(talent/4)*math.sin(talent/10+.9))
	return newStats
end

return Augment
