local Item = {}
Item.index__ = Item
function Item.new(name,Type,appearance,weight,maxStacks,stacks,rank,value)
	if not name then
		warn("The new item has no name")
	end

	--if not appearance then
	--	--warn("The new item has no appearance")
	--end
	if not Type then
		warn("This new item has no type")
	end

	if not weight then
		weight = 1
	end

	if not maxStacks then
		maxStacks = 1
	end
	
	if not stacks then 
		stacks = 0
	end

	if not value then
		value = 1
	end
	
	if not rank then -- rank is really only used for visualization on the ground. 
		rank = 1
	end

	local newItem = {}
	newItem.Name 		= name
	newItem.Type		= Type
	newItem.Appearance 	= appearance
	newItem.Weight		= weight
	newItem.Value		= value
	newItem.MaxStacks	= maxStacks
	newItem.Stacks 		= stacks
	newItem.Rank		= rank
	newItem.InvLocation	= {nil,nil}
	newItem.Id			= IdFunction(newItem)
	setmetatable(newItem,Item)
	--print(newItem)
	return newItem
end

function IdFunction(Item)
	if Item.Name == " " then return 0 end
	
	local temp = ""
	for i =1, #Item.Name,1 do
		local x = math.random(33,126)
		temp = temp..tostring(x)
	end 
	return temp
end

function Item.NewEmpty()
	local newitem = Item.new(" ","Empty",nil,0,0,0,0)
	return newitem
end
function Item.GetValue(Value)
	return Item[Value]
end
function Item:SetValue(Value,Amount)
	self[Value] = Amount
end
return Item

