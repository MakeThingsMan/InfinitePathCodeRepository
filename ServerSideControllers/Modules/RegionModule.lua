-- Note to future self who takes this and is sad to see how trash this is | Done!
--you can just remove subregions because they don't need to work the way you have them here
--instead put a priority rating on the regions. 
--So when you're in 2 or more regions at once the one with the highest priority will be the one that shows 
--and once you leave that area then the other more dominant regions will be the one that takes over


local Region = {}
Region.__index = Region
Region.RegionShape = {Rectangle = 1, Sphere = 2}

function Region.new(Name,Atmosphere,Shape,Hierarchy) -- fluff is the self that gets passed in for some reason took me a bit to understand that bit but I got it eventually
	
	if not Atmosphere then 
		Atmosphere = {0.428,0,Color3.new(0, 0, 0),Color3.new(1, 1, 1),.63,10}
	end
	
	if not Shape then 
		Shape = Region.RegionShape.Rectangle
	end
	
	if not Name then 
		error("You got to give the region a name you idiot")
	end

	local newRegion = {}
	newRegion.Name = Name
	newRegion.Shape = Shape
	newRegion.Atmo = Atmosphere
	newRegion.PlayersInRegion = {}
	newRegion.Hierarchy = Hierarchy -- i've set a visualization limit of 7 for the hierarchy because you really shouldn't need more than that... 
	-- 1 being the lowest 7 being the highest
	setmetatable(newRegion,Region)
	return newRegion
end


function Region:FindPlayerInRegion(case)
	-- if it returns nil the obviously there's no player in that region
	return self.PlayersInRegion[case]
end

function Region:RemovePlayer(case)
	if #self.PlayersInRegion <= 0  then return end
	local success,failure =  pcall(function()
		table.remove(self.PlayersInRegion,case)
	end)
	return success	
end

function Region:DefineDimensions(V1,V2,Center) 
	if not self[V1] then 
		self["Vector1"] = V1
	end
	if not self[V2] then
		self["Vector2"] = V2
	end
	if not Center then
		self["Center"] = Vector3.new((self["Vector1"].X+self["Vector2"].X), (self["Vector1"].Y+self["Vector2"].Y), (self["Vector1"].Z+self["Vector2"].Z))*.5
	else
		self["Center"] = Center
	end
	
	self["Width"] 	= math.abs(self.Vector2.X-self.Vector1.X)
	self["Height"]	= math.abs(self.Vector2.Y-self.Vector1.Y)
	self["Depth"]	= math.abs(self.Vector2.Z-self.Vector1.Z)
	--print(self.Width,self.Height,self.Depth, self.Name)
	
end

function Region:AddPlayer(playerName)
	if not table.find(self.PlayersInRegion,playerName) then 
		table.insert(self.PlayersInRegion,playerName) 
	end
end

function Region:Visualize()
	local Top = Instance.new("Part")
	Top.Parent = workspace
	Top.CanCollide = false
	Top.CanQuery = false
	Top.CanTouch = false
	Top.Color =Color3.new(self.Hierarchy*36.428,self.Hierarchy*36.428,self.Hierarchy*36.428) -- gives a color based on the hierarchyo of the region
	Top.Transparency = .2
	Top.Name = "Visualize"
	Top.Anchored = true
	Top.Size = Vector3.new((math.max(self["Vector1"].X, self["Vector2"].X) - math.min(self["Vector1"].X,self["Vector2"].X)),(math.max(self["Vector1"].Y, self["Vector2"].Y) - math.min(self["Vector1"].Y,self["Vector2"].Y)),(math.max(self["Vector1"].Z, self["Vector2"].Z) - math.min(self["Vector1"].Z,self["Vector2"].Z)))
	Top.Position = self["Center"]
	Top.CastShadow = false
	
	local P1 = Instance.new("Part")
	P1.Parent = workspace
	P1.Name = "P1"
	P1.CanCollide = false
	P1.BrickColor = BrickColor.Random()
	P1.Anchored = true
	P1.Size = Vector3.new(1,1,1)
	P1.Position = self.Center + Vector3.new(self.Width/2,self.Height/2,self.Depth/2)
	P1.CastShadow = false
	
	
	local P2 = Instance.new("Part")
	P2.Parent = workspace
	P2.Name = "P2"
	P2.CanCollide = false
	P2.BrickColor = BrickColor.Random()
	P2.Anchored = true
	P2.Size = Vector3.new(1,1,1)
	P2.Position = self.Center - Vector3.new(self.Width/2,self.Height/2,self.Depth/2)
	P2.CastShadow = false
	
	
	local C1 = Instance.new("Part")
	C1.Parent = workspace
	C1.Name = "P2"
	C1.CanCollide = false
	C1.BrickColor = BrickColor.Red()
	C1.Material	= Enum.Material.Neon
	C1.Anchored = true
	C1.Size = Vector3.new(1,1,1)
	C1.Position = self.Center
	C1.CastShadow = false
end

return Region