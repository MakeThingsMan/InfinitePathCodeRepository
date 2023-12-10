local Constitution = {}

Constitution.__index = Constitution

function Constitution.new(Name,Augs,description)
	if not Name then 
		error("You didn't set the name of a Constitution")
	end

	if not Augs then -- same format as configs 
		error("The Constitution you just made does literally nothing")
	end
	
	if not description then
		description = ""
	end
	
	local newConstitution 		= {}
	newConstitution.Name 		= Name 
	newConstitution.Augs 		= Augs
	newConstitution.Description = description
	setmetatable(newConstitution,Constitution)
	return newConstitution
end
return Constitution