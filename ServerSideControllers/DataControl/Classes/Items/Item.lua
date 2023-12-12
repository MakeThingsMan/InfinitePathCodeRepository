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
	newItem.Id		= IdFunction(newItem)
	setmetatable(newItem,Item)
	--print(newItem)
	return newItem
end

function IdFunction(Item) 
	-- turn this into a hashing function rather than whatever this is. 
	-- Make your own hash function even if it's simple because you need to be able to encrypt one for every
	if Item.Name == " " then return 0 end
	
	local temp = ""
	local baseTable= {a,b,c,d,e,f,g,h,I,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,1,2,3,4,5,6,7,8,9,0}
	local keyTable = {q,a,z,x,s,w,e,d,c,v,f,r,t,g,b,n,h,y,u,j,m,I,k,o,l,p,9,2,3,5,6,4,1,0,8,7}
	-- to increase the complexity you ould then shift the letters all over by some amount and slap that number at the 
	-- end of the hashed string and have the decrypter do the shifting in reverse. 
	local salt = "C%1(k3-" 
	for i =1, #Item.Name,1 do
		temp += keyTable[IndexOf(Item.Name[i],baseTable)]
	end 
	local x = math.random(1,#Item.Name)
	
	temp += String.sub(1,x) .. salt .. String.sub(x,#Item.Name)
	return temp
end

function DecryptId(Input)
	local baseTable		= {a,b,c,d,e,f,g,h,I,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,1,2,3,4,5,6,7,8,9,0}
	local keyTable 		= {q,a,z,x,s,w,e,d,c,v,f,r,t,g,b,n,h,y,u,j,m,I,k,o,l,p,9,2,3,5,6,4,1,0,8,7}
	local salt 		= "C%1(k3-"
	local saltLocation 	= String.Find(Input,salt)
	Input 			= String.sub(1,saltLocation) .. String.sub(saltLocation+7,Input.Length)
	local temp		= ""
	for i=1, Input.Length do 
		temp += baseTable[IndexOf(Item.Name[i],keyTable)]
	end
	
	return temp`1	
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

