local Switch 					= require(script.Parent.Parent.Switch)
local Bloodline = {}

Bloodline.__index = Bloodline

function Bloodline.New(name,effect,awakened)
	if not name then 
		warn("Debugging will be hell if you don't name this bloodline")
	end
	
	if not effect then 
		warn("This bloodline does literally nothing why is it here?", name)
	end
	
	if not awakened then 
		awakened = false
	end
	
	local newBloodline = {}
	
	newBloodline.Name 		= name
	newBloodline.Effect 	= effect
	newBloodline.Awakened 	= awakened
	newBloodline.Applied	= false
	setmetatable(newBloodline,Bloodline)
	return newBloodline
end 

function Bloodline.QiBloodline(pStats, qi)
	pStats.Qi.Element1.Element 	= qi
	pStats.Qi.Element1.Tier		+= 1
	pStats.Qi.Element2.Element 	= qi
	pStats.Qi.Element2.Tier		+= 1
	return pStats
end

return Bloodline
