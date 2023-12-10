local Hitbox = {}

Hitbox.__index = Hitbox
Hitbox.PositionType = {Flush = 1, Centered = 2,Behind = 3}
function Hitbox.new(hitbox,typing)
	if not hitbox  then
		error("There's no hitbox in this new hitbox")
	end
	
	if not typing then 
		typing = Hitbox.PositionType.Centered
	end
	
	local newHitbox 			= {}
	newHitbox.Box 				= hitbox:Clone()
	newHitbox.Box.Parent		= workspace
	newHitbox.Box.Position		= Vector3.new(0,0,0)
	newHitbox.Box.Anchored		= true
	newHitbox.Typing 			= typing
	setmetatable(newHitbox,Hitbox)
	return newHitbox	
end

function Hitbox.FindPosition(hitbox,parentPart,slot)
	print(hitbox,hitbox.Typing)
	hitbox.Box.Rotation = parentPart.Rotation
	if hitbox.Typing == 2 then
		hitbox.Box.Position = parentPart.Position
		print("Done A")
	elseif hitbox.Typing == 1  then
		hitbox.Box.Position = parentPart.Position + parentPart.CFrame.LookVector * (hitbox.Box.Size.Z/2)
		print("Done B")	
	end
	hitbox.Box.Parent = parentPart
	hitbox.Box.Anchored= false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hitbox.Box
	weld.Part1 = parentPart
	weld.Parent= hitbox.Box
end

function Hitbox:SelfFindPosition(parentPart)
	Hitbox.FindPosition(self,parentPart)
end

return Hitbox