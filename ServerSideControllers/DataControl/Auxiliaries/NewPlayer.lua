local module 		= {}
local baseStats 	= require(script.Parent:WaitForChild("BaseStats"))
local TalentAugment = require(script.Parent:WaitForChild("Talent Augments"))
local ItemClass		= require(script.Parent.ItemClass)
local elementTable 	= {"Fire","Earth","Metal","Water","Wood"}


function module.setNewStats(player)
	print(player.Name)
	local tempStats = baseStats
	tempStats.playerID = player.UserId
	---------------------- Talent Calculation section
	local x = math.random(0,160)/10
	local y = math.sqrt(4.499*x)--(-.2365*x)*(math.pow((x-16),2)+1)
	local talent  = 16 --math.floor(16*math.pow(math.cos(.133*y+.2),2))
	tempStats = TalentAugment(talent,tempStats)
	----------------------	Element Assignment
	x 	= math.random(1,5)
	tempStats.Qi.Element1.Element = "Water"--elementTable[x] -- change back to random
	x	= math.random(1,5)
	tempStats.Qi.Element2.Element = "Water" --elementTable[x] -- change back to random
	---------------------- Inventory Assignment
	for i, v in pairs(tempStats.Inventory) do
		for j, k in pairs(v) do
			tempStats.Inventory[i][j] = ItemClass.NewEmpty()
			tempStats.Inventory[i][j].InvLocation = {i,j}
		end
	end
	---------------------- Hotbar Assignment
	for i, v in pairs(tempStats.Hotbar) do
		tempStats.Hotbar[i] = ItemClass.NewEmpty()
		tempStats.Hotbar[i].InvLocation ={i,nil} 
	end
	
	---------------------- Cultivation Assignment
	tempStats.Cultivation.CBaseMax = math.ceil(100*math.sqrt(tempStats.Cultivation.State+1)*math.pow(tempStats.Cultivation.State+1,2))
	tempStats.Cultivation.CBase = 90 -- make sure this is set to 0
	---------------------- Constitution Assignment 
	
	x = math.random(1, 5)
	
	tempStats.PlayerName = player.Name
	
	return tempStats
end

function module.setNewStatsTest(player)
	local test = {}
	local talent
	for i = 0, 99, 1 do 
		local x = math.random(0,160)/10
		local y =   math.sqrt(4.499*x) --12*math.sin(.1*x)   --[[math.pow(1.2*x+9,2)+6 (-.2365*x)*(math.pow((x-16),2)+1)]] --[[]]
		talent = math.floor(17*math.pow(math.cos(.133*y+.2),2)) --math.floor(16*math.pow(math.cos(.2*y-.6),2)) --
		table.insert(test,talent)
		--print(x,y,talent)
	end
	--print(talent)
	return talent,test
end

function module.counter(test)
	local counter = 0
	for i = 0,16,1 do
		for t, v in pairs(test) do 
			if v == i then 
				counter+=1 
			end 
		end
		counter = 0
	end
end

function module.counter2(test)
	local temp = {}
	local counter = 0
	for i = 0,16,1 do
		for t, v in pairs(test) do 
			if v == i then 
				counter+=1 
			end 
		end
		table.insert(temp,counter)
		counter = 0
	end
	return temp
end

function module.average()
	local temp = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
	local count = 10000
	for i = 0, count, 1 do 
		local talent, test = module.setNewStatsTest()
		local temp1 = module.counter2(test)
		for i, v in pairs(temp) do
			temp[i] += temp1[i]
		end
	end
	print("population size: ",100*count,table.unpack(temp))
	for i = 1,17,1 do
		print("talent level:",i-1,"", math.round(temp[i]/(100*count)*100).."% of players")
	end
end

return module

