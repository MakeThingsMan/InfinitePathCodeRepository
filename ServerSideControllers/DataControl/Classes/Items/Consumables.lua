local buffClass = require(game.ServerScriptService.StateController.BuffClass)
local ItemClass = require(script.Parent)

local Consumables = {}

function Consumables.new(name,appearance,weight,maxStacks,stacks,value,buff,charges)
	local newConsumable = ItemClass.new(name,appearance,weight,maxStacks,stacks,value)
	
	if not buff then 
		warn("this consumable does nothing")
	end
	
	if not charges then
		charges = 1 
	end
	
	newConsumable.Buff = buff
	newConsumable.Charges = charges
	
	setmetatable(newConsumable,Consumables)
	return newConsumable
end


return Consumables
