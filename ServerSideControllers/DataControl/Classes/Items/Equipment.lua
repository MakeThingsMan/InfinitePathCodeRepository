local ItemClass		= require(script.Parent)
local Equipment = {}

function Equipment.new(name,appearance,weight,stacks,location,variant,sfx,value)

	local newEquipment = ItemClass.new(name,"Equipment",appearance,weight,1,stacks,value)
	
	if not location then 
		warn("This equipment doesn't know where it's meant to be!", name)
		location = ""
	end
	
	if not variant then 
		--varient 1 will be reserved for left versions of items 
		--varient 2 will be reserved for right versions of items 
		--anything higher than those two numbers will be considered just a varient 
		--zero in turn just means that there is no variation on this item.
		variant = 0 
	end	
	
	if not sfx then 
		-- do nothing for now.
	end
	
	newEquipment.Location 	= location 
	setmetatable(newEquipment,Equipment)
	--print(newEquipment)
	return newEquipment
end

return Equipment
