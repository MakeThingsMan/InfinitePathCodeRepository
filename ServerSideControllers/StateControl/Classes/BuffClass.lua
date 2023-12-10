local ts = game.ServerStorage:WaitForChild("TakeStats")
local ssA = game.ServerStorage:WaitForChild("SendStatsAlternative")
local Buff = {}

Buff.__index = Buff

function Buff.new(Name,Augs,Duration,maxStacks,Tickrate,perm,SpState)
	if not Name then 
		error("You didn't set the name of a buff")
	end
	
	if not Augs then -- in the format "Stat"| "Math" | "Value" I.E: "MaxHealth" "*" "1.1" 
					 --ex {{MaxHealth,Multi,1.1},{Speed,Multi,1.05},{}}
		error("The buff you just made does literally nothing")
	end
	
	if not Duration then  -- not having a duration will result in the Buff lasting forever on the player until it is otherwise removed
		Duration = -1 
	end
	
	if not maxStacks then
		maxStacks = 1
	end
	
	if not Tickrate then 
		Tickrate = -1
	end
	
	if not perm then
		perm = false
	end
	
	if not SpState then
		SpState = -1
	end
	
	local newBuff 		= {}
	newBuff.Name 		= Name 
	newBuff.Augs 		= Augs
	newBuff.Duration 	= Duration
	newBuff.MaxStacks	= maxStacks
	newBuff.Stacks		= 0
	newBuff.Tickrate 	= Tickrate
	newBuff.Finality	= perm
	newBuff.Special		= SpState
	setmetatable(newBuff,Buff)
	--print(newBuff)
	return newBuff
end

function Buff:SelfApply(pStats)
	pStats = Buff.Apply(self,pStats)
	return pStats
end

function Buff:SelfRemove(pStats)
	pStats = Buff.Remove(self,pStats)
	return pStats
end

function Buff.Apply(buff,pStats)
	for i, buffs in ipairs(buff.Augs) do
		for i = 1, #buffs-2, 3 do
			local x,y = SplitWord(buffs[i])
			local value = buffs[i+2]
			if buffs[i+1] == "Multi" then 
				pStats[y][x]*= value 
			else 
				pStats[y][x] += value
			end
			if y == "Health" and x == "Max" then 
				game.Players[pStats.PlayerName].Character.Humanoid.MaxHealth = pStats[y][x]
			end
		end
	end
	return pStats
end

function Buff.TickApply(buff,pStats)
	local count = 0 
	local currentStacks = pStats.States.Buffs[buff.Name].Stacks
	while buff.Duration > 0 do
		if pStats.States.Buffs[buff.Name] then -- this allows for some sort of cleansing magic to actually work and would maek
			if pStats.States.Buffs[buff.Name].Stacks > currentStacks then 
				return
			end
			if count > 1 then 
				pStats = ssA:Invoke(pStats.playerID)
			end
			pStats = Buff.Apply(buff,pStats)
			ts:Fire(pStats,script.Name)
		end
		wait(buff.Tickrate)	
		count+=1
	end
	return
end

function Buff.Remove(buff,pStats)
	pStats = Buff.Nullify(buff,pStats)
	pStats.States.Buffs[buff.Name] = nil
	return pStats
end

function Buff.Nullify(buff,pStats)
	for i, buffs in ipairs(buff.Augs) do
		for i = 1, #buffs-2, 3 do
			local x,y = SplitWord(buffs[i])
			local value = buffs[i+2]
			if buffs[i+1] == "Multi" then 
				pStats[y][x]/= math.pow(value,buff.Stacks)
			else 
				pStats[y][x] -= (value*buff.Stacks)
			end
		end
	end
	return pStats
end
	
function Buff.Disable(buff,pStats)
	pStats.States.Buffs[buff.Name] = nil
	return pStats
end

function SplitWord(word) -- for instance the line "MaxHealth"
	local upperWord = word:upper()
	local x,y,z
	for i = 2, word:len(),1 do 
		if string.sub(word,i,i) == string.sub(upperWord,i,i) then
			x = string.split(word,word:sub(i,i)) 
			y = x[1]
			z = x[2]
			z = word:sub(i,i) .. z
			return y,z
		end
	end
	return y,z 
end
return Buff
